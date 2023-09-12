//
//  Extensions.swift
//  
//
//  Created by RBLabs RD - Shane on 2023/7/17.
//

import Foundation
import Web3
import Web3Wallet
import BigInt

extension Int {
    var ethQty: EthereumQuantity {
        return EthereumQuantity(quantity: BigUInt(self))
    }
}

extension String {
    var safeAbiStringFiltered: String? {
        let jsonDecoder = JSONDecoder()
        guard let data = self.data(using: .utf8) else { return nil }
        guard let elements = try? jsonDecoder.decode(Array<Dictionary<String, AnyCodable>>.self, from: data) else { return nil }
        let result = elements.filter { ($0["type"]?.value as? String) != "error" }
        return try? result.json()
    }
    
    var simpleAddress: String {
        return self.dropLast(34) + "..." + self.dropFirst(36)
    }
}
