//
//  BackendServiceEntities.swift
//  Networkie
//

import Foundation

public typealias RequestParameters = [String: Any]
public typealias DataSuccessHandler = (Data, HTTPURLResponse) -> Void
public typealias DownloadSuccessHandler = (URL, HTTPURLResponse) -> Void
public typealias FailureHandler = (NetworkErrorType, HTTPURLResponse?) -> Void

public enum NetworkErrorType: Equatable {
    case requestError
    case networkError(NSError?)
    case parseError(Data)
}

public enum RequestMethod: String {
    case get
    case post
    case put
    case patch
    case delete
}

public enum BackendResponseType {
    case json
    case xml
    case string
}

public enum BackendAuthenticationType {
    case none
    case apiKey
    case token
}

public struct DataResultBlock {
    public let successBlock: DataSuccessHandler?
    public let failureBlock: FailureHandler?
    public let cancelBlock: (() -> Void)?
}

public struct DownloadResultBlock {
    public let successBlock: DownloadSuccessHandler?
    public let failureBlock: FailureHandler?
    public let cancelBlock: (() -> Void)?
}
