//
//  BackendService.swift
//  Networkie
//

import Foundation


// Backend service handles the API call itself
open class BackendService {
    // MARK: - Properties

    public let networkService: NetworkServiceProtocol
    public let networkQueue = OperationQueue()
    public let resultQueue = OperationQueue.main
    public var activeRequests = Set<Request>()

    private let requestLoggerInterceptor = RequestLoggerInterceptor()
    private let dataTaskResponseLoggerInterceptor = DataTaskResponseLoggerInterceptor()
    private let downloadTaskResponseLoggerInterceptor = DownloadTaskResponseLoggerInterceptor()

    // MARK: - Initialization

    public init(networkService: NetworkServiceProtocol) {
        self.networkService = networkService
    }

    // MARK: - Functions

    open func defaultRequestInterceptors(by request: BackendAPIRequestProtocol) -> [RequestInterceptorProtocol] {
        return [requestLoggerInterceptor]
    }

    open func defaultDataTaskResponseInterceptors(by request: BackendAPIRequestProtocol) -> [DataTaskResponseInterceptorProtocol] {
        return [dataTaskResponseLoggerInterceptor]
    }

    open func defaultDownloadTaskResponseInterceptors(by request: BackendAPIRequestProtocol) -> [DownloadTaskResponseInterceptorProtocol] {
        return [downloadTaskResponseLoggerInterceptor]
    }

    open func generateRequestOptions(by urlRequest: BackendAPIRequestProtocol) -> RequestOptions {
        return RequestOptions(maxRetryCount: 0,
                              startImmediately: urlRequest.startImmediately)
    }

    open func resultBlock<T: Codable>(urlRequest: BackendAPIRequestProtocol,
                                      type: T.Type,
                                      success: ((T, HTTPURLResponse) -> Void)?,
                                      failure: FailureHandler?,
                                      cancel: (() -> Void)?) -> DataResultBlock {
        return DataResultBlock(
            successBlock: { [weak self] data, httpURLResponse in
                let parsedResponse: T?
                switch urlRequest.backendResponseType {
                case .json:
                    parsedResponse = self?.decodeResponseAsJSON(request: urlRequest, data: data)
                case .xml:
                    parsedResponse = self?.decodeResponseAsXML(request: urlRequest, data: data)
                case .string:
                    parsedResponse = self?.decodeResponseAsString(request: urlRequest, data: data)
                }

                if let response = parsedResponse {
                    success?(response, httpURLResponse)
                } else {
                    failure?(.parseError(data), httpURLResponse)
                }
            }, failureBlock: failure,
               cancelBlock: cancel)
    }

    open func resultBlock(urlRequest: BackendAPIRequestProtocol,
                          destinationURL: URL,
                          success: ((URL, HTTPURLResponse) -> Void)?,
                          failure: FailureHandler?,
                          cancel: (() -> Void)?) -> DownloadResultBlock {
        return DownloadResultBlock(
            successBlock: { localURL, httpURLResponse in
                try? FileManager.default.removeItem(at: destinationURL)

                do {
                    try FileManager.default.copyItem(at: localURL, to: destinationURL)
                    DispatchQueue.main.async {
                        debugPrint("[BackendService]: Download file finished with success for endpoint: " + urlRequest.apiURL)

                        success?(destinationURL, httpURLResponse)
                    }
                } catch {
                    DispatchQueue.main.async {
                        debugPrint("[BackendService]: Download file finished but copy to destination url failed: " + urlRequest.apiURL)

                        failure?(.requestError, httpURLResponse)
                    }
                }
            }, failureBlock: failure,
            cancelBlock: cancel)
    }

    @discardableResult
    open func requestObject<T: Codable>(_ urlRequest: BackendAPIRequestProtocol,
                                        type: T.Type,
                                        resultBlock: DataResultBlock) -> RequestProtocol? {
        return requestObject(urlRequest,
                             type: type,
                             resultBlock: resultBlock,
                             requestInterceptors: defaultRequestInterceptors(by: urlRequest),
                             dataTaskResponseInterceptors: defaultDataTaskResponseInterceptors(by: urlRequest))
    }

    @discardableResult
    open func requestObject<T: Codable>(_ urlRequest: BackendAPIRequestProtocol,
                                        type: T.Type,
                                        resultBlock: DataResultBlock,
                                        requestInterceptors: [RequestInterceptorProtocol],
                                        dataTaskResponseInterceptors: [DataTaskResponseInterceptorProtocol]) -> RequestProtocol? {
        return DataRequest(urlRequest: urlRequest,
                           resultBlock: resultBlock,
                           delegate: self,
                           requestInterceptors: requestInterceptors,
                           responseInterceptors: dataTaskResponseInterceptors,
                           options: generateRequestOptions(by: urlRequest))
    }

    @discardableResult
    open func requestFile(_ urlRequest: BackendAPIRequestProtocol,
                          resultBlock: DownloadResultBlock) -> RequestProtocol? {
        requestFile(urlRequest,
                    resultBlock: resultBlock,
                    requestInterceptors: defaultRequestInterceptors(by: urlRequest),
                    downloadTaskResponseInterceptors: defaultDownloadTaskResponseInterceptors(by: urlRequest))
    }

