//
//  SettingMonitorView.swift
//  mPillowTalk
//
//  Created by Lakr Aream on 5/27/21.
//

import PTFoundation
import SwiftUI

struct SettingMonitorView: View {
    @StateObject var windowObserver = WindowObserver()

    @ObservedObject var agent = Agent.shared

    @State var supervisionTimeInterval: String = ""
    @State var supervisionMaxRecord: String = ""

    var body: some View {
        Group {
            ScrollView {
                VStack(spacing: 12) {
                    Section {
                        VStack(spacing: 4) {
                            Group {
                                SettingButtonView(icon: "stopwatch",
                                                  title: NSLocalizedString("MONITOR_INTERVAL", comment: "Monitor Interval"),
                                                  subTitle: NSLocalizedString("MONITOR_INTERVAL_TINT", comment: "Set the interval for each data gathering task"),
                                                  callback: { str in
                                                      let alert = UIAlertController(title: NSLocalizedString("MONITOR_INTERVAL", comment: "Monitor Interval"),
                                                                                    message: NSLocalizedString("MONITOR_INTERVAL_VALUE_TINT", comment: "A monitor interval that is too small may cost extra load to remote machine."),
                                                                                    preferredStyle: .alert)
                                                      alert.addTextField { textField in
                                                          textField.placeholder = "60"
                                                          textField.text = "\(Agent.shared.supervisionInterval)"
                                                      }
                                                      alert.addAction(UIAlertAction(title: NSLocalizedString("CANCEL", comment: "Cancel"),
                                                                                    style: .cancel,
                                                                                    handler: nil))
                                                      alert.addAction(UIAlertAction(title: NSLocalizedString("DONE", comment: "Done"),
                                                                                    style: .default,
                                                                                    handler: { _ in
                                                                                        if let str = alert.textFields?.first?.text,
                                                                                           let value = Int(str)
                                                                                        {
                                                                                            Agent.shared.supervisionInterval = value
                                                                                            supervisionTimeInterval = String(format: NSLocalizedString("%d_SECOND", comment: "%ds"), Agent.shared.supervisionInterval)
                                                                                        }
                                                                                    }))
                                                      windowObserver
                                                          .window?
                                                          .topMostViewController?
                                                          .present(alert,
                                                                   animated: true,
                                                                   completion: nil)
                                                  }, buttonStr: $supervisionTimeInterval)
                                    .onAppear {
                                        supervisionTimeInterval = String(format: NSLocalizedString("%d_SECOND", comment: "%ds"), Agent.shared.supervisionInterval)
                                    }
                            }
                            .padding(.horizontal, 8)
                        }
                        .background(Color.lightGray)
                        .cornerRadius(12)
                    }
                    Section {
                        VStack(spacing: 4) {
                            Group {
                                SettingToggleView(icon: "externaldrive.fill.badge.timemachine",
                                                  title: NSLocalizedString("MONITOR_ENABLE_RECORD", comment: "Enable Record"),
                                                  subTitle: NSLocalizedString("MONITOR_ENABLE_RECORD_TINT", comment: "Should we record server status")) {
                                    Agent.shared.supervisionRecordEnabled
                                } callback: { value in
                                    Agent.shared.supervisionRecordEnabled = value
                                    if !value {
                                        let alert = UIAlertController(title: "",
                                                                      message: NSLocalizedString("DELETE_EXIST_RECORD", comment: "Do you wish to delete exist records?"),
                                                                      preferredStyle: .alert)
                                        alert.addAction(UIAlertAction(title: NSLocalizedString("CONTINUE", comment: "Continue"),
                                                                      style: .destructive,
                                                                      handler: { _ in
                                                                          PTServerManager.shared.purgeDatabase()
                                                                      }))
                                        alert.addAction(UIAlertAction(title: NSLocalizedString("CANCEL", comment: "Cancel"),
                                                                      style: .default,
                                                                      handler: nil))
                                        windowObserver.window?.topMostViewController?.present(alert, animated: true, completion: nil)
                                    }
                                }
//                                Divider()
//                                SettingButtonView(icon: "tray.full",
//                                                  title: NSLocalizedString("MONITOR_MAX_RECORD", comment: "Max Record"),
//                                                  subTitle: NSLocalizedString("MONITOR_MAX_RECORD_TINT", comment: "How many record should we keep for each server"),
//                                                  callback: { str in
//                                                      let alert = UIAlertController(title: NSLocalizedString("MONITOR_MAX_RECORD", comment: "Max Record"),
//                                                                                    message: NSLocalizedString("MONITOR_MAX_RECORD_TINT", comment: "How many record should we keep for each server"),
//                                                                                    preferredStyle: .alert)
//                                                      alert.addTextField { textField in
//                                                          textField.placeholder = "255"
//                                                          textField.text = "\(Agent.shared.supervisionMaxRecord)"
//                                                      }
//                                                      alert.addAction(UIAlertAction(title: NSLocalizedString("CANCEL", comment: "Cancel"),
//                                                                                    style: .cancel,
//                                                                                    handler: nil))
//                                                      alert.addAction(UIAlertAction(title: NSLocalizedString("DONE", comment: "Done"),
//                                                                                    style: .default,
//                                                                                    handler: { _ in
//                                                                                        if let str = alert.textFields?.first?.text,
//                                                                                           let value = Int(str)
//                                                                                        {
//                                                                                            Agent.shared.supervisionMaxRecord = value
//                                                                                            supervisionMaxRecord = String(Agent.shared.supervisionMaxRecord)
//                                                                                        }
//                                                                                    }))
//                                                      windowObserver
//                                                          .window?
//                                                          .topMostViewController?
//                                                          .present(alert,
//                                                                   animated: true,
//                                                                   completion: nil)
//                                                  }, buttonStr: $supervisionMaxRecord)
//                                    .onAppear {
//                                        supervisionMaxRecord = String(Agent.shared.supervisionMaxRecord)
//                                    }
                            }
                            .padding(.horizontal, 8)
                        }
                        .background(Color.lightGray)
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
        }
        .background(
            HostingWindowFinder { [weak windowObserver] window in
                windowObserver?.window = window
            }
        )
        .navigationTitle(NSLocalizedString("MONITOR", comment: "Monitor"))
    }
}

struct SettingMonitorView_Previews: PreviewProvider {
    static var previews: some View {
        SettingMonitorView()
            .previewLayout(.fixed(width: 400, height: 800))
    }
}
