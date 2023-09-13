//
//  File.swift
//  
//
//  Created by RBLabs RD - Shane on 2023/7/27.
//

import Foundation
import Moya

// MARK: Opensea APIs

protocol OpenseaTargetType: DecodableResponseTargetType {}

extension OpenseaTargetType {
    var baseURL: URL { URL(string: "https://api.opensea.io/api")! }
    var headers: [String : String]? {
        [
            "Accept": "application/json",
            "X-API-KEY": apiKey,
        ]
    }
    private var apiKey: String {
        ActorHelper.shared.openseaApiKey
    }
}

struct OpenseaResponse<T: Codable>: Codable {}

enum OpenseaAPIs {}

// MARK: Assets

extension OpenseaAPIs {
    struct retrieveCollections: OpenseaTargetType {
        typealias ResponseType = [Opensea.Collection]
        var method: Moya.Method { .get }
        var path: String { "/v1/collections" }
        var task: Task {
            .requestParameters(parameters: [
                "asset_owner": address,
                "offset": offset,
                "limit": limit,
            ], encoding: URLEncoding.queryString)
        }
        
        private let address: String
        private var offset: Int
        private var limit: Int
        
        /// - Parameter address: the address querying
        /// - Parameter offset: the current page offset, `0` by default
        /// - Parameter limit: the current page size, `300` by default
        init(address: String, offset: Int = 0, limit: Int = 300) {
            self.address = address
            self.offset = offset
            self.limit = limit
        }
        
        
    }
}
