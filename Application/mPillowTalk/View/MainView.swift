//
//  MainView.swift
//  mPillowTalk
//
//  Created by Lakr Aream on 4/17/21.
//

import PTFoundation
import SwiftUI

private var bootAuthed: Bool = false
private let authThrottle: PTThrottle = .init(minimumDelay: 2)

struct MainView: View {
    #if os(iOS)
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif

    @ObservedObject var agent = Agent.shared
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        Group {
            if agent.authorizationStatus == .authorized {
                Group {
                    if horizontalSizeClass == .compact || !isPad {
                        TabBarView()
                    } else {
                        SideBarView()
                    }
                }
            } else {
                ProgressView()
                    .onAppear {
                        if !bootAuthed {
                            bootAuthed = true
                            agent.startUserAuthentication()
                        }
                    }
            }
        }
        .onReceive(timer, perform: { _ in
            AppearanceStore.shared.updateColorScheme()
            if agent.authorizationStatus == .unauthorized, agent.applicationActived {
                authThrottle.throttle {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        agent.startUserAuthentication()
                    }
                }
            }
        })
    }
}
