//
//  ScriptCreateView.swift
//  mPillowTalk
//
//  Created by Lakr Aream on 5/14/21.
//

import PTFoundation
import SwiftUI

struct ScriptCreateView: View {
    let initData: PassedData?
    struct PassedData {
        let name: String
        let section: String
        let icon: String
        let code: String
    }

    init(initData: PassedData? = nil) {
        self.initData = initData
    }

    @StateObject var windowObserver = WindowObserver()
    @Environment(\.presentationMode) var presentationMode

    @State var name: String = ""
    @State var section: String = NSLocalizedString("DEFAULT_SECTION_NAME", comment: "Default")
    @State var icon: String = "FLUENT_WAND"
    @State var code: String = "#! /bin/bash\n"

    @State var everInit: Bool = false

    @State var alertShouldPresent: Bool = false

    var body: some View {
        ScrollView {
            VStack {
                NavigationLink(
                    destination: CodeEditView(code: code, callback: { str in
                        code = str
                    }),
                    label: {
                        HStack {
                            Image(systemName: "chevron.left.slash.chevron.right")
                            Text(NSLocalizedString("EDIT_SCRIPT", comment: "Edit Script"))
                            Spacer()
                        }
                        .font(.system(size: 14, weight: .semibold, design: .default))
                        .padding()
                        .background(
                            Color
                                .lightGray
                                .frame(height: 40)
                                .cornerRadius(8)
                        )
                    }
                )
                InputElementView(title: NSLocalizedString("NAME", comment: "Name"),
                                 placeholder: NSLocalizedString("NAME", comment: "Name"),
                                 required: true,
                                 validator: {
                                     name.count > 0
                                 },
                                 type: nil,
                                 useInlineTextField: true,
                                 binder: $name)
                InputElementView(title: NSLocalizedString("SECTION", comment: "Section"),
                                 placeholder: NSLocalizedString("DEFAULT_SECTION_NAME", comment: "Default"),
                                 required: true,
                                 validator: {
                                     true
                                 },
                                 type: nil,
                                 useInlineTextField: true,
                                 binder: $section)
                HStack {
                    Text(NSLocalizedString("ICON", comment: "Icon"))
                        .opacity(0.5)
                        .font(.system(size: 12, weight: .semibold, design: .default))
                    Spacer()
                }
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 50, maximum: 80))], content: {
                    ForEach(FluentIconName, id: \.self) { name in
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .foregroundColor(name == icon ? .blue : .lightGray)
                                .opacity(0.05)
                                .shadow(radius: name == icon ? 6 : 0)
                            Image(name)
                                .renderingMode(.template)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 32, height: 32)
                                .foregroundColor(name == icon ? .blue : .init("BLACK_AND_WHITE"))
                                .opacity(name == icon ? 1 : 0.6)
                        }
                        .animation(.easeIn)
                        .onTapGesture {
                            icon = name
                        }
                        .frame(width: 50, height: 50)
                    }
                })
                    .padding()
                    .background(Color.lightGray)
                    .cornerRadius(12)
                Divider()
                Button(action: {
                    UIApplication.shared.open(URL(string: "https://github.com/microsoft/fluentui-system-icons")!, options: [:], completionHandler: nil)
                }, label: {
                    VStack(spacing: 4) {
                        Text(NSLocalizedString("FLUENT_ICON_DESCRIPTION", comment: "Fluent UI System Icon is designed by Microsoft licensed under MIT License"))
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                        Text("https://github.com/microsoft/fluentui-system-icons")
                            .font(.system(size: 8, weight: .regular, design: .monospaced))
                    }
                })
                Divider().opacity(0)
            }
            .padding()
            .background(
                HostingWindowFinder { [weak windowObserver] window in
                    windowObserver?.window = window
                }
            )
            .alert(isPresented: $alertShouldPresent, content: {
                Alert(title: Text(NSLocalizedString("SCRIPT_DUPLICATED", comment: "Script Duplicated")),
                      message: Text(NSLocalizedString("OVERRIDE_IF_CONTINUE", comment: "Will override if continue, this operation can't be undone.")),
                      primaryButton: .cancel(Text(NSLocalizedString("CANCEL", comment: "Cancel")), action: {}),
                      secondaryButton: .destructive(Text(NSLocalizedString("CONTINUE", comment: "Continue")), action: {
                          let clip = CodeClip(name: name,
                                              icon: icon,
                                              code: code,
                                              section: section,
                                              timeout: -1, // TODO:
                                              executor: .bash,
                                              target: .remote)
                          PTCodeClipManager.shared.addCodeClip(code: clip)
                          dismiss()
                      }))
            })
            .onAppear {
                if everInit { return }
                everInit = true
                if let initData = initData {
                    if initData.name.count > 0 {
                        name = initData.name
                    }
                    if initData.section == PTCodeClipManager.defaultSectionName {
                        section = NSLocalizedString("DEFAULT_SECTION_NAME", comment: "Default")
                    } else {
                        section = initData.section
                    }
                    if initData.icon.count > 0 {
                        icon = initData.icon
                    }
                    if initData.code.count > 0 {
                        code = initData.code
                    }
                }
            }
        }
        .navigationBarTitle(
            initData == nil
                ? NSLocalizedString("CREATE_SCRIPT", comment: "Create Script")
                : NSLocalizedString("EDIT", comment: "Edit"),
            displayMode: .inline // bug fix
        )
        .navigationBarItems(trailing: HStack {
            Button(initData == nil ? NSLocalizedString("CREATE", comment: "Create") : NSLocalizedString("SAVE", comment: "Save")) {
                if initData == nil,
                   PTCodeClipManager.shared.retrieveCodeClipWith(name: name, inSection: section) != nil
                {
                    alertShouldPresent = true
                    return
                }
                if let initData = initData {
                    PTCodeClipManager
                        .shared
                        .deleteCodeClipWith(name: initData.name, inSection: initData.section)
                }
                let clip = CodeClip(name: name,
                                    icon: icon,
                                    code: code,
                                    section: section,
                                    timeout: -1, // TODO:
                                    executor: .bash,
                                    target: .remote)
                PTCodeClipManager.shared.addCodeClip(code: clip)
                dismiss()
            }
            .disabled(!(name.count > 0 && section.count > 0))
        })
    }

    func dismiss() {
        DispatchQueue.main.async {
            windowObserver.window?.topMostViewController?.dismiss(animated: true, completion: nil)
            presentationMode.wrappedValue.dismiss()
        }
    }

    static func modifyScript(withInClip clip: CodeClip, withCode code: String) {
        PTLog.shared.join("ScriptEditor",
                          "code of clip \(clip.name) inside \(clip.section) was modified",
                          level: .info)
        PTCodeClipManager.shared.deleteCodeClipWith(name: clip.name, inSection: clip.section)
        let clip = CodeClip(name: clip.name,
                            icon: clip.icon,
                            code: code,
                            section: clip.section,
                            timeout: clip.timeout,
                            executor: clip.executor,
                            target: clip.target)
        PTCodeClipManager.shared.addCodeClip(code: clip)
    }
}

