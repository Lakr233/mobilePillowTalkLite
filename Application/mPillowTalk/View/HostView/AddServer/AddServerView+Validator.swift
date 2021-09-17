//
//  AddServerView+Validator.swift
//  mPillowTalk
//
//  Created by Lakr Aream on 2021/5/4.
//

import Foundation

extension AddServerView {
    func isServerAddrValid(addr: String) -> Bool {
        addr.isValidHostName || validateIpAddress(ipToValidate: addr)
    }
}

enum Regex {
    static let hostname = "^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\\-]*[a-zA-Z0-9])\\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\\-]*[A-Za-z0-9])$"
}

extension String {
    var isValidHostName: Bool {
        matches(pattern: Regex.hostname)
    }

    private func matches(pattern: String) -> Bool {
        range(of: pattern,
              options: .regularExpression,
              range: nil,
              locale: nil) != nil
    }
}

private func validateIpAddress(ipToValidate: String) -> Bool {
    var sin = sockaddr_in()
    var sin6 = sockaddr_in6()

    if ipToValidate.withCString({ cstring in inet_pton(AF_INET6, cstring, &sin6.sin6_addr) }) == 1 {
        // IPv6 peer.
        return true
    } else if ipToValidate.withCString({ cstring in inet_pton(AF_INET, cstring, &sin.sin_addr) }) == 1 {
        // IPv4 peer.
        return true
    }

    return false
}