    @discardableResult
    open func requestFile(_ urlRequest: BackendAPIRequestProtocol,
                          resultBlock: DownloadResultBlock,
                          requestInterceptors: [RequestInterceptorProtocol],
                          downloadTaskResponseInterceptors: [DownloadTaskResponseInterceptorProtocol]) -> RequestProtocol? {
        return DownloadRequest(urlRequest: urlRequest,
                               resultBlock: resultBlock,
                               delegate: self,
                               requestInterceptors: requestInterceptors,
                               responseInterceptors: downloadTaskResponseInterceptors,
                               options: generateRequestOptions(by: urlRequest))
    }

    open func makeNetworkOperation(by request: DataRequest) -> NetworkOperation? {
        return networkService.makeDataTask(
            request: request.urlRequest,
            identifier: request.identifier,
            delegate: request,
            requestInterceptors: request.requestInterceptors,
            responseInterceptors: request.responseInterceptors)
    }

    open func makeNetworkOperation(by request: DownloadRequest) -> NetworkOperation? {
        return networkService.makeDownloadTask(
            request: request.urlRequest,
            identifier: request.identifier,
            delegate: request,
            requestInterceptors: request.requestInterceptors,
            responseInterceptors: request.responseInterceptors)
    }

    open func decodeResponseAsJSON<T: Codable>(request: BackendAPIRequestProtocol,
                                               data: Data) -> T? {
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = request.dateDecodingStrategy
            let modelResponse = try decoder.decode(T.self, from: data)
            return modelResponse
        } catch let error {
            debugPrint(error)
            return nil
        }
    }

    open func decodeResponseAsString<T: Codable>(request: BackendAPIRequestProtocol,
                                                 data: Data) -> T? {
        if let stringResponse = String(data: data, encoding: .utf8) as? T {
            return stringResponse
        } else {
            assertionFailure("In case of string response type always provide String type for response")
            return nil
        }
    }

    open func decodeResponseAsXML<T: Codable>(request: BackendAPIRequestProtocol,
                                              data: Data) -> T? {
        assertionFailure("XML parsing is not implemented. Override this function and implement in case of needed.")
        return nil
    }

    open func handleSuccess(request: DataRequest) {
        guard let operation = request.dataTaskoperation else {
            return
        }

        let cleanupOperation = BlockOperation { [weak self] in
            self?.cleanup(request: request)
        }

        let resultOperation = BlockOperation()
        cleanupOperation.addDependency(resultOperation)

        if let result = operation.result,
            let data = result.data,
            let urlResponse = result.urlResponse as? HTTPURLResponse {
            resultOperation.addExecutionBlock {
                request.resultBlock.successBlock?(data, urlResponse)
            }
        } else {
            debugPrint("DataTaskOperationResult is invalid \(String(describing: operation.result))")
        }

        resultQueue.addOperation(resultOperation)
        resultQueue.addOperation(cleanupOperation)
    }

    open func handleSuccess(request: DownloadRequest) {
        guard let operation = request.downloadTaskoperation else {
            return
        }

        let cleanupOperation = BlockOperation { [weak self] in
            self?.cleanup(request: request)
        }

        let resultOperation = BlockOperation()
        cleanupOperation.addDependency(resultOperation)

        if let result = operation.result,
            let url = result.url,
            let urlResponse = result.urlResponse as? HTTPURLResponse {
            resultOperation.addExecutionBlock {
                request.resultBlock.successBlock?(url, urlResponse)
            }
        } else {
            debugPrint("DownloadTaskOperationResult is invalid")
        }

        resultQueue.addOperation(resultOperation)
        resultQueue.addOperation(cleanupOperation)
    }

    open func handleFail(request: DataRequest) {
        guard let operation = request.dataTaskoperation else {
            return
        }

        let cleanupOperation = BlockOperation { [weak self] in
            self?.cleanup(request: request)
        }

        let resultOperation = BlockOperation()
        cleanupOperation.addDependency(resultOperation)

        resultOperation.addExecutionBlock {
            request.resultBlock.failureBlock?(
                NetworkErrorType.networkError(operation.result?.error as NSError?),
                operation.result?.urlResponse as? HTTPURLResponse)
        }

        resultQueue.addOperation(resultOperation)
        resultQueue.addOperation(cleanupOperation)
    }

    open func handleFail(request: DownloadRequest) {
        guard let operation = request.downloadTaskoperation else {
            return
        }

        let cleanupOperation = BlockOperation { [weak self] in
            self?.cleanup(request: request)
        }

        let resultOperation = BlockOperation()
        cleanupOperation.addDependency(resultOperation)

        resultOperation.addExecutionBlock {
            request.resultBlock.failureBlock?(
                NetworkErrorType.networkError(operation.result?.error as NSError?),
                operation.result?.urlResponse as? HTTPURLResponse)
        }

        resultQueue.addOperation(resultOperation)
        resultQueue.addOperation(cleanupOperation)
    }

    open func handleCancel(request: DataRequest) {
        guard request.operation != nil else {
            return
        }

        let cleanupOperation = BlockOperation { [weak self] in
            self?.cleanup(request: request)
        }

        let resultOperation = BlockOperation()
        cleanupOperation.addDependency(resultOperation)

        resultOperation.addExecutionBlock {
            request.resultBlock.cancelBlock?()
        }

        resultQueue.addOperation(resultOperation)
        resultQueue.addOperation(cleanupOperation)
    }

    open func handleCancel(request: DownloadRequest) {
        guard request.operation != nil else {
            return
        }

        let cleanupOperation = BlockOperation { [weak self] in
            self?.cleanup(request: request)
        }

        let resultOperation = BlockOperation()
        cleanupOperation.addDependency(resultOperation)

        resultOperation.addExecutionBlock {
            request.resultBlock.cancelBlock?()
        }

        resultQueue.addOperation(resultOperation)
        resultQueue.addOperation(cleanupOperation)
    }

    open func cleanup(request: Request) {
        activeRequests.remove(request)
    }
}