struct ScriptCreateView_Previews: PreviewProvider {
    static var previews: some View {
        ScriptCreateView()
            .previewLayout(.fixed(width: 500, height: 1500))
    }
}

private
let FluentIconName =
    [
        "FLUENT_WAND",

        "FLUENT_ADD_SUBTRACT_CIRCLE", "FLUENT_ARCHIVE", "FLUENT_ARROW_DOWNLOAD", "FLUENT_ARROW_REDO", "FLUENT_ARROW_REPLY", "FLUENT_ARROW_REPLY_ALL", "FLUENT_ARROW_UNDO", "FLUENT_BACKPACK", "FLUENT_BACKPACK_ADD", "FLUENT_BRIEFCASE", "FLUENT_CAMERA_ADD", "FLUENT_CHANNEL", "FLUENT_CHANNEL_ADD", "FLUENT_CHANNEL_ALERT", "FLUENT_CHANNEL_ARROW_LEFT", "FLUENT_CHANNEL_DISMISS", "FLUENT_CHANNEL_SHARE", "FLUENT_CHART_PERSON", "FLUENT_CHAT", "FLUENT_CHECKMARK", "FLUENT_CHECKMARK_CIRCLE", "FLUENT_CHEVRON_DOWN", "FLUENT_CHEVRON_LEFT", "FLUENT_CHEVRON_RIGHT", "FLUENT_CHEVRON_UP", "FLUENT_CLOCK", "FLUENT_CLOSED_CAPTION", "FLUENT_CLOUD", "FLUENT_CLOUD_BACKUP", "FLUENT_CLOUD_DOWNLOAD", "FLUENT_CLOUD_OFF", "FLUENT_CLOUD_SYNC_COMPLETE", "FLUENT_COMMENT", "FLUENT_COMMENT_ADD", "FLUENT_COMMENT_ARROW_LEFT", "FLUENT_COMMENT_ARROW_RIGHT", "FLUENT_COMMENT_CHECKMARK", "FLUENT_COMMENT_OFF", "FLUENT_CONFERENCE_ROOM", "FLUENT_CONTACT_CARD_GROUP", "FLUENT_CURSOR_HOVER", "FLUENT_CURSOR_HOVER_OFF", "FLUENT_DELETE", "FLUENT_DISMISS_CIRCLE", "FLUENT_DOCK_PANEL_LEFT", "FLUENT_DOCK_PANEL_RIGHT", "FLUENT_DOCTOR", "FLUENT_DOCUMENT", "FLUENT_DOCUMENT_ADD", "FLUENT_DOCUMENT_ARROW_LEFT", "FLUENT_DOCUMENT_COPY", "FLUENT_DROP", "FLUENT_FINGERPRINT", "FLUENT_FLAG", "FLUENT_FLAG_OFF", "FLUENT_FLAG_PRIDE", "FLUENT_FLUENT", "FLUENT_FOLDER", "FLUENT_FOLDER_ADD", "FLUENT_FOLDER_ARROW_RIGHT", "FLUENT_FOLDER_ARROW_UP", "FLUENT_FOLDER_LINK", "FLUENT_FOLDER_PROHIBITED", "FLUENT_FORM_NEW", "FLUENT_GLASSES", "FLUENT_GLASSES_OFF", "FLUENT_HEADSET", "FLUENT_HOME", "FLUENT_IMAGE", "FLUENT_LINK", "FLUENT_LOCATION", "FLUENT_LOCATION_OFF", "FLUENT_LOCK_SHIELD", "FLUENT_MAIL", "FLUENT_MAIL_READ", "FLUENT_MAIL_UNREAD", "FLUENT_MIC_OFF", "FLUENT_MIC_ON", "FLUENT_MIC_PROHIBITED", "FLUENT_OPEN", "FLUENT_OPEN_FOLDER", "FLUENT_OPEN_OFF", "FLUENT_PAUSE", "FLUENT_PERSON", "FLUENT_PERSON_MAIL", "FLUENT_PLAY", "FLUENT_PRINT", "FLUENT_PROHIBITED", "FLUENT_PUZZLE_CUBE", "FLUENT_QUESTION", "FLUENT_QUESTION_CIRCLE", "FLUENT_QUIZ_NEW", "FLUENT_SHARE_IOS", "FLUENT_SHARE_SCREEN_STOP", "FLUENT_SKIP_BACKWARD_10", "FLUENT_SKIP_FORWARD_10", "FLUENT_SKIP_FORWARD_30", "FLUENT_SLIDE_TEXT", "FLUENT_SPEAKER_0", "FLUENT_SPEAKER_1", "FLUENT_SPEAKER_2", "FLUENT_SPEAKER_MUTE", "FLUENT_SPEAKER_OFF", "FLUENT_SPLIT_HORIZONTAL", "FLUENT_SPLIT_VERTICAL", "FLUENT_SUBTRACT", "FLUENT_TABLE", "FLUENT_TABLE_SIMPLE", "FLUENT_TENT", "FLUENT_TOGGLE_LEFT", "FLUENT_TOGGLE_RIGHT", "FLUENT_TV", "FLUENT_TV_USB", "FLUENT_VEHICLE_CAR", "FLUENT_VIDEO_PERSON",
    ]
