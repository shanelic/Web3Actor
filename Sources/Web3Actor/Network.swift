//
//  Network.swift
//  
//
//  Created by RBLabs RD - Shane on 2023/7/17.
//

import Foundation
import Web3
import Web3Wallet

public struct Network {
    let name: String
    let chainId: Int
    let nativeCurrency: Currency
    let rpcServers: [RpcServer]
    let multicall3: String
    let chainIdentity: Opensea.ChainIdentity
    
    var eip155: String {
        "eip155:\(chainId)"
    }
    var blockchain: Blockchain {
        Blockchain(eip155)!
    }
    
    public struct Currency {
        let name: String
        let symbol: String
    }
    
    public struct RpcServer {
        let url: String
        let type: RpcServerProtocol
        
        enum RpcServerProtocol {
            case http
            case websocket
        }
    }
    
    public static let EthereumMainnet = Network(
        name: "Ethereum Mainnet",
        chainId: 1,
        nativeCurrency: Currency(name: "Ether", symbol: "ETH"),
        rpcServers: [
            RpcServer(url: "https://cloudflare-eth.com", type: .http),
        ],
        multicall3: "0xca11bde05977b3631167028862be2a173976ca11",
        chainIdentity: .ethereum
    )
    public static let EthereumGoerli = Network(
        name: "Ethereum Goerli",
        chainId: 5,
        nativeCurrency: Currency(name: "Goerli Ether", symbol: "ETH"),
        rpcServers: [
            RpcServer(url: "https://rpc.ankr.com/eth_goerli", type: .http),
        ],
        multicall3: "0xca11bde05977b3631167028862be2a173976ca11",
        chainIdentity: .goerli
    )
    public static let PolygonMainnet = Network(
        name: "Polygon Mainnet",
        chainId: 137,
        nativeCurrency: Currency(name: "MATIC", symbol: "MATIC"),
        rpcServers: [
            RpcServer(url: "https://polygon-rpc.com", type: .http),
        ],
        multicall3: "0xca11bde05977b3631167028862be2a173976ca11",
        chainIdentity: .matic
    )
    public static let PomoTestnet = Network(
        name: "POMO Testnet",
        chainId: 1337,
        nativeCurrency: Currency(name: "POMO Ether", symbol: "POMO"),
        rpcServers: [
            RpcServer(url: "https://dev-ganache.pomo.network/:9527", type: .http)
        ],
        multicall3: "0xca11bde05977b3631167028862be2a173976ca11",
        chainIdentity: .pomo
    )
    
    public static var chains: [Blockchain] {
        [
            EthereumMainnet.blockchain,
            EthereumGoerli.blockchain,
            PolygonMainnet.blockchain,
            PomoTestnet.blockchain,
        ]
    }
    
    public static func getAccounts(by address: EthereumAddress) -> [Account] {
        chains.compactMap { Account(blockchain: $0, address: address.hex(eip55: true)) }
    }
}

public enum ERC: String, Codable {
    case ERC20
    case ERC721
    case ERC1155
    case unknown
    
    init(_ rawValue: String) {
        switch rawValue
            .uppercased()
            .replacingOccurrences(of: "-", with: "")
        {
        case "ERC20":
            self = .ERC20
        case "ERC721":
            self = .ERC721
        case "ERC1155":
            self = .ERC1155
        default:
            self = .unknown
        }
    }
}
