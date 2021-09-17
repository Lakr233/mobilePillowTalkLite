//
//  ScriptGridItemView.swift
//  mPillowTalk
//
//  Created by Lakr Aream on 5/14/21.
//

import PTFoundation
import SwiftUI

struct ScriptGridItemView: View {
    let clip: CodeClip
    let canModify: Bool
    let useDoubleTap: Bool

    init(clip: CodeClip, canModify: Bool = true, useDoubleTap: Bool = false) {
        self.clip = clip
        self.canModify = canModify
        self.useDoubleTap = useDoubleTap
    }

    @State var presentEditMeta: Bool = false
    @State var presentEditScript: Bool = false
    @State var scale: CGFloat = 1

    @StateObject var windowObserver = WindowObserver()

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(uiImage: obtainUIImageFromIconDescription().withRenderingMode(.alwaysTemplate))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 22, height: 22)
                    .foregroundColor(.overridableAccentColor)
                Spacer()
                Text(
                    NSLocalizedString("HODE_FOR_MORE", comment: "Hold for more").uppercased()
                )
                .foregroundColor(.systemGray)
                .font(.system(size: 7, weight: .semibold, design: .default))
            }

            Spacer()
                .frame(height: 12)

            VStack(alignment: .leading) {
                Text(clip.name)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .lineLimit(1)
            }

            Spacer()
                .frame(height: 4)
                .background(
                    VStack {
                        NavigationLink(destination: ScriptCreateView(initData: .init(name: clip.name,
                                                                                     section: clip.section,
                                                                                     icon: clip.icon ?? "",
                                                                                     code: clip.code)),
                        isActive: $presentEditMeta) {
                            Divider().frame(width: 0, height: 0)
                        }
                        NavigationLink(destination: CodeEditView(code: clip.code, callback: { code in
                            ScriptCreateView.modifyScript(withInClip: clip, withCode: code)
                        }),
                        isActive: $presentEditScript) {
                                Divider().frame(width: 0, height: 0)
                        }
                    })

            Text(useDoubleTap
                ? NSLocalizedString("DOUBLE_TAP_TO_EXECUTE", comment: "Tap twice to execute").uppercased()
                : NSLocalizedString("TAP_CLICK_TO_EXECUTE", comment: "Tap to execute").uppercased()
            )
            .foregroundColor(.systemGray)
            .font(.system(size: 7, weight: .semibold, design: .default))
        }
        .padding(10)
        .frame(height: 80)
        .background(
            Rectangle()
                .foregroundColor(.lightGray)
        )
        .foregroundColor(.primary)
        .contextMenu(ContextMenu(menuItems: {
            Section {
                Button(action: {
                    if clip.code.count > 0 {
                        UIPasteboard.general.string = clip.code
                    }
                }, label: {
                    Text(NSLocalizedString("COPY_SCRIPT", comment: "Copy Script"))
                    Image(systemName: "square.and.arrow.up.fill")
                })
            }
            if canModify {
                Section {
                    Button(action: {
                        presentEditMeta = true
                    }, label: {
                        Text(NSLocalizedString("EDIT_META", comment: "Edit Metadata"))
                        Image(systemName: "square.and.pencil")
                    })
                    Button(action: {
                        presentEditScript = true
                    }, label: {
                        Text(NSLocalizedString("EDIT_SCRIPT", comment: "Edit Script"))
                        Image(systemName: "square.and.pencil")
                    })
                }
                Section {
                    Button(action: {
                        let alert = UIAlertController(title: NSLocalizedString("WARNING", comment: "Warning"),
                                                      message:
                                                      String(format: NSLocalizedString("ARE_YOU_SURE_DELETE_SCRIPT", comment: "Are you sure you want to delete %@?"), clip.name),
                                                      preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: NSLocalizedString("CANCEL", comment: "Cancel"),
                                                      style: .cancel,
                                                      handler: nil))
                        alert.addAction(UIAlertAction(title: NSLocalizedString("CONTINUE", comment: "Continue"),
                                                      style: .destructive,
                                                      handler: { _ in
                                                          PTCodeClipManager.shared.deleteCodeClipWith(name: clip.name, inSection: clip.section)
                                                      }))
                        windowObserver.window?.topMostViewController?.present(alert, animated: true, completion: nil)
                    }, label: {
                        Text(NSLocalizedString("DELETE", comment: "Delete"))
                        Image(systemName: "trash.fill")
                    })
                }
            }
        }))
        .cornerRadius(6)
        .background(
            HostingWindowFinder { [weak windowObserver] window in
                windowObserver?.window = window
            }
        )
        .scaleEffect(scale)
    }

    func obtainUIImageFromIconDescription() -> UIImage {
        if let iconDescriptor = clip.icon {
            let base64Prefix = "data:image/png;base64,"
            if iconDescriptor.hasPrefix(base64Prefix),
               let data = Data(base64Encoded: String(iconDescriptor.dropFirst(base64Prefix.count)).trimmingCharacters(in: CharacterSet.whitespaces)),
               let img = UIImage(data: data)?.withRenderingMode(.alwaysTemplate)
            {
                return img
            } else if let img = UIImage(systemName: iconDescriptor) {
                return img
            } else if let img = UIImage(named: iconDescriptor)?.withRenderingMode(.alwaysTemplate) {
                return img
            } else {
                return UIImage(systemName: "square.stack.3d.down.forward.fill") ?? UIImage()
            }
        } else {
            return UIImage(systemName: "square.stack.3d.down.forward.fill") ?? UIImage()
        }
    }
}
