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

// MARK: API singleton basic structure
final public class API {
    public static let shared = API()
    private init() {}
    private let provider = MoyaProvider<MultiTarget>()
    
    public func request<Request: DecodableResponseTargetType>(_ request: Request, keyPath: String? = nil) -> AnyPublisher<Request.ResponseType, MoyaError> {
        let target = MultiTarget.init(request)
        return provider
            .requestPublisher(target)
            .filterSuccessfulStatusCodes()
            .map(Request.ResponseType.self, atKeyPath: keyPath)
    }
}

public protocol DecodableResponseTargetType: TargetType {
    associatedtype ResponseType: Decodable
}

