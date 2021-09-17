//
//  ServerStatusBlock.swift
//  uPillowTalk
//
//  Created by Lakr Aream on 1/2/21.
//

import PTFoundation
import SwiftUI

struct ServerStatusBlockView: View {
    let isPlaceHolder: Bool
    let descriptor: PTServerManager.ServerDescriptor?

    init(descriptor: PTServerManager.ServerDescriptor?, isPlaceHolder: Bool = false) {
        self.isPlaceHolder = isPlaceHolder
        self.descriptor = descriptor
    }

    @State var info: PTServerManager.ServerInfoHumanReadable? = nil
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State var validDescription = ""
    @State var cpu: Double = 0
    @State var ram: Double = 0
    @State var disk: Double = 0

    @State var notificationLinkID: String = ""
    let padding: CGFloat = 12

    var body: some View {
        VStack {
            HStack(alignment: .top, spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    if info == nil || isPlaceHolder {
                        Text("8888888888888888")
                            .font(.system(size: 12))
                            .redacted(reason: .placeholder)
                        Text("888888888888")
                            .font(.system(size: 8))
                            .opacity(0.75)
                            .redacted(reason: .placeholder)
                    } else {
                        Text(info!.serverTitle)
                            .font(.system(size: 14, weight: .semibold))
                        Spacer().frame(width: 2, height: 2)
                        Text(info!.serverSubtitle)
                            .font(.system(size: 8))
                            .opacity(0.75)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 0) {
                    HStack(spacing: 2) {
                        if info == nil || isPlaceHolder {
                            Text("88888888")
                                .font(.system(size: 12))
                                .redacted(reason: .placeholder)
                            Rectangle()
                                .frame(width: 9, height: 9, alignment: .center)
                                .cornerRadius(2)
                                .redacted(reason: .placeholder)
                                .opacity(0.233)
                        } else {
                            switch info!.newState {
                            case "normal":
                                Text(validDescription)
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundColor(.green)
                                    .onReceive(timer) { _ in
                                        updateTimeDescription()
                                    }
                                    .onAppear {
                                        updateTimeDescription()
                                    }
                                Image(systemName: "largecircle.fill.circle")
                                    .scaleEffect(0.8)
                                    .foregroundColor(.green)
                            case "animatebleLoading":
                                Text(NSLocalizedString("IN_UPDATE", comment: "In Update"))
                                    .font(.system(size: 12))
                                    .foregroundColor(.blue)
                                Image(systemName: "largecircle.fill.circle")
                                    .scaleEffect(0.8)
                                    .foregroundColor(.blue)
                            case "outdate":
                                Text(NSLocalizedString("OUTDATED", comment: "Outdated"))
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                                Image(systemName: "largecircle.fill.circle")
                                    .scaleEffect(0.8)
                                    .foregroundColor(.gray)
                            case "error":
                                Text(NSLocalizedString("ERROR", comment: "Error"))
                                    .font(.system(size: 12))
                                    .foregroundColor(.red)
                                Image(systemName: "largecircle.fill.circle")
                                    .scaleEffect(0.8)
                                    .foregroundColor(.red)
                            default:
                                Text(NSLocalizedString("NO_DATA", comment: "No Data"))
                                    .font(.system(size: 12))
                                Image(systemName: "largecircle.fill.circle")
                                    .scaleEffect(0.8)
                            }
                        }
                    }
                }
            }
            Spacer().frame(height: 20)
            if info == nil || isPlaceHolder {
                HStack(spacing: 8) {
                    Rectangle()
                        .frame(width: 60, height: 60, alignment: .center)
                        .cornerRadius(8)
                        .redacted(reason: .placeholder)
                        .opacity(0.233)
                    Rectangle()
                        .frame(width: 60, height: 60, alignment: .center)
                        .cornerRadius(8)
                        .redacted(reason: .placeholder)
                        .opacity(0.233)
                    Rectangle()
                        .frame(width: 60, height: 60, alignment: .center)
                        .cornerRadius(8)
                        .redacted(reason: .placeholder)
                        .opacity(0.233)
                    Spacer()
                }
            } else {
                HStack(spacing: 16) {
                    Element(title: "CPU", titleIcon: "cpu", value: $cpu)
                    Element(title: "RAM", titleIcon: "memorychip", value: $ram)
                    Element(title: "DISK", titleIcon: "square.3.stack.3d.bottom.fill", value: $disk)
                    Spacer()
                }
            }
        }
        .padding(padding)
        .background(
            Rectangle()
                .foregroundColor(.lightGray)
        )
        .contextMenu(ContextMenu(menuItems: {
            Section {
                Button(action: {
                    if let server = descriptor {
                        PTServerManager.shared.updateServerSupervisionInfoNow(withKey: server)
                    }
                }, label: {
                    Text(NSLocalizedString("REFRESH_NOW", comment: "Refresh Now"))
                })
                Button(action: {
                    if let server = descriptor {
                        PTServerManager.shared.removeServerFromSupervisedList(withKey: server)
                    }
                }, label: {
                    Text(NSLocalizedString("HIDE", comment: "Hide"))
                })
            }
        }))
        .cornerRadius(12)
        .onAppear {
            let link = PTNotificationCenter.NotificationLink(name: .ServerManager_ServerStatusUpdated,
                                                             throttle: nil) { pass in
                guard let sd = pass.representedObject as? String,
                      sd == descriptor
                else {
                    return
                }
                DispatchQueue.main.async {
                    self.updateInfomation()
                }
            }
            PTNotificationCenter.shared.registeringNotification(withLink: link)
            notificationLinkID = link.uuid
            updateInfomation()
        }
        .onDisappear {
            PTNotificationCenter.shared.removeNotificatino(withKey: notificationLinkID,
                                                           underName: .ServerManager_ServerStatusUpdated)
        }
    }

    func updateInfomation() {
        if let sd = descriptor {
            info = PTServerManager.ServerInfoHumanReadable(serverDescriptor: sd)
            cpu = info?.cpuThreshold ?? 0
            ram = info?.ramThreshold ?? 0
            disk = info?.diskThreshold ?? 0

            if cpu > 1 { cpu = 1 }
            if cpu < 0 { cpu = 0 }
            if ram > 1 { ram = 1 }
            if ram < 0 { ram = 0 }
            if disk > 1 { disk = 1 }
            if disk < 0 { disk = 0 }
        }
    }

    func updateTimeDescription() {
        let refDate = Date(timeIntervalSince1970: TimeInterval(info!.updatedAt))
        let sec = Int(Date().timeIntervalSince(refDate))
        validDescription = String(format: NSLocalizedString("STATUS_BLOCK_SEC_AGO", comment: "%ds ago"), sec)
    }

    struct Element: View {
        let title: String
        let titleIcon: String
        @Binding var value: Double

        var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 0) {
                    HStack(spacing: 2) {
                        Image(systemName: titleIcon)
                            .scaleEffect(0.8)
                        Text(title)
                            .font(.system(size: 12))
                            .opacity(0.75)
                    }
                }
                Spacer()
                    .frame(height: 8)
                HStack(alignment: .bottom, spacing: 4) {
                    Spacer()
                        .frame(width: 1)
                    Text(String(Int(value * 100)))
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                    Text("%")
                        .font(.system(size: 12, weight: .regular, design: .default))
                        .padding(EdgeInsets(top: 0, leading: 0, bottom: 4, trailing: 0))
                }
            }
        }
    }
}
