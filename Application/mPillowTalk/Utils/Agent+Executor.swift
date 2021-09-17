//
//  Agent+Dispatcher.swift
//  mPillowTalk
//
//  Created by Lakr Aream on 4/30/21.
//

import LocalAuthentication
import PTFoundation
import UIKit

private var authSuccessThrottle: Bool = false

extension Agent {
    func startUserAuthentication() {
        authenticationWithBioID {
            self.authorizationStatusSender = .authorized
        } onFailure: { _ in
            self.authorizationStatusSender = .unauthorized
        }
    }

    func authenticationWithBioID(onSuccess: @escaping () -> Void,
                                 onFailure: @escaping (String) -> Void)
    {
        if authSuccessThrottle == true {
            onSuccess()
            return
        }

        let localAuthenticationContext = LAContext()
        localAuthenticationContext.localizedFallbackTitle = NSLocalizedString("USE_PASSWORD", comment: "Please use password")

        var authorizationError: NSError?
        let reason = NSLocalizedString("AUTH_ERQUIRED", comment: "Authentication enabled and required")

        if localAuthenticationContext.canEvaluatePolicy(.deviceOwnerAuthentication, error: &authorizationError) {
            localAuthenticationContext.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, evaluateError in
                if success {
                    authSuccessThrottle = true
                    DispatchQueue.global().asyncAfter(deadline: .now() + 3) {
                        authSuccessThrottle = false
                    }
                    onSuccess()
                } else {
                    guard let error = evaluateError else { return }
                    onFailure(error.localizedDescription)
                }
            }
        } else {
            guard let error = authorizationError else { return }
            onFailure(error.localizedDescription)
        }
    }

    func authenticationWithBioIDSyncAndReturnIsSuccessOrError() -> (Bool, String?) {
        let sem = DispatchSemaphore(value: 0)
        var success = false
        var error: String?
        DispatchQueue.global().async {
            self.authenticationWithBioID {
                success = true
                sem.signal()
            } onFailure: { str in
                error = str
                sem.signal()
            }
        }
        _ = sem.wait(wallTimeout: .now() + 60)
        return (success, error)
    }

    func createTerminal(withInstance: PersistTerminalInstance) {
        // TODO: Thread Safe
        var get = terminalInstanceSender
        get.append(withInstance)
        terminalInstanceSender = get
    }

    func removeTerminal(withInstance: PersistTerminalInstance) {
        // TODO: Thread Safe
        let get = terminalInstanceSender
        var new = [PersistTerminalInstance]()
        for item in get where item.id != withInstance.id {
            new.append(item)
        }
        terminalInstanceSender = new
    }
}
