//
//  ServiceType.swift
//  SwiftBonjour
//
//  Created by Rachel on 2021/5/18.
//

import Foundation

public enum ServiceType {
    case tcp(String)
    case udp(String)

    public var description: String {
        switch self {
        case .tcp(let name):
            return "_\(name)._tcp."
        case .udp(let name):
            return "_\(name)._udp."
        }
    }
}
