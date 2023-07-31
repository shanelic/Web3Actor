import Foundation
import Combine
import Web3
import Web3ContractABI
import Web3PromiseKit

@globalActor
actor Web3Actor {
    static var shared = Web3Actor()
    private init() {}
    
    private var cancellables = [AnyCancellable]()
    
    private var web3: Web3?
    private var contracts: [String: EthereumContract] = [:]
    
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
        innerPrint("the version of rpc server just initialized is: \(version)")
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
}

class ActorHelper {
    static var shared = ActorHelper()
    var openseaApiKey: String!
    var etherscanApiKey: String!
}
