//
//  ParallelRequestGroup.swift
//  Networkie
//

import Foundation

public class ParallelRequestGroup: RequestGroup {
    // MARK: - Properties

    private var requests = [Int: RequestProtocol]()
    private var requestStatuses = [Int: RequestStatus]()

    // MARK: - Functions

    public func addRequest(requestFactory: ParallelRequestFactory) {
        let result = requestFactory()
        guard let request = result.request else {
            requestStatuses.updateValue(.skipped, forKey: result.id)
            return
        }

        guard !request.options.startImmediately else {
            assertionFailure("Please use startImmediately property with false value!")
            return
        }

        guard !requests.keys.contains(result.id) else {
            debugPrint("RequestGroup already contains request, skipped: \(request)!")
            return
        }

        requests.updateValue(request, forKey: result.id)
        requestStatuses.updateValue(.created, forKey: result.id)
        if request.requestGroup == nil {
            request.requestGroup = self
        } else {
            debugPrint("Request: \(request) already has a parent RequestGroup!")
        }
    }

    public func start() {
        requests.values.forEach { $0.start() }
    }

    public func cancel() {
        requests.values.forEach { $0.cancel() }
    }
}

// MARK: - RequestGroupProtocol

extension ParallelRequestGroup: RequestGroupProtocol {
    public func statusChanged(for request: RequestProtocol, status: RequestStatus) {
        guard let actualRequestID = requests.first(where: { request.identifier == $0.value.identifier })?.key else {
            assertionFailure("Actual request not set!")
            return
        }

        requestStatuses.updateValue(status, forKey: actualRequestID)
        onStatusChanged?(actualRequestID, status)

        let allFinished = !requestStatuses.contains(where: { $0.value == .created || $0.value == .started || $0.value == .retrying })
        if allFinished {
            onAllRequestFinished?(requestStatuses)
        }
    }
}
