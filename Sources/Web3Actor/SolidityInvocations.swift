//
//  SolodityInvocations.swift
//  
//
//  Created by RBLabs RD - Shane on 2023/7/18.
//

import Foundation
import Web3ContractABI

public protocol BetterInvocation {
    /// Invokes this function with the provided values
    ///
    /// - Parameters:
    ///     - inputs: values for parameters of the method. Must be in the correct order.
    /// - Returns: Invocation object
    func betterInvoke(_ inputs: [ABIEncodable]) -> SolidityInvocation
    var type: SolidityFunctionType { get }
}

public enum SolidityFunctionType {
    case constant
    case payable
    case nonPayable
}

extension SolidityConstantFunction: BetterInvocation {
    public var type: SolidityFunctionType { .constant }
    public func betterInvoke(_ inputs: [ABIEncodable]) -> SolidityInvocation {
        return SolidityReadInvocation(method: self, parameters: inputs, handler: handler)
    }
}

extension SolidityNonPayableFunction: BetterInvocation {
    public var type: SolidityFunctionType { .nonPayable }
    public func betterInvoke(_ inputs: [ABIEncodable]) -> SolidityInvocation {
        return SolidityNonPayableInvocation(method: self, parameters: inputs, handler: handler)
    }
}

extension SolidityPayableFunction: BetterInvocation {
    public var type: SolidityFunctionType { .payable }
    public func betterInvoke(_ inputs: [ABIEncodable]) -> SolidityInvocation {
        return SolidityPayableInvocation(method: self, parameters: inputs, handler: handler)
    }
}
