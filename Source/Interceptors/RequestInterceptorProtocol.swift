//
//  RequestInterceptorProtocol.swift
//  Networkie
//

import Foundation

public protocol InterceptorProtocol {}

public protocol RequestInterceptorProtocol: InterceptorProtocol {
    func adapt(originalRequest: URLRequest,
               identifier: String,
               completion: @escaping (RequestInterceptorResutltType) -> Void)
}

public protocol ResponseInterceptorProtocol: InterceptorProtocol {}

public protocol DataTaskResponseInterceptorProtocol: ResponseInterceptorProtocol {
    func adapt(originalResult: DataTaskOperationResult?,
               identifier: String,
               completion: @escaping (DataTaskResponseInterceptorResutltType) -> Void)
}

public protocol DownloadTaskResponseInterceptorProtocol: ResponseInterceptorProtocol {
    func adapt(originalResult: DownloadTaskOperationResult?,
               identifier: String,
               completion: @escaping (DownloadTaskResponseInterceptorResutltType) -> Void)
}
