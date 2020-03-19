//
//  RequestEntities.swift
//  Networkie
//

import Foundation

public enum RequestStatus {
    /// Created, but not yet started
    case created

    /// Execution started
    case started

    /// Retrying to execute
    case retrying

    /// Execution success
    case success

    /// Execution fail
    case fail

    /// Execution cancelled
    case cancelled

    /// Execution interrupted
    case interrupted

    /// Execution skipped
    case skipped
}

public struct RequestOptions {
    let maxRetryCount: Int
    let startImmediately: Bool

    public init(maxRetryCount: Int, startImmediately: Bool) {
        self.maxRetryCount = maxRetryCount
        self.startImmediately = startImmediately
    }
}

public typealias ParallelRequestFactory = () -> (id: Int, request: RequestProtocol?)
public typealias SerialRequestFactory = (RequestStatus) -> (id: Int, request: RequestProtocol?)
