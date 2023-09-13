import Foundation
import Combine
import Web3
import Web3ContractABI
import Web3PromiseKit
import Alamofire

@globalActor
public actor Web3Actor {
    public static var shared = Web3Actor()
    private init() {}
    
    private var cancellables = [AnyCancellable]()
    
    private var web3: Web3?
    private var connectedNetwork: Network?
    private var contracts: [String: EthereumContract] = [:]
    
    @Published public var collectibles: [Opensea.Collection] = []
    
    public func initialize(_ network: Network? = nil, openseaApiKey: String? = nil, etherscanApiKey: String? = nil) {
        ActorHelper.shared.openseaApiKey = openseaApiKey
        ActorHelper.shared.etherscanApiKey = etherscanApiKey
    }
    
    public func switchNetwork(_ network: Network) async {
        for rpcServer in (network.rpcServers.isEmpty ? Network.EthereumMainnet : network).rpcServers {
            if await connect(to: rpcServer) {
                connectedNetwork = network.rpcServers.isEmpty ? Network.EthereumMainnet : network
                break
            }
        }
    }
    
    private func connect(to rpcServer: Network.RpcServer) async -> Bool {
        guard let version = try? await Web3(rpcURL: rpcServer.url).clientVersion().async() else { return false }
        print("--- the version of rpc server just initialized is: \(version)")
        self.web3 = Web3(rpcURL: rpcServer.url)
        return true
    }
    
    public func getContracts() -> [String] {
        return contracts.keys.sorted()
    }
    
    public func removeContract(_ name: String) {
        guard let index = contracts.keys.firstIndex(of: name) else { return }
        _ = contracts.remove(at: index)
    }
    
    public func removeAllContracts() {
        contracts = [:]
    }
    
    public func getBalance(of address: EthereumAddress) async throws -> EthereumQuantity {
        guard let web3 else { throw W3AError.web3NotInitialized }
        return try await web3.eth.getBalance(address: address, block: .latest).async()
    }
    
    public func getCollectibles(of address: EthereumAddress) async throws {
        collectibles = try await retrieveCollections(for: address)
        try await addContracts(collectibles)
    }
    
    public func addDynamicContract(name: String, address: EthereumAddress, abiData: Data, abiKey: String? = nil) async throws {
        guard let web3 else { return }
        guard !contracts.keys.contains(name) else { return }
        if try await isAddressContract(address) {
            contracts[name] = try web3.eth.Contract(json: abiData, abiKey: abiKey, address: address)
        }
    }
    
    private func retrieveCollections(for address: EthereumAddress) async throws -> [Opensea.Collection] {
        return try await withCheckedThrowingContinuation { continuation in
            API.shared.request(OpenseaAPIs.retrieveCollections(address: address.hex(eip55: true)))
                .sink { result in
                    switch result {
                    case .finished:
                        print("--- reload holdings finished with continuation")
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                } receiveValue: { collections in
                    continuation.resume(returning: collections)
                }
                .store(in: &cancellables)
        }
    }
    
    private func retrieveNFTs(for address: EthereumAddress, limit: Int, nextCursor: String? = nil) async throws -> ([Opensea.NFT], String?) {
        return try await withCheckedThrowingContinuation { continuation in
            guard let connectedNetwork else {
                continuation.resume(throwing: W3AError.web3NotInitialized)
                return
            }
            /// in case the `next` property is not always there, I have to change the way fetching data.
//            API.shared.request(
//                OpenseaAPIs.retrieveNFTs(
//                    address: address.hex(eip55: true),
//                    chain: connectedNetwork.chainIdentity,
//                    limit: limit,
//                    nextCursor: nextCursor
//                ),
//                keyPath: "nfts"
//            )
//            .sink { result in
//                switch result {
//                case .finished:
//                    print("--- reload NFTs finished with continuation")
//                case .failure(let error):
//                    continuation.resume(throwing: error)
//                }
//            } receiveValue: { nfts in
//                continuation.resume(returning: nfts)
//            }
//            .store(in: &cancellables)
            var parameters: Parameters = [
                "limit": limit,
            ]
            if let nextCursor { parameters["next"] = nextCursor }
            AF.request(
                "https://api.opensea.io/api/v2/chain/\(connectedNetwork.chainIdentity.rawValue)/account/\(address.hex(eip55: true))/nfts",
                parameters: parameters,
                headers: [
                    "Accept": "application/json",
                    "X-API-KEY": ActorHelper.shared.openseaApiKey,
                ])
            .responseDecodable(of: [Opensea.NFT].self) { response in
                switch response.result {
                case .success(let nfts):
                    let decoder = JSONDecoder()
                    let nextCursor = try? decoder.decode(Opensea.NFT.NextCursor.self, from: response.data ?? Data())
                    continuation.resume(returning: (nfts, nextCursor?.next))
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func getContractAbi(contract address: EthereumAddress) async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in
            API.shared.request(EtherscanAPIs.AbiFromContract(address: address.hex(eip55: true)))
                .sink { result in
                    switch result {
                    case .finished:
                        print("--- fetching abi of \(address.hex(eip55: true)) from etherscan finished.")
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                } receiveValue: { esResponse in
                    guard let abiString = esResponse.result.safeAbiStringFiltered, let abiData = abiString.data(using: .utf8) else {
                        continuation.resume(throwing: W3AError.abiDecodingFailed)
                        return
                    }
                    continuation.resume(returning: abiData)
                }
                .store(in: &self.cancellables)
        }
    }
    
    private func addContracts(_ collections: [Opensea.Collection]) async throws {
        for collection in collections {
            for contract in collection.validAssetContracts {
                if let abiData = contract.abiData, let contractAddress = EthereumAddress(hexString: contract.address) {
                    try await addDynamicContract(name: "\(contract.name) - \(contract.address)", address: contractAddress, abiData: abiData)
                } else {
                    switch contract.schemaName {
                    default:
                        guard let contractAddress = EthereumAddress(hexString: contract.address) else { continue }
                        let abiData = try await getContractAbi(contract: contractAddress)
                        try await addDynamicContract(name: "\(contract.name) - \(contract.address)", address: contractAddress, abiData: abiData)
                    }
                }
            }
        }
    }
    
    private func isAddressContract(_ address: EthereumAddress) async throws -> Bool {
        guard let web3 else { throw W3AError.web3NotInitialized }
        let code = try await web3.eth.getCode(address: address, block: .latest).async()
        return code.hex() != "0x"
    }
}

extension Web3Actor {
    
    public func getDynamicContract(_ name: String) -> DynamicContract? {
        return contracts[name] as? DynamicContract
    }
    
    public func getDynamicContractMethods(name: String) -> [String] {
        guard let contract = contracts[name] as? DynamicContract else { return [] }
        return contract.methods.keys.sorted()
    }
    
    public func getDynamicMethodInputs(name: String, method: String) -> [String: SolidityType] {
        guard let contract = contracts[name] as? DynamicContract, let method = contract.methods[method] else { return [:] }
        return method.inputs.reduce(into: [:]) { $0[$1.name] = $1.type }
    }
    
    public func makeDynamicMethodRequest(name: String, method: String, inputs: [ABIEncodable]) -> SolidityInvocation? {
        guard let contract = contracts[name] as? DynamicContract else { return nil }
        guard let method = contract.methods[method] as? BetterInvocation else { return nil }
        return method.betterInvoke(inputs)
    }
}

class ActorHelper {
    static var shared = ActorHelper()
    var openseaApiKey: String!
    var etherscanApiKey: String!
}

enum W3AError: Error {
    case web3NotInitialized
    case abiDecodingFailed
}
