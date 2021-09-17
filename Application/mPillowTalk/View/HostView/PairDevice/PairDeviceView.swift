//
//  PairDeviceView.swift
//  mPillowTalk
//
//  Created by Lakr Aream on 4/18/21.
//

import PTFoundation
import SwiftUI

private var alertPresented: Bool = false

struct PairDeviceView: View {
    @StateObject var windowObserver = WindowObserver()

    @Environment(\.presentationMode) var presentationMode

    @State var qrcode: Image? = nil
    @State var uploadedData: String = ""

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { reader in
            if reader.size.width > 600 {
                VStack {
                    Spacer()
                    HStack {
                        ZStack {
                            if let image = qrcode {
                                RoundedRectangle(cornerRadius: 12)
                                    .foregroundColor(.white)
                                    .frame(width: 233, height: 233)
                                RoundedRectangle(cornerRadius: 12)
                                    .foregroundColor(.black)
                                    .opacity(0.02)
                                    .frame(width: 233, height: 233)
                                image
                                    .resizable()
                                    .renderingMode(.original)
                                    .scaledToFit()
                                    .frame(width: 222, height: 222)
                            } else {
                                ProgressView()
                            }
                        }
                        .animation(.easeInOut)
                        .padding()
                        VStack(alignment: .leading) {
                            HStack {
                                Text(NSLocalizedString("TRANSFER_CONFIG", comment: "Transfer Config"))
                                    .font(.system(size: 30, weight: .semibold))
                                Spacer()
                                ProgressView()
                            }
                            Text(NSLocalizedString("TRANSFER_CONFIG_INSTRUCTION_SCAN", comment: "Scan QRCode to import configuration from other devices running PillowTalk."))
                                .font(.system(size: 14, weight: .regular))
                            Divider()
                            Text("\(NSLocalizedString("TRANSFER_CONFIG_INSTRUCTION_INPUT", comment: "Manually connect using following addresses")):\n\n-> Bonjour [\(PairAgent.shared.obtainBonjourName())]\n\(ipAddressDescription())")
                                .font(.system(size: 14, weight: .regular, design: .monospaced))
                        }
                        .padding()
                    }
                    .padding()
                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 50, trailing: 0))
                    Spacer()
                }
            } else {
                ScrollView {
                    VStack {
                        ZStack {
                            if let image = qrcode {
                                RoundedRectangle(cornerRadius: 12)
                                    .foregroundColor(.white)
                                RoundedRectangle(cornerRadius: 12)
                                    .foregroundColor(.black)
                                    .opacity(0.02)
                                image
                                    .resizable()
                                    .renderingMode(.original)
                                    .scaledToFit()
                                    .padding(8)
                            } else {
                                ProgressView()
                            }
                        }
                        .animation(.easeInOut)
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: reader.size.width * 0.6,
                               maxHeight: reader.size.height * 0.6)
                        VStack(alignment: .leading) {
                            HStack {
                                Text(NSLocalizedString("TRANSFER_CONFIG", comment: "Transfer Config"))
                                    .font(.system(size: 24, weight: .semibold))
                                Spacer()
                                ProgressView()
                                    .scaleEffect(0.6)
                            }
                            Text(NSLocalizedString("TRANSFER_CONFIG_INSTRUCTION_SCAN", comment: "Scan QRCode to import configuration from other devices running PillowTalk."))
                                .font(.system(size: 14, weight: .regular))
                            Divider()
                            Text("\(NSLocalizedString("TRANSFER_CONFIG_INSTRUCTION_INPUT", comment: "Manually connect using following addresses")):\n\n-> Bonjour [\(PairAgent.shared.obtainBonjourName())]\n\(ipAddressDescription())")
                                .font(.system(size: 14, weight: .regular, design: .monospaced))
                        }
                    }
                    .padding()
                }
            }
        }
        .background(
            HostingWindowFinder { [weak windowObserver] window in
                windowObserver?.window = window
            }
        )
        .onAppear(perform: {
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
                let url = URL(string: "https://apple.com") ?? URL(fileURLWithPath: "")
                let task = URLSession.shared.dataTask(with: url)
                task.resume()
                if let cgImg = obtainQRCode() {
                    let build = Image(uiImage: UIImage(cgImage: cgImg))
                    DispatchQueue.main.async {
                        qrcode = build
                    }
                }
            }
            _ = PairAgent.shared
            DispatchQueue.global().async {
                PairAgent.shared.startWebServer()
            }
        })
        .onDisappear {
            DispatchQueue.global().async {
                PairAgent.shared.tearDownServer()
            }
        }
        .onReceive(timer, perform: { _ in
            if PairAgent.shared.uploadedData.count > 1 {
                if alertPresented { return }
                alertPresented = true
                uploadedData = PairAgent.shared.uploadedData
                PairAgent.shared.uploadedData = ""
                PTLog.shared.join("PairAgent",
                                  "Got pair data with lenth: \(uploadedData.count)",
                                  level: .info)
                DispatchQueue.global().async {
                    PairAgent.shared.tearDownServer()
                }
                let alert = UIAlertController(title: NSLocalizedString("PIN_REQUIRED", comment: "Pin Required"),
                                              message: NSLocalizedString("ENTER_PIN_ALERT_TINT", comment: "Enter your PIN number given by uploader to continue."),
                                              preferredStyle: .alert)
                alert.addTextField { textField in
                    textField.keyboardType = .numberPad
                    textField.placeholder = "0000"
                    textField.font = .monospacedDigitSystemFont(ofSize: 14, weight: .bold)
                }
                alert.addAction(UIAlertAction(title: NSLocalizedString("CANCEL", comment: "Cancel"),
                                              style: .cancel,
                                              handler: { _ in
                                                  alertPresented = false
                                                  DispatchQueue.global().async {
                                                      PairAgent.shared.startWebServer()
                                                  }
                                              }))
                alert.addAction(UIAlertAction(title: NSLocalizedString("CONTINUE", comment: "Continue"),
                                              style: .destructive, handler: { _ in
                                                  let textField = alert.textFields![0]
                                                  let pin = textField.text
                                                  PairAgent
                                                      .shared
                                                      .startTransfer(withData: uploadedData,
                                                                     withPIN: pin ?? "",
                                                                     withInWindow: windowObserver.window ?? UIWindow(),
                                                                     onComplete: {
                                                                         alertPresented = false
                                                                         DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                                                             windowObserver.window?.topMostViewController?.dismiss(animated: true, completion: nil)
                                                                             presentationMode.wrappedValue.dismiss()
                                                                         }
                                                                     })
                                              }))
                windowObserver.window?.topMostViewController?.present(alert, animated: true, completion: nil)
            }
        })
    }

    func ipAddressDescription() -> String {
        var str = ""
        getIPAddress().sorted(by: { a, b -> Bool in
            a.count < b.count
        }).forEach { addr in
            str.append("-> \(addr)\n")
        }
        if str.hasSuffix("\n") {
            str.removeLast()
        }
        if str.count < 1 {
            return "No address available, check your internet connection."
        }
        return str
    }

    func obtainQRCode() -> CGImage? {
        let address = getIPAddress() // json Encode 了一个 [String]
        let data = (try? PTFoundation.jsonEncoder.encode(address)) ?? Data()
        let img = generateQRCode(from: String(data: data, encoding: .utf8) ?? "")
        return img
    }

    func generateQRCode(from string: String) -> CGImage? {
        let data = string.data(using: String.Encoding.ascii)
        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            let transform = CGAffineTransform(scaleX: 5, y: 5)
            if let output = filter.outputImage?.transformed(by: transform) {
                if let colorFilter = CIFilter(name: "CIFalseColor") {
                    colorFilter.setDefaults()
                    colorFilter.setValue(output, forKey: "inputImage")
                    let transparentBG = CIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
                    let qrColor = CIColor(red: 0, green: 0, blue: 0)
                    colorFilter.setValue(qrColor, forKey: "inputColor0")
                    colorFilter.setValue(transparentBG, forKey: "inputColor1")
                    let outputImage = colorFilter.outputImage!
                    let context = CIContext()
                    let cgImg = context.createCGImage(outputImage, from: outputImage.extent)
                    return cgImg
                }
            }
        }
        return nil
    }

    func getIPAddress() -> [String] {
        var address: [String] = []
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        if getifaddrs(&ifaddr) == 0 {
            var ptr = ifaddr
            while ptr != nil {
                defer { ptr = ptr?.pointee.ifa_next }

                guard let interface = ptr?.pointee else { return [] }
                let addrFamily = interface.ifa_addr.pointee.sa_family
                if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {
                    // wifi = ["en0"]
                    // wired = ["en2", "en3", "en4"]
                    // cellular = ["pdp_ip0","pdp_ip1","pdp_ip2","pdp_ip3"]

                    let name = String(cString: interface.ifa_name)
                    if name == "en0"
                        || name == "en2"
                        || name == "en3"
                        || name == "en4"
                        || name == "pdp_ip0"
                        || name == "pdp_ip1"
                        || name == "pdp_ip2"
                        || name == "pdp_ip3"
                    {
                        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                        getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len), &hostname, socklen_t(hostname.count), nil, socklen_t(0), NI_NUMERICHOST)
                        address.append(String(cString: hostname))
                    }
                }
            }
            freeifaddrs(ifaddr)
        }
        return address
    }
}

struct PairDeviceView_Previews: PreviewProvider {
    static var previews: some View {
        PairDeviceView()
    }
}
