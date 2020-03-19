//
//  RequestLoggerInterceptor.swift
//  Networkie
//

import Foundation

class RequestLoggerInterceptor: RequestInterceptorProtocol {
    func adapt(originalRequest: URLRequest,
               identifier: String,
               completion: @escaping (RequestInterceptorResutltType) -> Void) {
        HTTPLogger.logRequest(originalRequest)
        completion(.notModified)
    }
}
