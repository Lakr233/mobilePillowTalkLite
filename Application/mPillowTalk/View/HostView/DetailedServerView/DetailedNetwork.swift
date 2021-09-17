//
//  DetailedNetwork.swift
//  mPillowTalk
//
//  Created by Lakr Aream on 5/20/21.
//

import PTFoundation
import SwiftUI

struct DetailedNetworkElementView: View {
    let data: [PTServerManager.ServerNetworkInfo]
    var body: some View {
        VStack {
            HStack {
                Image(systemName: "network")
                Text("NET")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                Spacer()
            }
            Divider()
            VStack(spacing: 12) {
                ForEach(0 ..< data.count, id: \.self) { idx in
                    VStack(spacing: 12) {
                        HStack {
                            Spacer().frame(width: 2.5, height: 0)
                            Image(systemName: "circle.fill")
                                .font(.system(size: 8))
                                .foregroundColor(.orange)
                            Text(data[idx].device)
                            Spacer()
                        }
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                        ], content: {
                            HStack {
                                Image(systemName: "arrow.down")
                                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                                    .foregroundColor(.purple)
                                Text("RX")
                                    .foregroundColor(.purple)
                                Spacer()
                                Text(bytesDescription(bytes: data[idx].rxBytesPerSec))
                                Spacer().frame(width: 5)
                            }
                            HStack {
                                Spacer().frame(width: 5)
                                Image(systemName: "arrow.up").font(.system(size: 14, weight: .heavy, design: .rounded))
                                    .foregroundColor(.blue)
                                Text("TX")
                                    .foregroundColor(.blue)
                                Spacer()
                                Text(bytesDescription(bytes: data[idx].txBytesPerSec))
                            }
                        })
                            .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    }
                }
            }

            Divider()
            HStack {
                Text("RX")
                Text(bytesDescription(bytes: data.map(\.rxBytesPerSec).reduce(0, +)))
                Text("TX")
                Text(bytesDescription(bytes: data.map(\.txBytesPerSec).reduce(0, +)))
                Spacer()
                Text("BYTES")
            }
            .font(.system(size: 8, weight: .semibold, design: .monospaced))
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
