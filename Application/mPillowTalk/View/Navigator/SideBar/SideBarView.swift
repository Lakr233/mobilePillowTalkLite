//
//  SideBar.swift
//  mPillowTalk
//
//  Created by Lakr Aream on 4/18/21.
//

import PTFoundation
import SwiftUI
#if DEBUG
    import FLEX
#endif

enum NavigationTag: Int, Equatable, Identifiable {
    var id: NavigationTag { self }
    case Dashboard
    case ServerManager
    case ServerDetailed
    case EmptyServerå
    case CodeClip
    case RemoteLogin
    case Setting
    case Help
}

struct SideBarView: View {
    let LSSideBarTitle = NSLocalizedString("APP_NAME", comment: "Pillow Talk")
    let LSSideBarElementDashboard = NSLocalizedString("SIDEBAR_DASHBOARD", comment: "Dashboard")

    let LSSideBarElementServer = NSLocalizedString("SIDEBAR_SERVER", comment: "Server")
    let LSSideBarElementServerManager = NSLocalizedString("SIDEBAR_SERVER_MANAGER", comment: "Management")
    let LSSideBarElementRegisterServer = NSLocalizedString("SIDEBAR_REG_SERVER", comment: "Register Server")

    let LSSideBarElementUtils = NSLocalizedString("SIDEBAR_UTILS", comment: "Utils")
    let LSSideBarElementCodeClip = NSLocalizedString("SIDEBAR_CODE_CLIP", comment: "Code Clip")
    let LSSideBarElementRemoteLogin = NSLocalizedString("SIDEBAR_REMOTE_LOGIN", comment: "Remote Login")

    let LSSideBarElementApplication = NSLocalizedString("SIDEBAR_APPLICATION", comment: "Application")
    let LSSideBarElementSetting = NSLocalizedString("SIDEBAR_SETTING", comment: "Setting")
    let LSSideBarElementHelp = NSLocalizedString("SIDEBAR_HELP", comment: "Help")

    let LSSideBarCopyRight = NSLocalizedString("COPY_RIGHT_FULL", comment: "Copyright © 2020 Pillow Talk Team. All rights reserved.")

    let fntSideBarSectionHead = Font.system(size: 18, weight: .semibold)

    @State var whichPane: NavigationTag? = nil

    @ObservedObject var agent = Agent.shared

    @StateObject var windowObserver = WindowObserver()

    var body: some View {
        Group {
            sidebar
        }
    }

    var sidebar: some View {
        NavigationView {
            List {
                Group {
                    NavigationLink(destination: DashboardView(),
                                   tag: NavigationTag.Dashboard,
                                   selection: $whichPane) {
                        Label(LSSideBarElementDashboard, systemImage: "square.stack.3d.down.right.fill")
                    }
                }

                Group {
                    Text(LSSideBarElementServer)
                        .font(fntSideBarSectionHead)
                    NavigationLink(destination: ServerManagerView(),
                                   tag: NavigationTag.ServerDetailed,
                                   selection: $whichPane) {
                        Label(LSSideBarElementServerManager, systemImage: "wrench.and.screwdriver")
                    }
                    ForEach(agent.serverDescriptorsSorted, id: \.self) { item in
                        NavigationLink(
                            destination: DetailedServerBoard(serverDescriptor: item),
                            label: {
                                let s = PTServerManager.shared.obtainServer(withKey: item)
                                Label(s?.obtainPossibleName() ?? "?", systemImage: "server.rack")
                            }
                        )
                    }.onDelete { indexSet in
                        let list = agent.serverDescriptorsSorted
                        guard let index = indexSet.first else { return }
                        if index < 0 || index >= list.count { return }
                        PTServerManager.shared.removeServerFromRegisteredList(withKey: list[index])
                    }
                    Button {
                        let controller = UIHostingController(rootView: AddServerView())
                        (controller as UIViewController).view.backgroundColor = UIColor(named: "WHITE_AND_BLACK_SHEET")
                        (controller as UIViewController).modalPresentationStyle = .formSheet
                        windowObserver.window?
                            .topMostViewController?
                            .present(controller,
                                     animated: true,
                                     completion: nil)
                    } label: {
                        Label(LSSideBarElementRegisterServer, systemImage: "plus.square")
                    }
                }

                Group {
                    Text(LSSideBarElementUtils)
                        .font(fntSideBarSectionHead)
                    NavigationLink(destination: CodeClipView(),
                                   tag: NavigationTag.CodeClip,
                                   selection: $whichPane) {
                        Label(LSSideBarElementCodeClip, systemImage: "wind")
                    }
                    NavigationLink(destination: RemoteLoginView(),
                                   tag: NavigationTag.RemoteLogin,
                                   selection: $whichPane) {
                        Label(LSSideBarElementRemoteLogin, systemImage: "rectangle.stack.person.crop")
                    }
                }

                Group {
                    Text(LSSideBarElementApplication)
                        .font(fntSideBarSectionHead)
                    NavigationLink(destination: SettingView(),
                                   tag: NavigationTag.Setting,
                                   selection: $whichPane) {
                        Label(LSSideBarElementSetting, systemImage: "gear")
                    }
                    NavigationLink(destination: DocumentView(),
                                   tag: NavigationTag.Help,
                                   selection: $whichPane) {
                        Label(LSSideBarElementHelp, systemImage: "questionmark.circle")
                    }
                }

                #if DEBUG
                    Group {
                        Text("Developer Area")
                            .font(fntSideBarSectionHead)
                        Button {
                            FLEXManager.shared.showExplorer()
                        } label: {
                            Label("Open FLEX", systemImage: "ladybug")
                        }
                        Button {
                            askAndSetBootFailed(window: windowObserver.window)
                        } label: {
                            Label("Set Boot Failed", systemImage: "ladybug")
                        }
                    }

                    Group {
                        Text(LSSideBarCopyRight)
                            .font(.system(size: 10))
                            .opacity(0.233)
                    }
                #endif
            }
            .listStyle(SidebarListStyle())
            .navigationTitle(LSSideBarTitle)
            .background(
                HostingWindowFinder { [weak windowObserver] window in
                    windowObserver?.window = window
                }
            )
            DashboardView()
        }
    }
}

struct SideBarView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SideBarView()
                .previewLayout(.fixed(width: 1024, height: 768))
        }
    }
}

#if DEBUG

    func askAndSetBootFailed(window: UIWindow?) {
        let alert = UIAlertController(title: "⚠️",
                                      message: "Set lastBootSucceed to false?",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: { _ in
            mPillowTalkApp.lastBootSucceed = false
            let alert = UIAlertController(title: "⚠️",
                                          message: "Exit?",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: { _ in
                UIControl().sendAction(#selector(NSXPCConnection.suspend),
                                       to: UIApplication.shared, for: nil)
                DispatchQueue.global().async {
                    sleep(1)
                    exit(0)
                }
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            let vc = window?.topMostViewController
            vc?.present(alert, animated: true, completion: nil)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        let vc = window?.topMostViewController
        vc?.present(alert, animated: true, completion: nil)
    }

#endif
