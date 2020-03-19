//
//  NetworkService.swift
//  Networkie
//

import Foundation

open class NetworkService {
    // MARK: - Properties

    private let enableHTTPLogger: Bool
    private let networkRequestTimeOutInterval: Double
    private let urlSession = URLSession.shared

    // MARK: - Initialization

    public init(enableHTTPLogger: Bool, networkRequestTimeOutInterval: Double) {
        self.enableHTTPLogger = enableHTTPLogger
        self.networkRequestTimeOutInterval = networkRequestTimeOutInterval
    }

    // MARK: - Functions

    private func makeRequestWithQuery(request: BackendAPIRequestProtocol,
                                      identifier: String,
                                      delegate: NetworkOperationDelegate,
                                      requestInterceptors: [RequestInterceptorProtocol]?,
                                      responseInterceptors: [DataTaskResponseInterceptorProtocol]?) -> DataTaskOperation? {
        guard let url = request.fullURL else {
            return nil
        }

        var mutableRequest = NetworkQueryGeneretor.makeRequest(for: url,
                                                               params: nil,
                                                               timeOutInterval: networkRequestTimeOutInterval)
        mutableRequest.allHTTPHeaderFields = request.headers
        mutableRequest.httpMethod = request.method.rawValue.uppercased()
        if request.ignoreLocalCache {
            mutableRequest.cachePolicy = .reloadIgnoringLocalCacheData
        }

        let dataTaskOperation = DataTaskOperation(
            urlSession: urlSession,
            request: mutableRequest,
            identifier: identifier,
            delegate: delegate,
            requestInterceptors: requestInterceptors,
            responseInterceptors: responseInterceptors)

        return dataTaskOperation
    }

    private func makeRequestWithBody(request: BackendAPIRequestProtocol,
                                     identifier: String,
                                     delegate: NetworkOperationDelegate,
                                     requestInterceptors: [RequestInterceptorProtocol]?,
                                     responseInterceptors: [DataTaskResponseInterceptorProtocol]?) -> DataTaskOperation? {
        guard let url = request.fullURL else {
            return nil
        }

        var mutableRequest: URLRequest
        if let bodyArray = request.bodyArray {
            mutableRequest = NetworkQueryGeneretor.makeRequest(for: url,
                                                               params: bodyArray,
                                                               timeOutInterval: networkRequestTimeOutInterval)
        } else {
            mutableRequest = NetworkQueryGeneretor.makeRequest(for: url,
                                                               params: request.bodyParameters,
                                                               timeOutInterval: networkRequestTimeOutInterval)
        }

        mutableRequest.allHTTPHeaderFields = request.headers
        mutableRequest.httpMethod = request.method.rawValue.uppercased()

        let dataTaskOperation = DataTaskOperation(
            urlSession: urlSession,
            request: mutableRequest,
            identifier: identifier,
            delegate: delegate,
            requestInterceptors: requestInterceptors,
            responseInterceptors: responseInterceptors)

        return dataTaskOperation
    }
}

// MARK: - NetworkServicdProtocol

extension NetworkService: NetworkServiceProtocol {
    @discardableResult
    public func makeDataTask(request: BackendAPIRequestProtocol,
                             identifier: String,
                             delegate: NetworkOperationDelegate,
                             requestInterceptors: [RequestInterceptorProtocol]?,
                             responseInterceptors: [DataTaskResponseInterceptorProtocol]?) -> DataTaskOperation? {
        let operation: DataTaskOperation?
        switch request.method {
        case .get, .delete:
            operation = makeRequestWithQuery(request: request,
                                             identifier: identifier,
                                             delegate: delegate,
                                             requestInterceptors: requestInterceptors,
                                             responseInterceptors: responseInterceptors)
        default:
            operation = makeRequestWithBody(request: request,
                                            identifier: identifier,
                                            delegate: delegate,
                                            requestInterceptors: requestInterceptors,
                                            responseInterceptors: responseInterceptors)
        }
        return operation
    }

    @discardableResult
    public func makeDownloadTask(request: BackendAPIRequestProtocol,
                                 identifier: String,
                                 delegate: NetworkOperationDelegate,
                                 requestInterceptors: [RequestInterceptorProtocol]?,
                                 responseInterceptors: [DownloadTaskResponseInterceptorProtocol]?) -> DownloadTaskOperation? {
        guard let url = request.fullURL else {
            return nil
        }

        var mutableRequest = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: networkRequestTimeOutInterval)

        mutableRequest.allHTTPHeaderFields = request.headers
        mutableRequest.httpMethod = request.method.rawValue.uppercased()
        if request.ignoreLocalCache {
            mutableRequest.cachePolicy = .reloadIgnoringLocalCacheData
        }

        let downloadTaskOperation = DownloadTaskOperation(
            urlSession: urlSession,
            request: mutableRequest,
            identifier: identifier,
            delegate: delegate,
            requestInterceptors: requestInterceptors,
            responseInterceptors: responseInterceptors)

        return downloadTaskOperation
    }
}
