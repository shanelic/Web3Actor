import Foundation
import Combine
import Web3
import Web3ContractABI
import Web3PromiseKit

@globalActor
public actor Web3Actor {
    public static var shared = Web3Actor()
    private init() {}
    
    private var cancellables = [AnyCancellable]()
    
    private var web3: Web3?
    private var contracts: [String: EthereumContract] = [:]
    
    @Published public var collectibles: [Opensea.Collection] = []
    
    public func initializeRpcServer(_ network: Network? = nil) async {
        if let rpcServer = network?.rpcServers.first {
            await switchRpcServer(rpcServer)
        } else {
            guard let rpcServer = Network.EthereumMainnet.rpcServers.first else { return }
            await switchRpcServer(rpcServer)
        }
    }
    
    public func initializeApis(openseaApiKey: String? = nil, etherscanApiKey: String? = nil) {
        ActorHelper.shared.openseaApiKey = openseaApiKey
        ActorHelper.shared.etherscanApiKey = etherscanApiKey
    }
    
    public func switchRpcServer(_ rpcServer: Network.RpcServer) async {
        guard let version = try? await Web3(rpcURL: rpcServer.url).clientVersion().async() else { return }
        print("--- the version of rpc server just initialized is: \(version)")
        self.web3 = Web3(rpcURL: rpcServer.url)
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
    
    public func addDynamicContract(name: String, address: EthereumAddress, abiData: Data, abiKey: String? = nil) async throws {
        guard let web3 else { return }
        guard !contracts.keys.contains(name) else { return }
        if try await isAddressContract(address) {
            contracts[name] = try web3.eth.Contract(json: abiData, abiKey: abiKey, address: address)
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
