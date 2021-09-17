//
//  BonjourBrowser.swift
//  SwiftBonjour
//
//  Created by Rachel on 2021/5/18.
//

import Foundation

public class BonjourBrowser {
    var netServiceBrowser: NetServiceBrowser
    var delegate: BonjourBrowserDelegate

    public var services = Set<NetService>()

    // Handlers
    public var serviceFoundHandler: ((NetService) -> Void)?
    public var serviceRemovedHandler: ((NetService) -> Void)?
    public var serviceResolvedHandler: ((Result<NetService, ErrorDictionary>) -> Void)?


    public var isSearching = false {
        didSet {
            BonjourLogger.info(isSearching)
        }
    }

    public init() {
        netServiceBrowser = NetServiceBrowser()
        delegate = BonjourBrowserDelegate()
        netServiceBrowser.delegate = delegate
        delegate.browser = self
    }

    public func browse(type: ServiceType, domain: String = "") {
        browse(type: type.description, domain: domain)
    }

    public func browse(type: String, domain: String = "") {
        stop()
        netServiceBrowser.searchForServices(ofType: type, inDomain: domain)
    }

    fileprivate func serviceFound(_ service: NetService) {
        services.update(with: service)
        serviceFoundHandler?(service)

        // resolve services if handler is registered
        guard let serviceResolvedHandler = serviceResolvedHandler else { return }
        var resolver: BonjourResolver? = BonjourResolver(service: service)
        resolver?.resolve(withTimeout: 0) { result in
            serviceResolvedHandler(result)
            // retain resolver until resolution
            resolver = nil
        }
    }

    fileprivate func serviceRemoved(_ service: NetService) {
        services.remove(service)
        serviceRemovedHandler?(service)
    }

    public func stop() {
        netServiceBrowser.stop()
    }

    deinit {
        stop()
    }
}

class BonjourBrowserDelegate: NSObject, NetServiceBrowserDelegate {
    weak var browser: BonjourBrowser?
    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        BonjourLogger.info("Bonjour service found", service)
        self.browser?.serviceFound(service)
    }

    func netServiceBrowserWillSearch(_ browser: NetServiceBrowser) {
        BonjourLogger.info("Bonjour browser will search")
        self.browser?.isSearching = true
    }

    func netServiceBrowserDidStopSearch(_ browser: NetServiceBrowser) {
        BonjourLogger.info("Bonjour browser stopped search")
        self.browser?.isSearching = false
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch errorDict: [String: NSNumber]) {
        BonjourLogger.debug("Bonjour browser did not search", errorDict)
        self.browser?.isSearching = false
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
        BonjourLogger.info("Bonjour service removed", service)
        self.browser?.serviceRemoved(service)
    }
}
