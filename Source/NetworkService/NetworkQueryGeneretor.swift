//
//  NetworkQueryGeneretor.swift
//  Networkie
//

import Foundation

public struct NetworkQueryGeneretor {
    // MARK: - Functions

    public static func makeRequest(for url: URL, params: Any?, timeOutInterval: Double) -> URLRequest {
        var mutableRequest = URLRequest(url: url,
                                        cachePolicy: .useProtocolCachePolicy,
                                        timeoutInterval: timeOutInterval)
        if let params = params {
            mutableRequest.httpBody = try? JSONSerialization.data(withJSONObject: params, options: [])
        }

        return mutableRequest
    }

    /// Convert a `Parameters` list in an URL query
    ///
    /// - Parameter params: The list of `Parameters`
    /// - Returns: The string that represents an URL query
    public static func makeQueryItems(params: RequestParameters?) -> [URLQueryItem]? {
        guard let params = params else {
            return nil
        }

        var query = [URLQueryItem]()

        params.forEach { key, value in
            if let array = value as? [Any] {
                parseQueryArray(key: key, array: array, query: &query)
            } else {
                let valueString = "\(value)"
                query.append(URLQueryItem(name: key, value: valueString))
            }
        }

        return query
    }

    private static func parseQueryArray(key: String, array: [Any], query: inout [URLQueryItem]) {
        for item in array {
            if let tmp = item as? [Any] {
                parseQueryArray(key: key, array: tmp, query: &query)
            } else {
                let arrayKey = key + "[]"
                let valueString = "\(item)"
                query.append(URLQueryItem(name: arrayKey, value: valueString))
            }
        }
    }
}

// MARK: - Sources, Base idea

// http://szulctomasz.com/how-do-I-build-a-network-layer/
