//
//  FunctionSet+Protocol.swift
//  PTFoundation
//
//  Created by Lakr Aream on 12/13/20.
//

import Foundation

/// 一个服务器方法集所需要提供的全部方法
protocol PTServerSelectorsProtocol {
    func obtainIdentity() -> String
    func setupConnection(withServer server: PTServerManager.Server) -> Any?
    func connect(withCandidate candidate: Any) -> (Any?, String?)
    func disconnect(withConnection connection: Any)
    func obtainServerProcessInfo(withConnection connection: Any) -> PTServerManager.ServerProcessInfo
    func obtainMemoryInfo(withConnection connection: Any) -> PTServerManager.ServerMemoryInfo
    func obtainServerFileSystemInfo(withConnection connection: Any) -> [PTServerManager.ServerFileSystemInfo]
    func obtainSystemInfo(withConnection connection: Any) -> PTServerManager.ServerSystemInfo
    func obtainServerNetworkInfo(withConnection connection: Any) -> [PTServerManager.ServerNetworkInfo]
    func executeScript(withConnection connection: Any,
                       script: String,
                       requestPty: Bool,
                       withEnvironment: [String: String],
                       output: ((String) -> Void)?,
                       terminate: (() -> (Bool))?) -> Int?
    func openShell(withConnection connection: Any,
                   withEnvironment: [String: String],
                   delegate: Any?) -> Any?
}

/// 用父类去做简易类型擦除
public class PTServerAllocationSelectors: PTServerSelectorsProtocol {
    public static let allSets = [PTServerSSHLinuxSelectors.shared]

    func obtainIdentity() -> String {
        fatalError("[PTServerAllocationSelectors] is only used for allocating server type")
    }

    func setupConnection(withServer _: PTServerManager.Server) -> Any? {
        fatalError("[PTServerAllocationSelectors] is only used for allocating server type")
    }

    func connect(withCandidate _: Any) -> (Any?, String?) {
        fatalError("[PTServerAllocationSelectors] is only used for allocating server type")
    }

    func disconnect(withConnection _: Any) {
        fatalError("[PTServerAllocationSelectors] is only used for allocating server type")
    }

    func obtainServerProcessInfo(withConnection _: Any) -> PTServerManager.ServerProcessInfo {
        fatalError("[PTServerAllocationSelectors] is only used for allocating server type")
    }

    func obtainMemoryInfo(withConnection _: Any) -> PTServerManager.ServerMemoryInfo {
        fatalError("[PTServerAllocationSelectors] is only used for allocating server type")
    }

    func obtainServerFileSystemInfo(withConnection _: Any) -> [PTServerManager.ServerFileSystemInfo] {
        fatalError("[PTServerAllocationSelectors] is only used for allocating server type")
    }

    func obtainSystemInfo(withConnection _: Any) -> PTServerManager.ServerSystemInfo {
        fatalError("[PTServerAllocationSelectors] is only used for allocating server type")
    }

    func obtainServerNetworkInfo(withConnection _: Any) -> [PTServerManager.ServerNetworkInfo] {
        fatalError("[PTServerAllocationSelectors] is only used for allocating server type")
    }

    func executeScript(withConnection _: Any,
                       script _: String,
                       requestPty _: Bool,
                       withEnvironment _: [String: String],
                       output _: ((String) -> Void)?,
                       terminate _: (() -> (Bool))?) -> Int?
    {
        fatalError("[PTServerAllocationSelectors] is only used for allocating server type")
    }

    func openShell(withConnection _: Any,
                   withEnvironment _: [String: String],
                   delegate _: Any?) -> Any?
    {
        fatalError("[PTServerAllocationSelectors] is only used for allocating server type")
    }
}
