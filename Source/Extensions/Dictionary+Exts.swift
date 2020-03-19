//
//  Dictionary+Exts.swift
//  Networkie
//

import Foundation

extension Dictionary where Key == String, Value == Any {
    public func encodedString() -> String? {
        let sortedKeyArray = keys.sorted()

        var keyValueSortedArray = [Any]()

        for key in sortedKeyArray {
            keyValueSortedArray.append(key)

            let value = self[key]!
            keyValueSortedArray.append(value)
        }

        let encodedString = try? JSONSerialization.data(withJSONObject: keyValueSortedArray, options: []).base64EncodedString()

        return encodedString
    }
}
