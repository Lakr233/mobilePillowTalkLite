//
//  AppLogView.swift
//  mPillowTalk
//
//  Created by Lakr Aream on 4/19/21.
//

import PTFoundation
import SwiftUI

struct AppLogView: View {
    let showCurrentLog: Bool
    let overrideLogFile: String?
    let overrideLogContent: String?

    init(showCurrentLog: Bool = true) {
        self.showCurrentLog = showCurrentLog
        overrideLogFile = nil
        overrideLogContent = nil
    }

    init(overrideLogFile: String) {
        showCurrentLog = true
        self.overrideLogFile = overrideLogFile
        overrideLogContent = nil
    }

    init(overrideLogContent: String) {
        showCurrentLog = false
        overrideLogFile = nil
        self.overrideLogContent = overrideLogContent
    }

    let LSAppNoLog = NSLocalizedString("APPLICATION_NO_LOG", comment: "Application does not have any diagnostic data, try again later.")
    let LSDiagnostic = NSLocalizedString("DIAGNOSTIC", comment: "Diagnostic")

    @State private var showShareSheet = false
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    @State var header: String = ""
    @State var textContent: String = ""

    func updateLog() {
        DispatchQueue.global().async {
            if let override = overrideLogContent {
                header = ""
                textContent = override
                return
            }
            if let override = overrideLogFile {
                header = override
                textContent = (try? String(contentsOfFile: override)) ?? "Filed to read from \(override)"
                return
            }
            if showCurrentLog {
                header = PTLog.shared.currentLogFileLocation?.path ?? "Unknown Error"
                textContent = PTLog.shared.obtainCurrentLogContent()
            } else {
                var newLog = LSAppNoLog
                // read file stucks
                let get = obtainPreviousLog()
                if get.1?.count ?? 0 > 0 {
                    DispatchQueue.main.async {
                        if header != get.0 ?? "" {
                            header = get.0 ?? ""
                        }
                        if let read = get.1 {
                            newLog = read
                        }
                        if newLog != textContent {
                            textContent = newLog
                        }
                    }
                }
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                if header.count > 0 {
                    HStack {
                        Text(header)
                            .font(.system(size: 10, weight: .semibold, design: .default))
                            .multilineTextAlignment(.leading)
                        Spacer()
                    }
                    Divider()
                }
                Text(textContent)
                    .multilineTextAlignment(.leading)
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .opacity(0.6)
                Divider().opacity(0)
            }
            .padding()
        }
        .navigationTitle(LSDiagnostic)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(trailing:
            Button(action: {
                showShareSheet.toggle()
            }, label: {
                Image(systemName: "square.and.arrow.up")
            })
        )
        .sheet(isPresented: $showShareSheet, content: {
            ShareSheet(activityItems: [textContent])
        })
        .onReceive(timer) { _ in
            updateLog()
        }
        .onAppear {
            updateLog()
        }
    }

    func obtainPreviousLog() -> (String?, String?) {
        if let documentLocation = mPillowTalkApp.obtainApplicationStoragePath() {
            return PTLog.shared.obtainPreviousLogContent(baseLocation: documentLocation)
        }
        return (nil, nil)
    }
}
