//
//  NetworkServiceProtocol.swift
//  Networkie
//

import Foundation

public protocol NetworkServiceProtocol {
    @discardableResult
    func makeDataTask(request: BackendAPIRequestProtocol,
                      identifier: String,
                      delegate: NetworkOperationDelegate,
                      requestInterceptors: [RequestInterceptorProtocol]?,
                      responseInterceptors: [DataTaskResponseInterceptorProtocol]?) -> DataTaskOperation?

    @discardableResult
    func makeDownloadTask(request: BackendAPIRequestProtocol,
                          identifier: String,
                          delegate: NetworkOperationDelegate,
                          requestInterceptors: [RequestInterceptorProtocol]?,
                          responseInterceptors: [DownloadTaskResponseInterceptorProtocol]?) -> DownloadTaskOperation?
}
