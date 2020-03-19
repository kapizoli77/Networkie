//
//  HTTPLogger.swift
//  Networkie
//

import Foundation

public final class HTTPLogger {
    // MARK: - Properties

    private struct PrivateConstants {
        static let trimBodyAtLength = 1000
    }

    // MARK: - Functions

    public class func logError(_ error: NSError) {
        var logString = "⚠️\n"
        logString += "Error: \n\(error.localizedDescription)\n"

        if let reason = error.localizedFailureReason {
            logString += "Reason: \(reason)\n"
        }

        if let suggestion = error.localizedRecoverySuggestion {
            logString += "Suggestion: \(suggestion)\n"
        }
        logString += "\n\n*************************\n\n"

        debugPrint(logString)
    }

    public class func logRequest(_ request: URLRequest) {
        var logString = "\n📤"
        if let url = request.url?.absoluteString {
            logString += "Request: \n  \(request.httpMethod!) \(url)\n"
        }

        if let headers = request.allHTTPHeaderFields {
            logString += "Header:\n"
            logString += logHeaders(headers as [String: AnyObject]) + "\n"
        }

        if let data = request.httpBody,
            let bodyString = NSString(data: data, encoding: String.Encoding.utf8.rawValue) {
            logString += "Body:\n"
            logString += trimTextOverflow(bodyString as String)
        }

        if let dataStream = request.httpBodyStream {
            let bufferSize = 1024
            var buffer = [UInt8](repeating: 0, count: bufferSize)

            let data = NSMutableData()
            dataStream.open()
            while dataStream.hasBytesAvailable {
                let bytesRead = dataStream.read(&buffer, maxLength: bufferSize)
                data.append(buffer, length: bytesRead)
            }

            if let bodyString = NSString(data: data as Data, encoding: String.Encoding.utf8.rawValue) {
                logString += "Body:\n"
                logString += trimTextOverflow(bodyString as String)
            }
        }

        logString += "\n\n*************************\n\n"
        debugPrint(logString)
    }

    public class func logResponse(_ response: URLResponse?, data: Data? = nil) {
        var logString = "\n📥"
        if let response = response, let url = response.url?.absoluteString {
            logString += "Response: \n  \(url)\n"
        }

        if let httpResponse = response as? HTTPURLResponse {
            let localisedStatus = HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode).capitalized
            logString += "Status: \n  \(httpResponse.statusCode) - \(localisedStatus)\n"
        }

        if let headers = (response as? HTTPURLResponse)?.allHeaderFields as? [String: AnyObject] {
            logString += "Header: \n"
            logString += self.logHeaders(headers) + "\n"
        }

        guard let data = data else {
            return
        }

        do {
            let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers)
            let pretty = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)

            if let string = NSString(data: pretty, encoding: String.Encoding.utf8.rawValue) {
                logString += "\nJSON: \n\(string)"
            }
        } catch {
            if let string = NSString(data: data, encoding: String.Encoding.utf8.rawValue) {
                logString += "\nData: \n\(string)"
            }
        }

        logString += "\n\n*************************\n\n"
        debugPrint(logString)
    }

    public class func logHeaders(_ headers: [String: AnyObject]) -> String {
        let string = headers.reduce(String()) { str, header in
            let string = "  \(header.0) : \(header.1)"
            return str + "\n" + string
        }
        let logString = "[\(string)\n]"
        return logString
    }

    private class func trimTextOverflow(_ string: String) -> String {
        guard string.count > PrivateConstants.trimBodyAtLength else {
            return string
        }

        return string[..<string.index(string.startIndex, offsetBy: PrivateConstants.trimBodyAtLength)].appending("…")
    }
}

// MARK: - Sources

/**
 https://github.com/muukii-archive/HTTPLogger

 The MIT License (MIT)

 Copyright (c) 2016 Hiroshi Kimura

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 */
