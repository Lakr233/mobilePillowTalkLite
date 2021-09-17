//
//  PersistTerminalInstanceView.swift
//  mPillowTalk
//
//  Created by Lakr Aream on 5/31/21.
//

import SwiftUI

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.formatterBehavior = .behavior10_4
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

struct PersistTerminalInstanceView: View {
    let instanceRef: PersistTerminalInstance

    var body: some View {
        NavigationLink(destination: PersistTerminalView(instance: instanceRef)) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "terminal.fill")
                    Text(instanceRef.terminalTitle)
                    Spacer()
                    Button {
                        withAnimation(.interactiveSpring()) {
                            instanceRef.terminate()
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                    }
                }
                .font(.system(size: 18, weight: .semibold, design: .default))
                HStack {
                    Text(NSLocalizedString("CREATE_AT", comment: "Create At"))
                    Text(dateFormatter.string(from: instanceRef.openDate))
                    Spacer()
                }
                .font(.system(size: 10, weight: .regular, design: .default))
                Divider()
                HStack {
                    Text(instanceRef.id.uuidString)
                    Spacer()
                }
                .font(.system(size: 8, weight: .regular, design: .monospaced))
                .opacity(0.2)
            }
            .padding()
            .background(Color.lightGray)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PersistTerminalInstanceView_Previews: PreviewProvider {
    static func getPreviewInstanceRef() -> PersistTerminalInstance {
        let ref = PersistTerminalInstance()
        ref.terminalTitle = "测试 ABC"
        return ref
    }

    static var previews: some View {
        PersistTerminalInstanceView(instanceRef: PersistTerminalInstanceView_Previews.getPreviewInstanceRef())
    }
}
