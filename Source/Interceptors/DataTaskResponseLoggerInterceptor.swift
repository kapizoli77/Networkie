//
//  DataTaskResponseLoggerInterceptor.swift
//  Networkie
//

import Foundation

class DataTaskResponseLoggerInterceptor: DataTaskResponseInterceptorProtocol {
    func adapt(originalResult: DataTaskOperationResult?,
               identifier: String,
               completion: @escaping (DataTaskResponseInterceptorResutltType) -> Void) {
        logResponse(result: originalResult)
        completion(.notModified)
    }

    private func logResponse(result: DataTaskOperationResult?) {
        guard let result = result else {
            debugPrint("There is no result in DataTaskOperation after request execution")
            return
        }

        if let error = result.error {
            HTTPLogger.logError(error as NSError)
        } else {
            HTTPLogger.logResponse(result.urlResponse, data: result.data)
        }
    }
}
