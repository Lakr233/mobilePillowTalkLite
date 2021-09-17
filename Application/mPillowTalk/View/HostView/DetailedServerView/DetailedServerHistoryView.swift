//
//  DetailedServerHistoryView.swift
//  mPillowTalk
//
//  Created by Lakr Aream on 5/21/21.
//

import PTFoundation
import SwiftUI

struct DetailedServerHistoryView: View {
    let serverDescriptor: PTServerManager.ServerDescriptor

    @State var progressViewHolder: Bool = true
    @State var dataSource: PassedData?

    struct PassedData {
        let select: (TimeInterval, PTServerManager.ServerInfo?)?
        let info: [TimeInterval: PTServerManager.ServerInfo]

        init(info: [TimeInterval: PTServerManager.ServerInfo]) {
            self.info = info
            if let lastKey = info.keys.sorted().last,
               let object = info[lastKey]
            {
                select = (lastKey, object)
            } else {
                select = nil
            }
        }
    }

    init(serverDescriptor: PTServerManager.ServerDescriptor) {
        self.serverDescriptor = serverDescriptor
    }

    var body: some View {
        Group {
            if progressViewHolder {
                VStack {
                    Spacer().frame(height: 200)
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                }
            } else {
                if dataSource == nil {
                    VStack(alignment: .leading) {
                        HStack {
                            Image(systemName: "questionmark.folder.fill")
                                .font(.system(size: 50, weight: .semibold, design: .rounded))
                            Spacer()
                        }
                        .opacity(0.5)
                        Divider()
                        Text(NSLocalizedString("NO_RECORD_FOUND", comment: "No Record Found")).font(.system(size: 12, weight: .semibold, design: .default))
                            .opacity(0.5)
                        Spacer().frame(height: 150)
                    }
                    .padding()
                } else {
                    ScrollView {
                        Group {
                            VStack {
                                ForEach(dataSource!.info.keys.sorted { $0 > $1 }, id: \.self) { timestamp in
                                    NavigationLink(
                                        destination:
                                        Group {
                                            ScrollView {
                                                DetailedDataElementView(timestamp: timestamp, dataSource: dataSource!.info[timestamp]!, server: serverDescriptor)
                                                    .padding()
                                            }
                                            .navigationTitle(NSLocalizedString("HISTORY", comment: "History"))
                                        },
                                        label: {
                                            HStack {
                                                Text(Date(timeIntervalSince1970: timestamp).description(with: .current))
                                                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                                Spacer()
                                                Image(systemName: "arrow.right")
                                            }
                                            .padding()
                                            .background(Color.lightGray.cornerRadius(12))
                                        }
                                    )
                                }
                            }
                            .listStyle(PlainListStyle())
                            VStack(alignment: .leading) {
                                Divider()
                                Text(String(format: NSLocalizedString("%d_RECORD_IN_TOTAL", comment: "%d records in total"), dataSource!.info.count))
                                    .font(.system(size: 12, weight: .semibold, design: .default))
                                    .opacity(0.5)
                                Spacer().frame(height: 20)
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .onAppear {
            if !progressViewHolder {
                return
            }
            DispatchQueue.global().async {
                let info = PTServerManager.shared.obtainStatusRecordForServer(serverDescriptor: serverDescriptor)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    dataSource = .init(info: info)
                    progressViewHolder = false
                }
                DispatchQueue.global().async {
                    let info = PTServerManager.shared.obtainStatusRecordForServer(serverDescriptor: serverDescriptor)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        dataSource = .init(info: info)
                        progressViewHolder = false
                    }
                }
            }
        }
        .navigationTitle(NSLocalizedString("HISTORY", comment: "History"))
    }
}

struct DetailedServerHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        DetailedServerHistoryView(serverDescriptor: "")
    }
}
