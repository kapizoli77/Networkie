//
//  DataTaskOperation.swift
//  Networkie
//

import Foundation

public typealias DataTaskOperationResult = (data: Data?, urlResponse: URLResponse?, error: Error?)

open class DataTaskOperation: NetworkOperation {
    // MARK: - Properties

    private let requestInterceptors: [RequestInterceptorProtocol]?
    private let responseInterceptors: [DataTaskResponseInterceptorProtocol]?
    public private(set) var result: DataTaskOperationResult?

    private let urlSession: URLSession
    private var request: URLRequest
    private var task: URLSessionDataTask?
    private lazy var taskFactory: (URLSession, URLRequest, @escaping (Bool) -> Void) -> URLSessionDataTask? = { urlSession, request, completion in
        return urlSession.dataTask(
            with: request,
            completionHandler: { [weak self] data, response, error in
                guard let self = self else { return }

                defer {
                    var success = error == nil
                    if let statusCode = (response as? HTTPURLResponse)?.statusCode {
                        success = statusCode == HTTPStatusCode.ok.rawValue || statusCode == HTTPStatusCode.created.rawValue
                    }
                    completion(success)
                }

                self.result = DataTaskOperationResult(data: data, urlResponse: response, error: error)
            }
        )
    }

    // MARK: - Initialization

    init(urlSession: URLSession,
         request: URLRequest,
         identifier: String,
         delegate: NetworkOperationDelegate?,
         requestInterceptors: [RequestInterceptorProtocol]?,
         responseInterceptors: [DataTaskResponseInterceptorProtocol]?) {
        self.requestInterceptors = requestInterceptors
        self.responseInterceptors = responseInterceptors
        self.urlSession = urlSession
        self.request = request

        super.init(identifier: identifier, delegate: delegate)
    }

    // MARK: - NetworkOperation functions

    open override func cancel() {
        task?.cancel()
        super.cancel()
    }

    open override func main(completion: @escaping (Bool) -> Void) {
        task = taskFactory(urlSession, request, completion)
        task?.resume()
    }

    open override func performRequestInterceptors(completion: @escaping (Bool) -> Void) {
        /// There are no Response Interceptors
        guard let requestInterceptors = requestInterceptors, requestInterceptors.count > 0  else {
            completion(true)
            return
        }

        /// Call all interceptor's adapt function sequentially
        var closures = [(Int) -> Void]()
        let closureFactory: (RequestInterceptorProtocol) -> ((Int) -> Void) = { requestInterceptor in
            let closure: (Int) -> Void = { [weak self] index in
                guard let self = self else { return }

                guard let requestInterceptor = requestInterceptors[safe: index] else {
                    completion(true)
                    return
                }

                requestInterceptor.adapt(
                    originalRequest: self.request,
                    identifier: self.identifier,
                    completion: { [weak self] resultType in
                        switch resultType {
                        case .interrupt:
                            // Must to interrupt operation
                            self?.interrupt()
                            return
                        case .error(let error):
                            // There is an error, stop executing
                            self?.result = DataTaskOperationResult(data: nil, urlResponse: nil, error: error)
                            completion(false)
                            return
                        case .modified(let newRequest):
                            // Got a modified request, save it
                            self?.request = newRequest
                            fallthrough
                        case .notModified:
                            // There is no modification

                            // Call the next closure or if this is the last closure, call the completion closure
                            let nextIndex = index + 1
                            if let nextClosure = closures[safe: nextIndex] {
                                nextClosure(nextIndex)
                            } else {
                                completion(true)
                            }
                        }
                    }
                )
            }
            return closure
        }

        requestInterceptors.forEach { requestInterceptor in
            closures.append(closureFactory(requestInterceptor))
        }

        closures.first?(0)
    }

    open override func performResponseInterceptors(completion: @escaping (Bool) -> Void) {
        /// There are no Request Interceptors
        guard let responseInterceptors = responseInterceptors, responseInterceptors.count > 0  else {
            completion(true)
            return
        }

        /// Call all interceptor's adapt function sequentially
        var closures = [(Int) -> Void]()
        let closureFactory: (DataTaskResponseInterceptorProtocol) -> ((Int) -> Void) = { responseInterceptor in
            let closure: (Int) -> Void = { [weak self] index in
                guard let self = self else { return }

                guard let responseInterceptor = responseInterceptors[safe: index] else {
                    completion(true)
                    return
                }

                responseInterceptor.adapt(
                    originalResult: self.result,
                    identifier: self.identifier,
                    completion: { [weak self] resultType in
                        switch resultType {
                        case .interrupt:
                            // Must to interrupt operation
                            self?.interrupt()
                            return
                        case .error(let error):
                            /// There is an error, stop executing
                            self?.result = DataTaskOperationResult(data: nil, urlResponse: nil, error: error)
                            completion(false)
                            return
                        case .modified(let newResult):
                            /// Got a modified request, save it
                            self?.result = newResult
                        case .notModified:
                            /// There is no modification
                            ()
                        }

                        /// Call the next closure or if this is the last closure, call the completion closure
                        let nextIndex = index + 1
                        if let nextClosure = closures[safe: nextIndex] {
                            nextClosure(nextIndex)
                        } else {
                            completion(true)
                        }
                    }
                )
            }
            return closure
        }

        responseInterceptors.forEach { responseInterceptor in
            closures.append(closureFactory(responseInterceptor))
        }

        closures.first?(0)
    }
}
