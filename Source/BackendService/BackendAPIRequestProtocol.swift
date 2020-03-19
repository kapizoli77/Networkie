//
//  BackendAPIRequestProtocol.swift
//  Networkie
//

import Foundation

// Interface for describing a standard  API call
public protocol BackendAPIRequestProtocol {
    /// URL created from apiURL that already includes query parameters
    var fullURL: URL? { get }

    /// URL string that are given to the request object, query parameters are not contained.
    var apiURL: String { get }

    var method: RequestMethod { get }
    var backendResponseType: BackendResponseType { get }

    /// If you create a GET or a DELETE request, please use ONLY query params (bodyParams will be ignored)
    var queryParameters: RequestParameters? { get }
    var bodyParameters: RequestParameters? { get }

    /// bodyArray priority over bodyParameters
    var bodyArray: [Any]? { get }
    var headers: [String: String] { get }

    var backendAuthenticationType: BackendAuthenticationType { get }
    var dateDecodingStrategy: JSONDecoder.DateDecodingStrategy { get }
    var startImmediately: Bool { get set }
}

extension BackendAPIRequestProtocol {
    public var fullURL: URL? {
        guard let url = URL(string: apiURL),
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                return nil
        }

        if let queryItems = NetworkQueryGeneretor.makeQueryItems(params: queryParameters) {
            if components.queryItems != nil {
                components.queryItems?.append(contentsOf: queryItems)
            } else {
                components.queryItems = queryItems
            }
        }

        components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
        components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "@", with: "%40")

        return components.url
    }

    public var backendResponseType: BackendResponseType {
        return .json
    }

    public var uniqueKey: String {
        var key = apiURL

        key.append(method.rawValue)

        if let queryParametersString = queryParameters?.encodedString() {
            key.append(queryParametersString)
        }

        if let bodyParametersString = bodyParameters?.encodedString() {
            key.append(bodyParametersString)
        }

        return key
    }

    public var queryParameters: RequestParameters? {
        return nil
    }

    public var bodyParameters: RequestParameters? {
        return nil
    }

    public var bodyArray: [Any]? {
        return nil
    }

    public var noCacheControl: Bool {
        return false
    }

    public var ignoreLocalCache: Bool {
        return false
    }

    public var headers: [String: String] {
        var headers = defaultJSONHeaders()

        if noCacheControl == true {
            headers["Cache-control"] = "no-cache"
        }

        return headers
    }

    public func defaultJSONHeaders() -> [String: String] {
        let defaultJSONHeaders = ["Content-Type": "application/json"]
        return defaultJSONHeaders
    }

    public var dateDecodingStrategy: JSONDecoder.DateDecodingStrategy {
        return .deferredToDate
    }
}
