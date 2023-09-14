//
//  OpenseaModel.swift
//  
//
//  Created by RBLabs RD - Shane on 2023/7/17.
//

import Foundation

public struct Opensea {
    
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
    
    public struct AssetContract: Codable {
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
    
    public struct Collection: Codable {
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
    
    public struct NFT: Codable, Hashable, Identifiable {
        
        public var id: UUID
        
        let identifier: String
        public let collection: String
        let contract: String
        let tokenStandard: ERC
        public let name: String
        public let description: String
        public let imageUrl: String?
        let metadataUrl: String
//        let createdAt: Date
//        let updatedAt: Date
        let isDisabled: Bool
        let isNsfw: Bool
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.identifier = try container.decode(String.self, forKey: .identifier)
            self.collection = try container.decode(String.self, forKey: .collection)
            self.contract = try container.decode(String.self, forKey: .contract)
            self.tokenStandard = try container.decode(ERC.self, forKey: .tokenStandard)
            self.name = try container.decode(String.self, forKey: .name)
            self.description = try container.decode(String.self, forKey: .description)
            self.imageUrl = try container.decode(Optional<String>.self, forKey: .imageUrl)
            self.metadataUrl = try container.decode(String.self, forKey: .metadataUrl)
            self.isDisabled = try container.decode(Bool.self, forKey: .isDisabled)
            self.isNsfw = try container.decode(Bool.self, forKey: .isNsfw)
            self.id = UUID()
        }
        
        enum CodingKeys: String, CodingKey {
            case identifier
            case collection
            case contract
            case tokenStandard = "token_standard"
            case name
            case description
            case imageUrl = "image_url"
            case metadataUrl = "metadata_url"
//            case createdAt = "created_at"
//            case updatedAt = "updated_at"
            case isDisabled = "is_disabled"
            case isNsfw = "is_nsfw"
        }
        
        struct NextCursor: Codable {
            let next: String
        }
    }
    
    public struct NFTResponse: Codable {
        let nfts: [NFT]
    }
}
