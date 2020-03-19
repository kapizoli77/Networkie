//
//  DataRequest.swift
//  Networkie
//

import Foundation

public class DataRequest: Request {
    // MARK: - Properties

    public let resultBlock: DataResultBlock
    public let responseInterceptors: [DataTaskResponseInterceptorProtocol]?
    public var dataTaskoperation: DataTaskOperation? {
        return operation as? DataTaskOperation
    }

    // MARK: - Initialization

    public init(urlRequest: BackendAPIRequestProtocol,
                resultBlock: DataResultBlock,
                delegate: RequestDelegate? = nil,
                requestInterceptors: [RequestInterceptorProtocol]?,
                responseInterceptors: [DataTaskResponseInterceptorProtocol]?,
                options: RequestOptions) {
        self.resultBlock = resultBlock
        self.responseInterceptors = responseInterceptors

        super.init(urlRequest: urlRequest, delegate: delegate, requestInterceptors: requestInterceptors, options: options)

        if options.startImmediately {
            start()
        }
    }
}
