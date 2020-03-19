//
//  RequestGroup.swift
//  Networkie
//

import Foundation

public class RequestGroup {
    // MARK: - Properties

    public let identifier = UUID().uuidString
    public var onStatusChanged: ((Int, RequestStatus) -> Void)?
    public var onAllRequestFinished: (([Int: RequestStatus]) -> Void)?

    // MARK: - Initialization

    public init() {}
}

// MARK: - Equatable

extension RequestGroup: Equatable {
    public static func == (lhs: RequestGroup, rhs: RequestGroup) -> Bool {
        return lhs.identifier == rhs.identifier
    }
}
