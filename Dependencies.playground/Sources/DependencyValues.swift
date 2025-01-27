//
//  DependencyValues.swift
//  
//
//  Created by Emil Marashliev on 27.01.25.
//

import Foundation

public struct DependencyValues: Sendable {
    private var storage: [ObjectIdentifier: any Sendable] = [:]
    
    public subscript<Key: DependencyKey>(key: Key.Type) -> Key.Value {
        get {
            if let value = storage[ObjectIdentifier(key)] as? Key.Value {
                return value
            } else {
                return Key.currentValue
            }
        }
        
        set {
            storage[ObjectIdentifier(key)] = newValue
        }
    }
    
    @TaskLocal public static var current = Self()
}
