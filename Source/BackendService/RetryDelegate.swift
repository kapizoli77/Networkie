//
//  RetryDelegate.swift
//  Networkie
//

import Foundation

public protocol RetryDelegate: class {
    func retry(with identifier: String)
}
