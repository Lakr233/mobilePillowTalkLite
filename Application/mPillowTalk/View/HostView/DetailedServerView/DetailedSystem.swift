//
//  DetailedSystem.swift
//  mPillowTalk
//
//  Created by Lakr Aream on 5/20/21.
//

import PTFoundation
import SwiftUI

struct DetailedSystemElementView: View {
    let timestamp: TimeInterval
    let data: PTServerManager.ServerSystemInfo
    let serverDescriptor: PTServerManager.ServerDescriptor

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State var showProgress: Bool = false

    var body: some View {
        VStack {
            HStack {
                Image(systemName: "gyroscope")
                Text(NSLocalizedString("SYSTEM", comment: "System").uppercased())
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                Spacer()
                Text(data.releaseName)
                    .font(.system(size: 10, weight: .regular, design: .monospaced))
            }
            Divider()
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(NSLocalizedString("HOSTNAME", comment: "Hostname") + ":")
                    Spacer()
                    Text(data.hostname)
                }
                HStack {
                    Text(NSLocalizedString("UPTIME", comment: "Uptime") + ":")
                    Spacer()
                    Text(obtainUptimeDescription())
                }
                HStack {
                    Text(NSLocalizedString("RUNNING_PROCESS", comment: "Running Process") + ":")
                    Spacer()
                    Text("\(data.runningProcs)").font(.system(size: 12, weight: .semibold, design: .monospaced))
                }
                HStack {
                    Text(NSLocalizedString("TOTAL_PROCESS", comment: "Total Process") + ":")
                    Spacer()
                    Text("\(data.totalProcs)").font(.system(size: 12, weight: .semibold, design: .monospaced))
                }
                HStack {
                    Text(NSLocalizedString("AVERAGE_LOAD_1_MIN", comment: "Average Load 1 min") + ":")
                    Spacer()
                    Text(String(format: "%.4f", data.load1))
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                }
                HStack {
                    Text(NSLocalizedString("AVERAGE_LOAD_5_MIN", comment: "Average Load 5 min") + ":")
                    Spacer()
                    Text(String(format: "%.4f", data.load5)).font(.system(size: 12, weight: .semibold, design: .monospaced))
                }
                HStack {
                    Text(NSLocalizedString("AVERAGE_LOAD_15_MIN", comment: "Average Load 15 min") + ":")
                    Spacer()
                    Text(String(format: "%.4f", data.load15)).font(.system(size: 12, weight: .semibold, design: .monospaced))
                }
                Divider().opacity(0)
            }
            .font(.system(size: 12, weight: .semibold, design: .rounded))

            VStack(alignment: .leading, spacing: 2) {
                Divider()
                Divider().opacity(0)
                Divider().opacity(0)
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(NSLocalizedString("STATUS_CAPTURED_AT", comment: "Status captured at"))
                            .font(.system(size: 10, weight: .regular, design: .rounded))
                        Text(Date(timeIntervalSince1970: timestamp).description(with: .current)).font(.system(size: 8, weight: .regular, design: .rounded))
                    }
                    Spacer()
                    if showProgress {
                        ProgressView()
                    }
                }
                .opacity(0.5)
                .onAppear {
                    showProgress = PTServerManager.shared.isServerInUpdate(withKey: serverDescriptor)
                }
                .onReceive(timer, perform: { _ in
                    showProgress = PTServerManager.shared.isServerInUpdate(withKey: serverDescriptor)
                })
            }
            .frame(alignment: .leading)
        }
        .padding()
        .background(Color.lightGray)
        .cornerRadius(12)
    }

    func format(duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.day, .hour, .minute, .second]
        formatter.unitsStyle = .full
        formatter.maximumUnitCount = 1

        return formatter.string(from: duration)!
    }

    func obtainUptimeDescription() -> String {
        format(duration: TimeInterval(data.uptimeSec))
    }
}
