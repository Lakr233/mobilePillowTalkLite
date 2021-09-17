//
//  BonjourServer.swift
//  SwiftBonjour
//
//  Created by Rachel on 2021/5/18.
//

import Foundation

public class BonjourServer {
    
    public private(set) var serviceType: ServiceType
    public private(set) var netService: NetService
    var delegate: BonjourServerDelegate?
    var successCallback: ((Bool) -> Void)?
    
    public fileprivate(set) var started = false {
        didSet {
            successCallback?(started)
            successCallback = nil
        }
    }
    
    public var txtRecord: [String: String]? {
        get {
            return netService.txtRecordDictionary
        }
        set {
            netService.setTXTRecord(dictionary: newValue)
            BonjourLogger.info("TXT Record updated", newValue as Any)
        }
    }

    public init(type: ServiceType, domain: String = "", name: String = "", port: Int32 = 0) {
        serviceType = type
        netService = NetService(domain: domain, type: type.description, name: name, port: port)
        delegate = BonjourServerDelegate()
        delegate?.server = self
        netService.delegate = delegate
    }
    
    public func start(options: NetService.Options = [.listenForConnections]) {
        start(options: options, success: successCallback)
    }

    public func start(options: NetService.Options = [.listenForConnections], success: ((Bool) -> Void)?) {
        if started {
            success?(true)
            return
        }
        successCallback = success
        netService.schedule(in: RunLoop.current, forMode: RunLoop.Mode.common)
        netService.publish(options: options)
    }

    public func stop() {
        netService.stop()
    }

    deinit {
        stop()
        netService.delegate = nil
        delegate = nil
    }
}

class BonjourServerDelegate: NSObject, NetServiceDelegate {
    weak var server: BonjourServer?

    func netServiceDidPublish(_ sender: NetService) {
        server?.started = true
        BonjourLogger.info("Bonjour server started at domain \(sender.domain) port \(sender.port)")
    }

    func netService(_ sender: NetService, didNotPublish errorDict: [String: NSNumber]) {
        server?.started = false
        BonjourLogger.fault("Bonjour server did not publish", errorDict)
    }

    func netServiceDidStop(_ sender: NetService) {
        server?.started = false
        BonjourLogger.info("Bonjour server stoped")
    }
}
