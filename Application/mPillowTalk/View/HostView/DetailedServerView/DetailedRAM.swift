//
//  DetailedRAM.swift
//  mPillowTalk
//
//  Created by Lakr Aream on 5/20/21.
//

import PTFoundation
import SwiftUI

struct DetailedRAMElementView: View {
    let data: PTServerManager.ServerMemoryInfo
    var body: some View {
        VStack {
            HStack {
                Image(systemName: "memorychip")
                Text("RAM")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                Spacer()
                Text(localizeMemoryInfo(KBytes: Int(data.memTotal)))
                    .font(.system(size: 10, weight: .regular, design: .monospaced))
            }
            Divider()
            VStack(spacing: 2) {
                HStack {
                    Text(String(
                        format: "USED: %@ CACHE %@ FREE %@ SWAP %@",
                        localizeMemoryInfo(KBytes: data.memTotal - data.memFree),
                        localizeMemoryInfo(KBytes: data.memCached),
                        localizeMemoryInfo(KBytes: data.memFree),
                        localizeMemoryInfo(KBytes: data.swapTotal)
                    )
                    )
                    Spacer()
                    Text(String(format: "%.2f", (1.0 - (data.memFree / data.memTotal)) * 100) + " %")
                }
                .font(.system(size: 8, weight: .regular, design: .monospaced))
                SeparatedProgressView(height: 25,
                                      backgroundColor: .green,
                                      rounded: false,
                                      progressElements: [
                                          (.yellow, data.memTotal - data.memFree),
                                          (.orange, data.memCached),
                                      ],
                                      emptyHolder: data.memFree)
                    .cornerRadius(5)
            }

            Divider()

            LazyVGrid(columns:
                [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                ], content: {
                    HStack {
                        Circle()
                            .foregroundColor(.yellow)
                            .frame(width: 10, height: 10)
                        Text("USED")
                            .font(.system(size: 10, weight: .semibold, design: .default))
                        Spacer()
                    }
                    HStack {
                        Circle()
                            .foregroundColor(.orange)
                            .frame(width: 10, height: 10)
                        Text("CACHE")
                            .font(.system(size: 10, weight: .semibold, design: .default))
                        Spacer()
                    }
                    HStack {
                        Circle()
                            .foregroundColor(.green)
                            .frame(width: 10, height: 10)
                        Text("FREE")
                            .font(.system(size: 10, weight: .semibold, design: .default))
                        Spacer()
                    }
                })
        }
        .padding()
        .background(Color.lightGray)
        .cornerRadius(12)
    }

    func localizeMemoryInfo(KBytes: Int) -> String {
        if KBytes >= 1_000_000 {
            return "\(KBytes / 1_000_000) GB"
        } else if KBytes > 1000 {
            return "\(KBytes / 1000) MB"
        }
        return "\(KBytes) KB"
    }

    func localizeMemoryInfo(KBytes: Float) -> String {
        localizeMemoryInfo(KBytes: Int(KBytes))
    }
}
