//
//  SerialRequestGroup.swift
//  Networkie
//

import Foundation

public class SerialRequestGroup: RequestGroup {
    // MARK: - Properties

    private var requestFactories = [SerialRequestFactory]()
    private var requestStatuses = [Int: RequestStatus]()
    private var idFactoryMap = [Int: Int]()
    private var actualRequest: RequestProtocol?
    private var actualRequestID: Int?
    private var groupCancelled = false

    // MARK: - Functions

    public func addRequest(requestFactory: @escaping SerialRequestFactory) {
        requestFactories.append(requestFactory)
    }

    public func start() {
        serialExecution(previousRequestStatus: .success, previousRequestIndex: -1)
    }

    public func cancel() {
        groupCancelled = true
        actualRequest?.cancel()
    }

    func callFinishCompletion() {
        guard requestStatuses.count > 0 else {
            debugPrint("Empty Serial request queue, add at least 1 request to the group!")
            return
        }

        let allFinished = !requestStatuses.contains(where: { $0.value == .created || $0.value == .started || $0.value == .retrying })
        if allFinished {
            onAllRequestFinished?(requestStatuses)
        }
    }

    private func serialExecution(previousRequestStatus: RequestStatus, previousRequestIndex: Int) {
        let actualRequestIndex = previousRequestIndex + 1
        guard let factory = requestFactories[safe: actualRequestIndex] else {
            debugPrint("There are no more requests in this group!")
            actualRequest = nil
            actualRequestID = nil
            callFinishCompletion()
            return
        }

        let result = factory(previousRequestStatus)
        idFactoryMap.updateValue(actualRequestIndex, forKey: result.id)

        guard let request = result.request else {
            requestStatuses.updateValue(.skipped, forKey: result.id)
            return
        }

        guard !request.options.startImmediately else {
            assertionFailure("Please use startImmediately property with false value!")
            return
        }

        if request.requestGroup == nil {
            request.requestGroup = self
        } else {
            debugPrint("Request: \(request) already has a parent RequestGroup!")
        }

        requestStatuses.updateValue(.created, forKey: result.id)
        actualRequest = request
        actualRequestID = result.id

        if groupCancelled {
            request.cancel()
        } else {
            request.start()
        }
    }
}

// MARK: - RequestGroupProtocol

extension SerialRequestGroup: RequestGroupProtocol {
    public func statusChanged(for request: RequestProtocol, status: RequestStatus) {
        guard let actualRequestID = actualRequestID else {
            assertionFailure("Actual request not set!")
            return
        }

        guard let actualRequestIndex = idFactoryMap[actualRequestID] else {
            assertionFailure("Factory map not set for actual request!")
            return
        }

        requestStatuses.updateValue(status, forKey: actualRequestID)
        onStatusChanged?(actualRequestID, status)

        if status == .success || status == .fail || status == .cancelled {
            serialExecution(previousRequestStatus: status, previousRequestIndex: actualRequestIndex)
        }
    }
}
