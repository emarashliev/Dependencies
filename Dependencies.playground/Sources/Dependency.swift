//
//  Dependency.swift
//  
//
//  Created by Emil Marashliev on 27.01.25.
//

import Foundation

@propertyWrapper
public struct Dependency<Value>: Sendable {
    let initialValues: DependencyValues

    private let keyPath: KeyPath<DependencyValues, Value> & Sendable

    public init(_ keyPath: KeyPath<DependencyValues, Value> & Sendable) {
        self.initialValues = DependencyValues.current
        self.keyPath = keyPath
    }

    public init<Key: DependencyKey>(_ key: Key.Type) where Key.Value == Value {
        self.init(\DependencyValues.[key: HashableType<Key>()])
    }

    public var wrappedValue: Value {
        DependencyValues.current[keyPath: self.keyPath]
    }
}

private struct HashableType<T>: Hashable, Sendable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        true
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(T.self))
    }
}

extension DependencyValues {
    fileprivate subscript<Key: DependencyKey>(key key: HashableType<Key>) -> Key.Value {
        get {
            self[Key.self]
        }
        set {
            self[Key.self] = newValue
        }
    }
}
