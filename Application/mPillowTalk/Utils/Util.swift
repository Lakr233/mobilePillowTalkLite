//
//  Util.swift
//  mPillowTalk
//
//  Created by Innei on 2021/4/25.
//

import Foundation
import UIKit

public let device = UIDevice.current.userInterfaceIdiom
public let isPhone = device == .phone
public let isPad = device == .pad

@propertyWrapper
struct Atomic<Value> {
    private var value: Value
    private let lock = NSLock()

    init(wrappedValue value: Value) {
        self.value = value
    }

    var wrappedValue: Value {
        get { load() }
        set { store(newValue: newValue) }
    }

    func load() -> Value {
        lock.lock()
        defer { lock.unlock() }
        return value
    }

    mutating func store(newValue: Value) {
        lock.lock()
        defer { lock.unlock() }
        value = newValue
    }
}
