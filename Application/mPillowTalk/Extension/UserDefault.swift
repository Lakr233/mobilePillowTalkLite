//
//  UserDefault.swift
//  mPillowTalk
//
//  Created by Lakr Aream on 4/17/21.
//

import Foundation

@propertyWrapper
public struct UserDefaultsWrapper<Value> {
    let key: String
    let defaultValue: Value
    var storage: UserDefaults = .standard

    public var wrappedValue: Value {
        get {
            let value = storage.value(forKey: key) as? Value
            return value ?? defaultValue
        }
        set {
            storage.setValue(newValue, forKey: key)
            UserDefaults.standard.synchronize()
        }
    }
}

public extension UserDefaultsWrapper where Value: ExpressibleByNilLiteral {
    init(key: String, storage: UserDefaults = .standard) {
        self.init(key: key, defaultValue: nil, storage: storage)
    }
}
