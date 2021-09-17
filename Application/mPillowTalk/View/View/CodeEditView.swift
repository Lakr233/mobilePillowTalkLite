//
//  CodeEditView.swift
//  mPillowTalk
//
//  Created by Lakr Aream on 5/14/21.
//

import CodeViewer
import PTFoundation
import SwiftUI

struct CodeEditView: View {
    var callback: (String) -> Void = { _ in }

    @State var textContext: String
    @StateObject var windowObserver = WindowObserver()

    @Environment(\.presentationMode) var presentationMode

    init(code: String, callback: @escaping (String) -> Void) {
        _textContext = State(initialValue: code)
        self.callback = callback
    }

    var body: some View {
        VStack {
            GeometryReader { reader in
                CodeViewer(
                    content: $textContext,
                    mode: .sh,
                    darkTheme: .solarized_dark,
                    lightTheme: .github,
                    isReadOnly: false,
                    fontSize: reader.size.width > 600 ? 16 : 32
                )
                .background(Color.lightGray)
            }
        }
        .navigationBarItems(leading: Group {
            Button(action: {
                dismiss()
            }, label: {
                Text(NSLocalizedString("CANCEL", comment: "Cancel"))
                    .foregroundColor(.red)
            })
        },
        trailing: Group {
            Button(action: {
                dismiss()
                callback(textContext)
            }, label: {
                Text(NSLocalizedString("SAVE", comment: "Save"))
            })
        })
        .background(
            HostingWindowFinder { [weak windowObserver] window in
                windowObserver?.window = window
            }
        )
        .navigationBarBackButtonHidden(true)
        .navigationTitle(NSLocalizedString("EDIT_SCRIPT", comment: "Edit Script"))
    }

    func dismiss() {
        DispatchQueue.main.async {
            windowObserver.window?.topMostViewController?.dismiss(animated: true, completion: nil)
            presentationMode.wrappedValue.dismiss()
        }
    }
}

struct ScriptEditView_Previews: PreviewProvider {
    static var previews: some View {
        CodeEditView(code: "", callback: { _ in })
    }
}
