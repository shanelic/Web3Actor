//
//  File.swift
//  
//
//  Created by RBLabs RD - Shane on 2023/7/27.
//

import Foundation

struct Etherscan {
    struct Erc20Token: Codable {
        let address: String
        let name: String
        let symbol: String
        let quantity: String
        let divisor: String
        
        enum CodingKeys: String, CodingKey {
            case address = "TokenAddress"
            case name = "TokenName"
            case symbol = "TokenSymbol"
            case quantity = "TokenQuantity"
            case divisor = "TokenDivisor"
        }
    }
    
    struct Erc721Token: Codable {
        let address: String
        let name: String
        let symbol: String
        let quantity: String
        
        enum CodingKeys: String, CodingKey {
            case address = "TokenAddress"
            case name = "TokenName"
            case symbol = "TokenSymbol"
            case quantity = "TokenQuantity"
        }
    }
}
