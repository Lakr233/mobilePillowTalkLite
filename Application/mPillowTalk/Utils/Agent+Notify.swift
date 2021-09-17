//
//  Agent+Notify.swift
//  mPillowTalk
//
//  Created by Lakr Aream on 4/30/21.
//

import PTFoundation
import UIKit

extension Agent {
    func prepareNotifications() {
        // 服务器注册列表的 binding
        let serverCountLink = PTNotificationCenter.NotificationLink(name: .ServerManager_RegistrationChanged,
                                                                    throttle: PTThrottle(minimumDelay: 1, queue: .global())) { _ in
            self.updateServerRegistrationInfo()
        }
        PTNotificationCenter.shared.registeringNotification(withLink: serverCountLink)
        // 捷径的 binding
        let scriptLink = PTNotificationCenter.NotificationLink(name: .CodeClip_RegistrationChanged,
                                                               throttle: PTThrottle(minimumDelay: 1, queue: .global())) { _ in
            self.clipDataSender = UUID()
        }
        PTNotificationCenter.shared.registeringNotification(withLink: scriptLink)
        DispatchQueue.global().async {
            self.clipDataSender = UUID()
            self.updateServerRegistrationInfo()
        }
    }

    private func updateServerRegistrationInfo() {
        serverDescriptorsSender = PTServerManager.shared.obtainServerList().map { x in
            x.uuid
        }
        serverSectionsSender = PTServerManager.shared.obtainRegisteredServerSectionList()
        debugPrint("PTNotificationCenter ServerManager_RegistrationChanged \(serverDescriptorsSender.count)")
    }
}