// MARK: - RequestDelegate

extension BackendService: RequestDelegate {
    private func requestWillStart(_ request: DataRequest) {
        guard let operation = makeNetworkOperation(by: request) else {
            debugPrint("Operation can't be create for request: \(request)")
            return
        }

        request.operation = operation
        activeRequests.insert(request)
        networkQueue.addOperation(operation)
    }

    private func requestWillStart(_ request: DownloadRequest) {
        guard let operation = makeNetworkOperation(by: request) else {
            debugPrint("Operation can't be create for request: \(request)")
            return
        }

        request.operation = operation
        activeRequests.insert(request)
        networkQueue.addOperation(operation)
    }

    public func requestWillStart(_ request: Request) {
        if let dataRequest = request as? DataRequest {
            requestWillStart(dataRequest)
        } else if let downloadRequest = request as? DownloadRequest {
            requestWillStart(downloadRequest)
        } else {
            debugPrint("Unhandled Request type")
        }
    }

    public func requestDidStart(_ request: Request) {
        guard activeRequests.contains(request) else {
            debugPrint("There is no active request with id: \(request.identifier)")
            return
        }

        debugPrint("\(request) is started")
        request.status = .started
    }

    public func requestDidFinish(_ request: Request) {
        guard activeRequests.contains(request) else {
            debugPrint("There is no active request with id: \(request.identifier)")
            return
        }

        guard let operation = request.operation else {
            debugPrint("Operation cannot be nil!")
            return
        }

        if let dataRequest = request as? DataRequest {
            requestDidFinish(dataRequest, operation: operation)
        } else if let downloadRequest = request as? DownloadRequest {
            requestDidFinish(downloadRequest, operation: operation)
        } else {
            debugPrint("Unhandled Request type")
        }
    }

    func requestDidFinish(_ request: DataRequest, operation: NetworkOperation) {
        DispatchQueue.main.async { [weak self] in
            if operation.isSuccess {
                request.status = .success
                self?.handleSuccess(request: request)
            } else if operation.isCancelled {
                request.status = .cancelled
                self?.handleCancel(request: request)
            } else if operation.isInterrupted {
                // We have to handle this state where we interrupt the operation
                request.status = .interrupted
            } else {
                request.status = .fail
                self?.handleFail(request: request)
            }
        }
    }

    func requestDidFinish(_ request: DownloadRequest, operation: NetworkOperation) {
        if operation.isSuccess {
            request.status = .success
            handleSuccess(request: request)
        } else if operation.isCancelled {
            request.status = .cancelled
            handleCancel(request: request)
        } else if operation.isInterrupted {
            // We have to handle this state where we interrupt the operation
            request.status = .interrupted
        } else {
            request.status = .fail
            handleFail(request: request)
        }
    }
}

// MARK: - RetryDelegate

extension BackendService: RetryDelegate {
    public func retry(with identifier: String) {
        guard let request = activeRequests.first(where: { $0.identifier == identifier }) else {
            debugPrint("There is no active request with id: \(identifier)")
            return
        }

        if let dataRequest = request as? DataRequest {
            retry(request: dataRequest)
        } else if let downloadRequest = request as? DownloadRequest {
            retry(request: downloadRequest)
        } else {
            debugPrint("Unhandled Request type")
            cleanup(request: request)
        }
    }

    private func retry(request: DataRequest) {
        guard request.canRetry else {
            // Can't retry, call fail block
            handleFail(request: request)
            return
        }

        guard let newOperation = makeNetworkOperation(by: request) else {
            debugPrint("Operation can't be create for request: \(request)")
            return
        }

        // Retry
        request.retry(with: newOperation)
        networkQueue.addOperation(newOperation)
    }

    private func retry(request: DownloadRequest) {
        guard request.canRetry else {
            // Can't retry, call fail block
            handleFail(request: request)
            return
        }

        guard let newOperation = makeNetworkOperation(by: request) else {
            debugPrint("Operation can't be create for request: \(request)")
            return
        }

        // Retry
        request.retry(with: newOperation)
        networkQueue.addOperation(newOperation)
    }
}
