//
//  RequestGroupProtocol.swift
//  Networkie
//

import Foundation

public protocol RequestGroupProtocol: class {
    func statusChanged(for request: RequestProtocol, status: RequestStatus)
}
