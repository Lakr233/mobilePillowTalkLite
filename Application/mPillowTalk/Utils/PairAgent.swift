//
//  PairAgent.swift
//  mPillowTalk
//
//  Created by Lakr Aream on 5/17/21.
//

import GCDWebServers
import PTFoundation
import UIKit

class PairAgent {
    static let shared = PairAgent()

    private static let port = PTTransfer.suggestedHttpPort
    private let webServer = GCDWebServer()
    private let lock = NSLock()
    private let bonjourName = NSLocalizedString("PILLOW_TALK_CONFIGURATOR", comment: "Pillow Talk Configurator") + " " + String(Int.random(in: 10000 ... 99999))

    public var uploadedData: String = ""

    private init() {
        webServer.addDefaultHandler(forMethod: "GET",
                                    request: GCDWebServerRequest.self)
        { request -> GCDWebServerResponse? in
            guard let base64 = request.query?["conf"] else {
                return .init(statusCode: 404)
            }
            self.uploadedData = base64
            return .init(statusCode: 200)
        }
    }

    var webServerStarted = false
    func startWebServer() {
        if webServerStarted {
            return
        }
        webServerStarted = true
        lock.lock()
        let sem = DispatchSemaphore(value: 0)
        DispatchQueue.main.async {
            self.webServer.start(withPort: PairAgent.port,
                                 bonjourName: self.bonjourName)
            sem.signal()
        }
        sem.wait()
        lock.unlock()
        PTLog.shared.join(self,
                          "accepting incoming connection at port: \(PairAgent.port)",
                          level: .info)
    }

    func tearDownServer() {
        if !webServerStarted {
            return
        }
        webServerStarted = false
        lock.lock()
        let sem = DispatchSemaphore(value: 0)
        DispatchQueue.main.async {
            self.webServer.stop()
            sem.signal()
        }
        sem.wait()
        lock.unlock()
        PTLog.shared.join(self,
                          "configurator stopped listening for connections",
                          level: .info)
    }

    func startTransfer(withData: String, withPIN: String, withInWindow: UIWindow, onComplete: @escaping () -> Void) {
        let testResult = PTTransfer.shared.testDecryption(base64: withData, pin: withPIN)
        if !testResult {
            let alert = UIAlertController(title: NSLocalizedString("ERROR", comment: "Error"),
                                          message: NSLocalizedString("FAILED_DECRYPT_DATA_ALERT_TINT", comment: "Failed to decrypt transferred data, PIN may be invalid. Please try again later."),
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("DONE", comment: "Done"),
                                          style: .default,
                                          handler: nil))
            withInWindow.topMostViewController?.present(alert, animated: true, completion: nil)
            onComplete()
            return
        }
        var alerts = [UIAlertController]()
        for window in UIApplication.shared.windows {
            let alert = UIAlertController(title: NSLocalizedString("PLEASE_WAIT", comment: "Please Wait"),
                                          message: NSLocalizedString("TRANSFER_IN_PROGRESS_ALERT_TINT", comment: "Transfer in progress"),
                                          preferredStyle: .alert)
            window.topMostViewController?.present(alert, animated: true, completion: nil)
            alerts.append(alert)
        }
        DispatchQueue.global().async {
            PTTransfer.shared.applyTransferPackage(base64: withData, pin: withPIN, fromMainThread: true)
            DispatchQueue.main.async {
                for alert in alerts {
                    alert.dismiss(animated: true, completion: nil)
                }
                onComplete()
            }
        }
    }

    func obtainBonjourName() -> String {
        bonjourName
    }
}
