//
//  OpenseaModel.swift
//  
//
//  Created by RBLabs RD - Shane on 2023/7/17.
//

import Foundation

struct Opensea {
    
    // MARK: BASIC
    
    enum ChainIdentity: String, Codable {
        // from opensea
        case arbitrum
        case avalanche
        case ethereum
        case klaytn
        case matic
        case optimism
        // customized
        case goerli
        case pomo
    }
    
    struct AssetContract: Codable {
        let address: String
        let chainIdentifier: ChainIdentity
        let name: String
        let schemaName: ERC
        let symbol: String
        
        enum CodingKeys: String, CodingKey {
            case address
            case chainIdentifier = "chain_identifier"
            case name
            case schemaName = "schema_name"
            case symbol
        }
        
        var abiData: Data? = nil
    }
    
    struct Collection: Codable {
        let primaryAssetContracts: [AssetContract]
        let ownedAssetCount: Int
        
        enum CodingKeys: String, CodingKey {
            case primaryAssetContracts = "primary_asset_contracts"
            case ownedAssetCount = "owned_asset_count"
        }
        
        var appliedChain: ChainIdentity? = nil
        var validAssetContracts: [AssetContract] {
            guard let appliedChain else { return [] }
            return primaryAssetContracts.filter { $0.chainIdentifier == appliedChain }
        }
    }
}
