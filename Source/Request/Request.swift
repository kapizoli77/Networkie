//
//  Request.swift
//  Networkie
//

import Foundation

// Abstract class to manage requests

public class Request {
    // MARK: - Properties

    public let identifier = UUID().uuidString
    public let urlRequest: BackendAPIRequestProtocol
    public let requestInterceptors: [RequestInterceptorProtocol]?
    public weak var delegate: RequestDelegate?
    public var operation: NetworkOperation?
    public private(set) var retryCount: Int = 0
    public let options: RequestOptions
    public var requestGroup: RequestGroupProtocol?
    public var status: RequestStatus = .created {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }

                self.requestGroup?.statusChanged(for: self, status: self.status)
            }
        }
    }

    public var canRetry: Bool {
        guard status == .cancelled || status == .fail || status == .interrupted else {
            debugPrint("Request can't retry, actual status is: \(status)")
            return false
        }

        guard retryCount < options.maxRetryCount else {
            debugPrint("Request can't retry, retryCount reached maxRetryCount")
            return false
        }

        return true
    }

    // MARK: - Initialization

    public init(urlRequest: BackendAPIRequestProtocol,
                delegate: RequestDelegate? = nil,
                requestInterceptors: [RequestInterceptorProtocol]?,
                options: RequestOptions) {
        self.urlRequest = urlRequest
        self.delegate = delegate
        self.requestInterceptors = requestInterceptors
        self.options = options
    }

    // MARK: - Functions

    public func retry(with newOperation: NetworkOperation) {
        self.operation = newOperation
        status = .retrying
        retryCount += 1
    }
}

// MARK: - Hashable

extension Request: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
}

// MARK: - Equatable

extension Request: Equatable {
    public static func == (lhs: Request, rhs: Request) -> Bool {
        return lhs.identifier == rhs.identifier
    }
}

// MARK: - RequestProtocol

extension Request: RequestProtocol {
    @discardableResult
    public func start() -> Bool {
        guard status == .created else {
            debugPrint("Request already started!")
            return false
        }

        delegate?.requestWillStart(self)
        return true
    }

    public func cancel() {
        guard status == .created || status == .started || status == .retrying else {
            debugPrint("Request is not running!")
            return
        }

        operation?.cancel()
    }
}

// MARK: - NetworkOperationDelegate

extension Request: NetworkOperationDelegate {
    public func operationDidStart(_ operation: NetworkOperation) {
        delegate?.requestDidStart(self)
    }

    public func operationDidFinish(_ operation: NetworkOperation) {
        delegate?.requestDidFinish(self)
    }
}
