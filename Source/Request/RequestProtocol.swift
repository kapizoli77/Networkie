//
//  RequestProtocol.swift
//  Networkie
//

import Foundation

public protocol RequestProtocol: class {
    var identifier: String { get }
    var status: RequestStatus { get }
    var requestGroup: RequestGroupProtocol? { get set }
    var options: RequestOptions { get }

    @discardableResult
    func start() -> Bool
    func cancel()
}
