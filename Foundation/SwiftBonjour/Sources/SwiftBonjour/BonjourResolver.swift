//
//  BonjourResolver.swift
//  SwiftBonjour
//
//  Created by Rachel on 2021/5/18.
//

import Foundation

public class BonjourResolver {
    public init(service: NetService) {
        self.service = service
    }

    let service: NetService
    let delegate: BonjourResolverDelegate = BonjourResolverDelegate()

    public func resolve(withTimeout timeout: TimeInterval, completion: @escaping (Result<NetService, ErrorDictionary>) -> Void) {
        delegate.onResolve = completion
        service.delegate = delegate
        service.resolve(withTimeout: timeout)
    }

    deinit {
        BonjourLogger.verbose(self)
        service.stop()
    }

}

public typealias ErrorDictionary = [String: Int]
extension ErrorDictionary: Error {}

extension BonjourResolver {
    class BonjourResolverDelegate: NSObject, NetServiceDelegate {
        var onResolve: ((Result<NetService, ErrorDictionary>) -> Void)?

        func netService(_ sender: NetService, didNotResolve errorDict: [String: NSNumber]) {
            BonjourLogger.fault("Bonjour service did not resolve", sender, errorDict)
            let transformed = errorDict.mapValues { value in
                Int(truncating: value)
            }
            onResolve?(Result.failure(transformed))
        }

        func netServiceDidResolveAddress(_ sender: NetService) {
            BonjourLogger.info("Bonjour service resolved", sender)
            onResolve?(Result.success(sender))
        }

        func netServiceWillResolve(_ sender: NetService) {
            BonjourLogger.info("Bonjour service will resolve", sender)
        }
    }
}
