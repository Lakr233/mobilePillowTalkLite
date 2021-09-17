//
//  DetailedDataElementView.swift
//  mPillowTalk
//
//  Created by Lakr Aream on 5/20/21.
//

import PTFoundation
import SwiftUI

struct DetailedDataElementView: View {
    let timestamp: TimeInterval
    let dataSource: PTServerManager.ServerInfo
    let serverDescriptor: PTServerManager.ServerDescriptor

    init(timestamp: TimeInterval,
         dataSource: PTServerManager.ServerInfo,
         server: PTServerManager.ServerDescriptor)
    {
        self.timestamp = timestamp
        self.dataSource = dataSource
        serverDescriptor = server
    }

    var body: some View {
        VStack(spacing: 12) {
            DetailedSystemElementView(timestamp: timestamp, data: dataSource.ServerSystemInfo, serverDescriptor: serverDescriptor)
            DetailedCPUElementView(data: dataSource.ServerProcessInfo)
            DetailedRAMElementView(data: dataSource.ServerMemoryInfo)
            DetailedNetworkElementView(data: dataSource.ServerNetworkInfo.sorted(by: { a, b in
                a.device < b.device
            }))
            DetailedFileSystemView(data: dataSource.ServerFileSystemInfo)
            NavigationLink(destination: AppLogView(overrideLogContent: dataSource.description() ?? "Unknown Error")) {
                HStack {
                    Image(systemName: "text.magnifyingglass")
                    Text(NSLocalizedString("SHOW_RAW_RECORD", comment: "Show Raw Record"))
                    Spacer()
                }
                .font(.system(size: 14, weight: .semibold, design: .default))
                .padding()
                .background(
                    Color
                        .lightGray
                        .frame(height: 40)
                        .cornerRadius(8)
                )
            }
        }
    }
}

#if DEBUG
    fileprivate
    let mockObject = try! PTFoundation.jsonDecoder.decode(PTServerManager.ServerInfo.self, from: Data(base64Encoded: "eyJTZXJ2ZXJNZW1vcnlJbmZvIjp7Im1lbUZyZWUiOjIyNTM0MCwibWVtVG90YWwiOjIwMzU0MDAsIm1lbUNhY2hlZCI6NzQyOTMyLCJzd2FwVG90YWwiOjk2OTk2NCwic3dhcFVzZWQiOjAuMjQ2NDAyNjY1OTcyNzA5NjYsIm1lbUJ1ZmZlcnMiOjQwMTM2LCJwaHlVc2VkIjowLjUwNDU2NTE3OTM0Nzk5MTk0LCJzd2FwRnJlZSI6NDY4NDM2fSwiU2VydmVyU3lzdGVtSW5mbyI6eyJ0b3RhbFByb2NzIjo1NTMsInJ1bm5pbmdQcm9jcyI6MSwibG9hZDEiOjAuMDA5OTk5OTk5Nzc2NDgyNTgyMSwibG9hZDUiOjAsInVwdGltZVNlYyI6MjAyMTM2NSwicmVsZWFzZU5hbWUiOiJVYnVudHUgMjAuMDQuMiBMVFMiLCJob3N0bmFtZSI6ImI1MDQzYzFhMTA4NiIsImxvYWQxNSI6MH0sIlNlcnZlckZpbGVTeXN0ZW1JbmZvIjpbeyJmcmVlQnl0ZXMiOjg4MjgxMzc0NzIsInVzZWRQZXJjZW50Ijo3OC4wMzQ2MTQ1NjI5ODgyODEsIm1vdW50UG9pbnQiOiJcLyIsInVzZWRCeXRlcyI6MzEzNjI5OTgyNzJ9LHsiZnJlZUJ5dGVzIjo4ODI4MTM3NDcyLCJ1c2VkUGVyY2VudCI6NzguMDM0NjE0NTYyOTg4MjgxLCJtb3VudFBvaW50IjoiXC9ldGNcL2hvc3RzIiwidXNlZEJ5dGVzIjozMTM2Mjk5ODI3Mn1dLCJTZXJ2ZXJQcm9jZXNzSW5mbyI6eyJzdW1tYXJ5Ijp7InN1bVVzZXIiOjEuMDQxNjY2NzQ2MTM5NTI2NCwic3VtU3lzdGVtIjoyLjA4MzMzMzQ5MjI3OTA1MjcsInN1bU5pY2UiOjAsInN1bVVzZWQiOjQuMTY2NjY2OTg0NTU4MTA1NSwic3VtSU9XYWl0IjoxLjA0MTY2Njc0NjEzOTUyNjR9LCJjb3JlcyI6eyJjcHUwIjp7InN1bVVzZXIiOjEuMDQxNjY2NzQ2MTM5NTI2NCwic3VtU3lzdGVtIjoyLjA4MzMzMzQ5MjI3OTA1MjcsInN1bU5pY2UiOjAsInN1bVVzZWQiOjQuMTY2NjY2OTg0NTU4MTA1NSwic3VtSU9XYWl0IjoxLjA0MTY2Njc0NjEzOTUyNjR9fX0sIlNlcnZlck5ldHdvcmtJbmZvIjpbeyJyeEJ5dGVzUGVyU2VjIjo1NDAsImRldmljZSI6ImV0aDAiLCJ0eEJ5dGVzUGVyU2VjIjoxOTEyfSx7InJ4Qnl0ZXNQZXJTZWMiOjAsImRldmljZSI6ImxvIiwidHhCeXRlc1BlclNlYyI6MH1dLCJjb21waWxlQXQiOjY0MzIwMDAwNS4xMzgzOTEwMn0K")!)
    struct DetailedDataElementView_Previews: PreviewProvider {
        static var previews: some View {
            VStack {
                DetailedDataElementView(timestamp: Date().timeIntervalSince1970,
                                        dataSource: mockObject,
                                        server: "")
                Spacer()
            }
            .padding()
            .previewLayout(.fixed(width: 350, height: 1200))
        }
    }
#endif
