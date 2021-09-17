//
//  PairDeviceSenderView.swift
//  mPillowTalk
//
//  Created by Lakr Aream on 5/18/21.
//

import CodeScanner
import PTFoundation
import SwiftBonjour
import SwiftUI

struct PairDeviceSenderView: View {
    @State private var isShowingScanner = false
    @StateObject var windowObserver = WindowObserver()

    init() {
        state = SBBrowserState()
        browser = BonjourBrowser()
    }

    let state: SBBrowserState
    let browser: BonjourBrowser

    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(NSLocalizedString("SCANNING_DEVICES", comment: "Scanning Devices"))
                        .bold()
                    Spacer()
                    ProgressView()
                }

                bonjourView

                Text(NSLocalizedString("OTHER_OPTIONS", comment: "Other Options"))
                    .bold()

                Button {
                    isShowingScanner = true
                } label: {
                    HStack {
                        Image(systemName: "qrcode.viewfinder")
                        Text(NSLocalizedString("SCAN_QR_CODE", comment: "Scan QR Code"))
                        Spacer()
                    }
                    .padding(.horizontal)
                    .font(.system(size: 16, weight: .semibold, design: .default))
                    .frame(height: 60)
                    .background(Color.lightGray.cornerRadius(12))
                }
                Button {
                    let alert = UIAlertController(title: NSLocalizedString("INPUT_MANUALLY", comment: "Input Manually"),
                                                  message: NSLocalizedString("INPUT_MANUALLY_ALERT_TINT", comment: "Input target ip address manually here"),
                                                  preferredStyle: .alert)
                    alert.addTextField { setup in
                        setup.autocorrectionType = .no
                        setup.font = .monospacedSystemFont(ofSize: 14, weight: .semibold)
                        setup.placeholder = "192.168.x.x"
                    }
                    alert.addAction(UIAlertAction(title: NSLocalizedString("CONTINUE", comment: "Continue"),
                                                  style: .default,
                                                  handler: { _ in
                                                      if let text = alert.textFields?.first?.text,
                                                         text.count > 0
                                                      {
                                                          startUpload(toAddresses: [text])
                                                      }
                                                  }))
                    alert.addAction(UIAlertAction(title: NSLocalizedString("CANCEL", comment: "Cancel"),
                                                  style: .cancel,
                                                  handler: nil))
                    windowObserver.window?.topMostViewController?.present(alert, animated: true, completion: nil)
                } label: {
                    HStack {
                        Image(systemName: "square.and.pencil")
                        Text(NSLocalizedString("INPUT_MANUALLY", comment: "Input Manually"))
                        Spacer()
                    }
                    .padding(.horizontal)
                    .font(.system(size: 16, weight: .semibold, design: .default))
                    .frame(height: 60)
                    .background(Color.lightGray.cornerRadius(12))
                }
                Divider().opacity(0)
            }
            .padding()
        }
        .sheet(isPresented: $isShowingScanner, content: {
            CodeScannerView(codeTypes: [.qr], simulatedData: "", completion: self.handleScan)
        })
        .background(
            HostingWindowFinder { [weak windowObserver] window in
                windowObserver?.window = window
            }
        )
        .navigationTitle(NSLocalizedString("TRANSFER_CONFIG", comment: "Transfer Config"))
    }

    var bonjourView: some View {
        SBBrowserView(state: state) { state in
            guard let addr = state.netService?.ipAddresses else {
                return
            }
            let addrs = addr.map { String(describing: $0) }
            PTLog.shared.join("Bonjour", "Passing encrypted transfer package to \(addrs)")
            startUpload(toAddresses: addrs, shouldDismiss: false)
        }
        .onAppear {
            DispatchQueue.main.async {
                browser.serviceFoundHandler = { service in
                    print("Service found")
                    print(service)
                }

                browser.serviceResolvedHandler = { result in
                    print("Service resolved")
                    print(result)
                    switch result {
                    case let .success(service):
                        state.resolvedServiceProviders.insert(SBServiceState(netService: service))
                    case .failure:
                        break
                    }
                }

                browser.serviceRemovedHandler = { service in
                    print("Service removed")
                    print(service)
                    if let serviceToRemove = state.resolvedServiceProviders.first(where: { $0.domain == service.domain && $0.name == service.name }) {
                        state.resolvedServiceProviders.remove(serviceToRemove)
                    }
                }

                browser.browse(type: .tcp("http"))
            }
        }
        .onDisappear {
            DispatchQueue.main.async {
                browser.stop()
            }
        }
    }

    private func handleScan(result: Result<String, CodeScannerView.ScanError>) {
        isShowingScanner = false
        switch result {
        case let .success(str):
            if let data = str.data(using: .utf8),
               let addrs = try? PTFoundation.jsonDecoder.decode([String].self, from: data)
            {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    startUpload(toAddresses: addrs)
                }
            }
        default:
            debugPrint("scan failed")
        }
    }

    func startUpload(toAddresses address: [String], shouldDismiss: Bool = true) {
        guard let package = PTTransfer.shared.obtainTransferData() else {
            return
        }
        if address.filter({ $0.count > 0 }).count > 0, shouldDismiss {
            windowObserver.window?.topMostViewController?.dismiss(animated: true, completion: nil)
            presentationMode.wrappedValue.dismiss()
        }
        DispatchQueue.global().async {
            let alert = UIAlertController(title: package.pin,
                                          message: NSLocalizedString("ENTER_PIN_ON_ANOTHER_DEVICE_ALERT_TINT", comment: "Enter PIN on another device to decrypt transferred data."),
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("DONE", comment: "Done"),
                                          style: .default,
                                          handler: nil))
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                windowObserver.window?.topMostViewController?.present(alert, animated: true, completion: nil)
            }
            let group = DispatchGroup()
            for addr in address.filter({ $0.count > 0 }) {
                let str = "http://\(addr):5343/upload?conf=\(package.base64)"
                guard let url = URL(string: str) else {
                    continue
                }
                group.enter()
                let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData)
                let task = URLSession.shared.dataTask(with: request) { _, _, _ in
                    group.leave()
                }
                task.resume()
            }
            group.wait()
        }
    }
}

struct PairDeviceSenderView_Previews: PreviewProvider {
    static var previews: some View {
        PairDeviceSenderView()
    }
}
