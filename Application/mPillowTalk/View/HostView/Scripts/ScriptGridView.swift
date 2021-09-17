//
//  ScriptGridView.swift
//  mPillowTalk
//
//  Created by Innei on 2021/5/5.
//

import PTFoundation
import SwiftUI

struct ScriptCollectionView: View {
    let insideServer: PTServerManager.ServerDescriptor?
    init(withInServer server: PTServerManager.ServerDescriptor? = nil) {
        insideServer = server
    }

    @StateObject var windowObserver = WindowObserver()
    @ObservedObject var agent = Agent.shared

    // CodeClipGroup 被砍掉了
    @State var dataSource: [IterationElement] = []
    @State var builtinScript: [CodeClip] = PTCodeClipManager.shared.obtainBuiltinCodeClips()

    struct IterationElement: Identifiable {
        var id: String {
            section + String(describing: clips)
        }

        let section: String
        let clips: [CodeClip]
        init(section: String, clips: [String: CodeClip]) {
            self.section = section
            self.clips = clips.map(\.value).sorted { $0.name < $1.name }
        }
    }

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect() // TODO:

    var body: some View {
        VStack {
            Group {
                if dataSource.count < 1 {
                    NavigationLink(destination: ScriptCreateView()) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .foregroundColor(.lightGray)
                            HStack {
                                Image(systemName: "plus.viewfinder")
                                Text(NSLocalizedString("ADD_CLIP", comment: "Add Clip"))
                            }
                        }
                    }
                    .frame(height: 100)
                } else {
                    ForEach(dataSource) { element in
                        Section(header:
                            VStack {
                                HStack {
                                    Group {
                                        if element.section == PTCodeClipManager.defaultSectionName {
                                            Text(NSLocalizedString("DEFAULT_SECTION_NAME", comment: "Default"))
                                        } else {
                                            Text(element.section)
                                        }
                                    }
                                    .font(.headline)
                                    Spacer()
                                    NavigationLink(destination: ScriptCreateView(initData: .init(name: "", section: element.section, icon: "", code: ""))) {
                                        Image(systemName: "plus.circle")
                                    }
                                }
                                Divider()
                            }
                        ) {
                            VStack {
                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 8)], spacing: 8) {
                                    ForEach(element.clips, id: \.self) { clip in
                                        if insideServer != nil {
                                            ScriptGridItemView(clip: clip, useDoubleTap: false)
                                                .onTapGesture {
                                                    execute(withClip: clip)
                                                }
                                        } else {
                                            NavigationLink(
                                                destination: ScriptPreExecView(clip: clip),
                                                label: {
                                                    ScriptGridItemView(clip: clip)
                                                }
                                            )
                                        }
                                    }
                                }
                                Divider()
                                    .opacity(0)
                            }
                        }
                    }
                }
            }

            Section(header:
                VStack {
                    HStack(alignment: .bottom) {
                        Text(NSLocalizedString(
                            "SHORTCUT_EMBEDDED_ELEMENTS", comment: "内建捷径元素"
                        ))
                            .font(.headline)
                        Spacer()
                    }
                    Divider()
                }
            ) {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 8)], spacing: 8) {
                    ForEach(Array(builtinScript), id: \.self) { clip in
                        if insideServer != nil {
                            ScriptGridItemView(clip: clip, canModify: false, useDoubleTap: false)
                                .onTapGesture {
                                    execute(withClip: clip)
                                }
                        } else {
                            NavigationLink(
                                destination: ScriptPreExecView(clip: clip),
                                label: {
                                    ScriptGridItemView(clip: clip, canModify: false)
                                }
                            )
                        }
                    }
                }
            }

            Spacer()
        }
        .onReceive(agent.$clipDataTokenPublisher) { _ in
            updateDataSource()
        }
        .onAppear {
            updateDataSource()
        }
        .background(
            HostingWindowFinder { [weak windowObserver] window in
                windowObserver?.window = window
            }
        )
    }

    func updateDataSource() {
        var clips = PTCodeClipManager
            .shared
            .obtainCodeClipList()
        if NSLocalizedString("DEFAULT_SECTION_NAME", comment: "Default").count > 0,
           let defaults = clips[PTCodeClipManager.defaultSectionName],
           defaults.count > 0
        {
            clips.removeValue(forKey: PTCodeClipManager.defaultSectionName)
            clips[NSLocalizedString("DEFAULT_SECTION_NAME", comment: "Default")] = defaults
        }
        dataSource = clips
            .map { key, value in
                IterationElement(section: key, clips: value)
            }
            .sorted { $0.section < $1.section }
    }

    func execute(withClip clip: CodeClip) {
        let view = ScriptExecution(clip: clip, serverDescriptor: insideServer)
        let controller = UIHostingController(rootView: view)
        (controller as UIViewController).modalPresentationStyle = .formSheet
        (controller as UIViewController).preferredContentSize = CGSize(width: 800, height: 600)
        windowObserver.window?.topMostViewController?.present(controller, animated: true, completion: {})
    }
}

struct ScriptGridView_Previews: PreviewProvider {
    static var previews: some View {
        ScriptCollectionView().previewLayout(.fixed(width: 500, height: 800))
    }
}
