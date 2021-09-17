//
//  Executable.swift
//  PTFoundation
//
//  Created by Lakr Aream on 1/19/21.
//

import Foundation

public struct ExecuteEnvironment {
    public var payload: [String: String] = [:]
    public var server: String?

    public init(payload: [String: String] = [:], server: String? = nil) {
        self.payload = payload
        self.server = server
    }
}

public struct ExecuteRecipe {
    public var code: Int = 0
    public var ouput: String = ""
    public var vars: [String: String] = [:]
    public var error: String?
}

protocol Executable {
    func execute(fromEnvironment env: ExecuteEnvironment?,
                 output: ((String) -> Void)?,
                 terminate: (() -> (Bool))?) -> ExecuteRecipe

    func execAsync(fromEnvironment env: ExecuteEnvironment?,
                   queue: DispatchQueue,
                   output: ((String) -> Void)?,
                   terminate: (() -> (Bool))?,
                   onComplete complete: @escaping (ExecuteRecipe) -> Void)
}
