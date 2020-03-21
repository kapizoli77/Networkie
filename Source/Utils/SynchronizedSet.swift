//
//  SynchronizedSet.swift
//  Networkie
//

import Foundation

/// It has to be a class, otherwise it can cause Swift Access Races
/// https://developer.apple.com/documentation/code_diagnostics/thread_sanitizer/swift_access_races
public class SynchronizedSet<Element> where Element : Hashable {
    private let queue: DispatchQueue
    private var set: Set<Element>

    /// Constructor
    /// - Parameters:
    ///   - queue: DispatchQueue where operations are executing synchronously, do not use main queue!
    ///   - set: initial set
    public init(queue: DispatchQueue = DispatchQueue(label: "SynchronizedSet"), set: Set<Element> = Set<Element>()) {
        self.queue = queue
        self.set = set
    }

    @discardableResult
    public func remove(_ member: Element) -> Element? {
        var result: Element?
        queue.sync { result = set.remove(member) }
        return result
    }

    @discardableResult
    public func insert(_ newMember: Element) -> (inserted: Bool, memberAfterInsert: Element) {
        var result: (inserted: Bool, memberAfterInsert: Element)?
        queue.sync { result = set.insert(newMember) }
        return result ?? (inserted: false, memberAfterInsert: newMember)
    }

    public func contains(_ member: Element) -> Bool {
        var result: Bool?
        queue.sync { result = set.contains(member) }
        return result ?? false
    }

    @discardableResult
    public func first(where predicate: (Element) throws -> Bool) rethrows -> Element? {
        var result: Element?
        queue.sync {
            result = try? set.first(where: predicate)
        }
        return result
    }
}
