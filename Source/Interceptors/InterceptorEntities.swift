//
//  RequestInterceptorEntities.swift
//  Networkie
//

import Foundation

public enum RequestInterceptorResutltType {
    /// Use this if the interceptor just read the request
    case notModified

    /// Use this if the interceptor modified the request
    case modified(URLRequest)

    /// Use this if the interceptor found an error, with the specific error
    case error(Error)

    /// Use this if the interceptor interrupted the original request, the interruption should handle where it happened
    case interrupt
}

public enum DataTaskResponseInterceptorResutltType {
    /// Use this if the interceptor just read the result
    case notModified

    /// Use this if the interceptor modified the result
    case modified(DataTaskOperationResult)

    /// Use this if the interceptor found an error, with the specific error
    case error(Error)

    /// Use this if the interceptor interrupted the original request, the interruption should handle where it happened
    case interrupt
}

public enum DownloadTaskResponseInterceptorResutltType {
    /// Use this if the interceptor just read the result
    case notModified

    /// Use this if the interceptor modified the result
    case modified(DownloadTaskOperationResult)

    /// Use this if the interceptor found an error, with the specific error
    case error(Error)

    /// Use this if the interceptor interrupted the original request, the interruption should handle where it happened
    case interrupt
}
