//
//  SwiftBonjour.swift
//  mPillowTalk
//
//  Created by Lakr Aream on 5/20/21.
//

import SwiftUI

class SBBrowserState: ObservableObject {
    @Published var resolvedServiceProviders = Set<SBServiceState>()

    var resolvedServiceSections: [String?] {
        Set(resolvedServiceProviders.compactMap { $0.txtRecord?["ServerName"] })
            .sorted(by: { $0.localizedCompare($1) == .orderedAscending }) + [nil]
    }

    func resolvedServiceProvidersInSection(_ section: String?) -> [SBServiceState] {
        resolvedServiceProviders
            .filter { $0.txtRecord?["ServerName"] == section }
            .sorted(by: { $0.name.localizedCompare($1.name) == .orderedAscending })
    }
}

class SBServiceState: ObservableObject, Hashable {
    static func == (lhs: SBServiceState, rhs: SBServiceState) -> Bool {
        lhs.hostName == rhs.hostName && lhs.domain == rhs.domain && lhs.name == rhs.name && lhs.port == rhs.port
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(domain)
        hasher.combine(name)
        hasher.combine(hostName)
        hasher.combine(port)
    }

    @Published var domain: String = ""
    @Published var name: String = ""
    @Published var hostName: String?
    @Published var port: Int = 0
    @Published var txtRecord: [String: String]?
    private(set) weak var netService: NetService?

    init() {}

    init(domain: String, name: String, hostName: String?, port: Int, txtRecord: [String: String]?) {
        self.domain = domain
        self.name = name
        self.hostName = hostName
        self.port = port
        self.txtRecord = txtRecord
    }

    init(netService: NetService) {
        domain = netService.domain
        name = netService.name
        hostName = netService.hostName
        port = netService.port
        txtRecord = netService.txtRecordDictionary
        self.netService = netService
    }
}

struct SBDeviceView: View {
//    @State private var showPopup: Bool = false

    var SBServiceState: SBServiceState

    init(SBServiceState: SBServiceState) {
        self.SBServiceState = SBServiceState
    }

    var body: some View {
        HStack {
            Image(systemName: HostClassType
                .displayTypeForHardwareModel(
                    SBServiceState.txtRecord?["HWModel"] ?? ""
                )
                .symbolName
            )
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 30, height: 30, alignment: .center)
            Divider().opacity(0)
            VStack(alignment: .leading, spacing: 0) {
                Text(
                    SBServiceState.txtRecord?["HostName"] ?? SBServiceState.name
                )
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                Spacer().frame(width: 0, height: 4)
                Divider()
                Spacer().frame(width: 0, height: 4)
                Text(
                    SBServiceState
                        .netService?
                        .ipAddresses
                        .map { String(describing: $0) }
                        .sorted(by: { $0.count < $1.count })
                        .first
                        ?? NSLocalizedString("UNKNOWN_ADDRESS", comment: "Unknown Address")
                )
                .font(.system(size: 10, weight: .regular, design: .monospaced))
            }
        }
        .padding()
//        .popover(isPresented: $showPopup, content: {
//            Text(
//                """
//                Domain: \(SBServiceState.domain)
//                Host Name: \(SBServiceState.hostName ?? "Unknown")
//                Hardware Model: \(SBServiceState.txtRecord?["HWModel"] ?? "Unknown")
//                Server Name: \(SBServiceState.txtRecord?["ServerName"] ?? "Unknown")
//                Server Version: \(SBServiceState.txtRecord?["ServerVersion"] ?? "Unknown")
//                """
//            )
//            .padding()
//        })
    }
}

struct SBBrowserView: View {
    @ObservedObject var state: SBBrowserState

    let call: (SBServiceState) -> Void

    var body: some View {
        if state.resolvedServiceProviders.count < 1 {
            VStack {
                HStack {
                    Image(systemName: "bonjour")
                    Text(NSLocalizedString("BONJOUR_NO_DEVICE_FOUND", comment: "No device found over Bonjour service"))
                    Spacer()
                }
                .font(.system(size: 14, weight: .semibold, design: .default))
                .foregroundColor(.overridableAccentColor)
            }
            .padding()
            .background(Color.lightGray)
            .cornerRadius(8)
            .disabled(true)
        } else {
            ForEach(state.resolvedServiceSections, id: \.self) { section in
                ForEach(state.resolvedServiceProvidersInSection(section), id: \.self) { service in
                    Button(action: {
                        call(service)
                    }, label: {
                        ZStack {
                            VStack {
                                Divider().opacity(0)
                            }
                            SBDeviceView(SBServiceState: service)
                        }
                    })
                        .background(Color.lightGray)
                        .cornerRadius(12)
                }
            }
        }
    }
}
