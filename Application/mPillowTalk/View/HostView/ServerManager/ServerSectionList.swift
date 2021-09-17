//
//  ServerSectionList.swift
//  mPillowTalk
//
//  Created by Lakr Aream on 2021/5/30.
//

import PTFoundation
import SwiftUI

struct ServerSectionList: View {
    let sectionName: String

    @ObservedObject var agent = Agent.shared

    @State var servers: [PTServerManager.Server] = []

    var body: some View {
        VStack {
            HStack {
                if sectionName == PTServerManager.Server.defaultSectionName {
                    Text(NSLocalizedString("DEFAULT_SECTION_NAME", comment: "Default"))
                } else {
                    Text(sectionName)
                }
                Spacer()
            }
            .font(.system(size: 18, weight: .semibold, design: .default))
            Divider()
            ForEach(servers, id: \.self) { server in
                ServerListItem(server: server)
            }
            .onAppear {
                updateServers()
            }
            .onReceive([agent.serverDescriptorsSorted].publisher.first()) { _ in
                updateServers()
            }
            SectionAddServerButton(sectionName: sectionName)
            Divider().opacity(0)
        }
    }

    func updateServers() {
        if sectionName == PTServerManager.Server.defaultSectionName {
            let a = PTServerManager.shared.obtainServersWithinSection(name: sectionName)
            let b = PTServerManager.shared.obtainServersWithinSection(name: PTServerManager.Server.defaultSectionName)
            var all: [String: PTServerManager.Server] = [:]
            for o in a { all[o.uuid] = o }
            for o in b { all[o.uuid] = o }
            servers = all
                .values
                .sorted(by: { a, b in
                    a.obtainPossibleName() < b.obtainPossibleName()
                })
        } else {
            servers = PTServerManager.shared.obtainServersWithinSection(name: sectionName)
                .sorted(by: { a, b in
                    a.obtainPossibleName() < b.obtainPossibleName()
                })
        }
    }
}
