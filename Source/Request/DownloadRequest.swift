//
//  DownloadRequest.swift
//  Networkie
//

import Foundation

public class DownloadRequest: Request {
    // MARK: - Properties

    public let resultBlock: DownloadResultBlock
    public let responseInterceptors: [DownloadTaskResponseInterceptorProtocol]?
    public var downloadTaskoperation: DownloadTaskOperation? {
        return operation as? DownloadTaskOperation
    }

    // MARK: - Initialization

    public init(urlRequest: BackendAPIRequestProtocol,
                resultBlock: DownloadResultBlock,
                delegate: RequestDelegate? = nil,
                requestInterceptors: [RequestInterceptorProtocol]?,
                responseInterceptors: [DownloadTaskResponseInterceptorProtocol]?,
                options: RequestOptions) {
        self.resultBlock = resultBlock
        self.responseInterceptors = responseInterceptors

        super.init(urlRequest: urlRequest, delegate: delegate, requestInterceptors: requestInterceptors, options: options)

        if options.startImmediately {
            start()
        }
    }
}
