//
//  DetailedFileSystem.swift
//  mPillowTalk
//
//  Created by Lakr Aream on 5/20/21.
//

import PTFoundation
import SwiftUI

struct DetailedFileSystemView: View {
    let data: [PTServerManager.ServerFileSystemInfo]
    var body: some View {
        VStack {
            HStack {
                Image(systemName: "square.stack.3d.up.fill")
                Text("DISK")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                Spacer()
            }
            Divider()
            VStack(spacing: 12) {
                ForEach(0 ..< data.count, id: \.self) { idx in
                    VStack(spacing: 6) {
                        HStack {
                            Text(data[idx].mountPoint)
                                .font(.system(size: 12, weight: .bold, design: .default))
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text(String(format: " %.2f", data[idx].usedPercent) + " %")
                                    .font(.system(size: 10, weight: .regular, design: .monospaced))
                                    .foregroundColor(data[idx].usedPercent > 75 ? .red : .blue)
                                Text(String(
                                    format: "USED: %@ FREE %@",
                                    bytesDescription(bytes: data[idx].usedBytes),
                                    bytesDescription(bytes: data[idx].freeBytes)
                                ))
                            }
                            .font(.system(size: 8, weight: .regular, design: .monospaced))
                        }

                        SeparatedProgressView(height: 25,
                                              backgroundColor: .systemGray5,
                                              rounded: false,
                                              progressElements: [
                                                  (.yellow, Float(data[idx].usedBytes)),
                                              ],
                                              emptyHolder: Float(data[idx].freeBytes))
                            .cornerRadius(5)
                    }
                }
            }
            Divider()
            HStack {
                Text(NSLocalizedString("MOUNTPOINT_INACCURATE_WARNING", comment: "Mount point may be inaccurate due to system limit")).font(.system(size: 8, weight: .regular, design: .monospaced))
                Spacer()
            }
            .opacity(0.5)
        }
        .padding()
        .background(Color.lightGray)
        .cornerRadius(12)
    }

    func bytesDescription(bytes: Int) -> String {
        if bytes >= 1_000_000_000 {
            return "\(bytes / 1_000_000_000) GB"
        } else if bytes >= 1_000_000 {
            return "\(bytes / 1_000_000) MB"
        } else if bytes > 1000 {
            return "\(bytes / 1000) KB"
        }
        return "\(bytes) B"
    }
}
