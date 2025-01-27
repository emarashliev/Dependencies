//
//  WithDependencies.swift
//
//
//  Created by Emil Marashliev on 27.01.25.
//

import Foundation


extension NSRecursiveLock {
    @inlinable @discardableResult
    @_spi(Internals) public func sync<R>(work: () throws -> R) rethrows -> R {
        self.lock()
        defer { self.unlock() }
        return try work()
    }
}

@dynamicMemberLookup
public final class LockIsolated<Value>: @unchecked Sendable {
    private var _value: Value
    private let lock = NSRecursiveLock()

    public init(_ value: @autoclosure @Sendable () throws -> Value) rethrows {
        self._value = try value()
    }

    public subscript<Subject: Sendable>(dynamicMember keyPath: KeyPath<Value, Subject>) -> Subject {
        self.lock.sync {
            self._value[keyPath: keyPath]
        }
    }

    public func withValue<T: Sendable>(
        _ operation: @Sendable (inout Value) throws -> T
    ) rethrows -> T {
        try self.lock.sync {
            var value = self._value
            defer { self._value = value }
            return try operation(&value)
        }
    }

    public func setValue(_ newValue: @autoclosure @Sendable () throws -> Value) rethrows {
        try self.lock.sync {
            self._value = try newValue()
        }
    }
}

extension LockIsolated where Value: Sendable {
    public var value: Value {
        self.lock.sync {
            self._value
        }
    }
}

private struct DependencyObject: @unchecked Sendable {
    private weak var object: AnyObject?
    let dependencyValues: DependencyValues
    init(object: AnyObject, dependencyValues: DependencyValues) {
        self.object = object
        self.dependencyValues = dependencyValues
    }
    var isNil: Bool {
        object == nil
    }
}
private final class DependencyObjects: Sendable {
    private let storage = LockIsolated<[ObjectIdentifier: DependencyObject]>([:])

    internal init() {}

    func store(_ object: AnyObject) {
        let dependencyObject = DependencyObject(
            object: object,
            dependencyValues: DependencyValues.current
        )
        self.storage.withValue { [id = ObjectIdentifier(object)] storage in
            storage[id] = dependencyObject
            Task {
                self.storage.withValue { storage in
                    for (id, object) in storage where object.isNil {
                        storage.removeValue(forKey: id)
                    }
                }
            }
        }
    }
}

private let dependencyObjects = DependencyObjects()

@discardableResult
public func withDependencies<R>(
    _ updateValuesForOperation: (inout DependencyValues) throws -> Void,
    operation: () throws -> R
) rethrows -> R {
    var dependencies = DependencyValues.current
    try updateValuesForOperation(&dependencies)
    return try DependencyValues.$current.withValue(dependencies) {
        let result = try operation()
        if R.self is AnyClass {
            dependencyObjects.store(result as AnyObject)
        }
        return result
    }
}
