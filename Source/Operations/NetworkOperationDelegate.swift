//
//  NetworkOperationDelegate.swift
//  Networkie
//

import Foundation

public protocol NetworkOperationDelegate: class {
    func operationDidStart(_ operation: NetworkOperation)
    func operationDidFinish(_ operation: NetworkOperation)
}
