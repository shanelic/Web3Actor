//
//  File.swift
//  
//
//  Created by RBLabs RD - Shane on 2023/7/27.
//

import Foundation
import Combine
import Moya
import CombineMoya

// MARK: Etherscan APIs

protocol EtherscanTargetType: DecodableResponseTargetType {}

extension EtherscanTargetType {
    var baseURL: URL { URL(string: "https://api.etherscan.io/api")! }
    var headers: [String : String]? {
        [
            "Content-Type": "application/json",
            "Accept": "application/json",
        ]
    }
    var apiKey: String {
        ActorHelper.shared.etherscanApiKey
    }
}

struct EtherscanResponse<T: Codable>: Codable {
    let status: String
    let message: String
    let result: T
}

enum EtherscanAPIs {}

// MARK: Account

extension EtherscanAPIs {
    struct Erc20TokenHolding: EtherscanTargetType {
        typealias ResponseType = EtherscanResponse<[Etherscan.Erc20Token]>
        var method: Moya.Method { .get }
        var path: String { "/" }
        var task: Task {
            .requestParameters(parameters: [
                "module": "account",
                "action": "addresstokenbalance",
                "address": address,
                "page": page,
                "offset": offset,
                "apiKey": apiKey,
            ], encoding: URLEncoding.queryString)
        }
        
        private let address: String
        private var page: String
        private var offset: String
        
        /// - Parameter address: the address querying
        /// - Parameter page: the current page number, `1` by default
        /// - Parameter offset: the current page size, `100` by default
        init(address: String, page: Int = 0, offset: Int = 100) {
            self.address = address
            self.page = "\(page)"
            self.offset = "\(offset)"
        }
    }
    
    struct Erc721TokenHolding: EtherscanTargetType {
        typealias ResponseType = EtherscanResponse<[Etherscan.Erc721Token]>
        var method: Moya.Method { .get }
        var path: String { "/" }
        var task: Task {
            .requestParameters(parameters: [
                "module": "account",
                "action": "addresstokennftbalance",
                "address": address,
                "page": page,
                "offset": offset,
                "apiKey": apiKey,
            ], encoding: URLEncoding.queryString)
        }
        
        private let address: String
        private var page: String
        private var offset: String
        
        /// - Parameter address: the address querying
        /// - Parameter page: the current page number, `1` by default
        /// - Parameter offset: the current page size, `100` by default
        init(address: String, page: Int = 0, offset: Int = 100) {
            self.address = address
            self.page = "\(page)"
            self.offset = "\(offset)"
        }
    }
    
    struct AbiFromContract: EtherscanTargetType {
        typealias ResponseType = EtherscanResponse<String>
        var method: Moya.Method { .get }
        var path: String { "/" }
        var task: Task {
            .requestParameters(parameters: [
                "module": "contract",
                "action": "getabi",
                "address": address,
                "apiKey": apiKey,
            ], encoding: URLEncoding.queryString)
        }
        
        private let address: String
        
        /// - Parameter address: the address querying
        init(address: String) {
            self.address = address
        }
    }
}
