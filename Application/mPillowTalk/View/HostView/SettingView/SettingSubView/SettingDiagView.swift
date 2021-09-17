//
//  SettingDiagView.swift
//  mPillowTalk
//
//  Created by Lakr Aream on 5/19/21.
//

import PTFoundation
import SwiftUI

struct SettingDiagView: View {
    @State var logPath = [LogElement]()

    struct LogElement: Identifiable {
        var id: String { path }

        let path: String
        let fileName: String
        let timestamp: Int

        init(withPTLogFilePath path: String) {
            self.path = path
            fileName = URL(fileURLWithPath: path).lastPathComponent
            let dateStr = String(fileName.dropFirst(6).dropLast(13))
            let initDateFormatter = DateFormatter()
            initDateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
            let date = initDateFormatter.date(from: dateStr)
            timestamp = Int(date?.timeIntervalSince1970 ?? 0)
        }
    }

    var body: some View {
        Group {
            if logPath.count > 0 {
                List(logPath, id: \.id) { element in
                    NavigationLink(
                        destination: AppLogView(overrideLogFile: element.path),
                        label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(element.fileName)
                                    .bold()
                                Text(Date(timeIntervalSince1970: TimeInterval(element.timestamp)).description(with: .current))
                                    .font(.system(size: 12, weight: .regular, design: .default))
                                Text(element.path)
                                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                                    .opacity(0.5)
                            }
                            .padding(.vertical, 4)
                        }
                    )
                }
            } else {
                VStack(alignment: .leading) {
                    Divider()
                    Text(NSLocalizedString("DIAGNOSTIC_NO_DATA", comment: "No diagnostic data were generated, try gain later."))
                        .bold()
                        .padding()
                }
            }
        }
        .navigationTitle(NSLocalizedString("DIAGNOSTIC", comment: "Diagnostic"))
        .onAppear {
            updateLogItems()
        }
    }

    func updateLogItems() {
        logPath = PTLog.shared.obtainAllLogFilePath().map { path in
            LogElement(withPTLogFilePath: path)
        }.sorted(by: { a, b in
            a.timestamp > b.timestamp
        })
    }
}

struct SettingDiagView_Previews: PreviewProvider {
    static var previews: some View {
        SettingDiagView()
    }
}
