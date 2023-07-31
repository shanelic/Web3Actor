@globalActor
actor Web3Actor {
    static var shared = Web3Actor()
    private init() {}
    
    public func initializeApis(openseaApiKey: String? = nil, etherscanApiKey: String? = nil) {
        ActorHelper.shared.openseaApiKey = openseaApiKey
        ActorHelper.shared.etherscanApiKey = etherscanApiKey
    }
}

class ActorHelper {
    static var shared = ActorHelper()
    var openseaApiKey: String!
    var etherscanApiKey: String!
}
