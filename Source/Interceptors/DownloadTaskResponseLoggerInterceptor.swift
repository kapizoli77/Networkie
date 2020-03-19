//
//  DownloadTaskResponseLoggerInterceptor.swift
//  Networkie
//

import Foundation

class DownloadTaskResponseLoggerInterceptor: DownloadTaskResponseInterceptorProtocol {
    func adapt(originalResult: DownloadTaskOperationResult?,
               identifier: String,
               completion: @escaping (DownloadTaskResponseInterceptorResutltType) -> Void) {
        logResponse(result: originalResult)
        completion(.notModified)
    }

    private func logResponse(result: DownloadTaskOperationResult?) {
        guard let result = result else {
            debugPrint("There is no result in DataTaskOperation after request execution")
            return
        }

        if let error = result.error {
            HTTPLogger.logError(error as NSError)
        } else {
            HTTPLogger.logResponse(result.urlResponse, data: nil)
        }
    }
}
