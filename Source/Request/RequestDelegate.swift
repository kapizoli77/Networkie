//
//  RequestDelegate.swift
//  Networkie
//

import Foundation

public protocol RequestDelegate: class {
    func requestWillStart(_ request: Request)
    func requestDidStart(_ request: Request)
    func requestDidFinish(_ request: Request)
}
