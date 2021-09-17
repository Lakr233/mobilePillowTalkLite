//
//  DetailedCPU.swift
//  mPillowTalk
//
//  Created by Lakr Aream on 5/20/21.
//

import PTFoundation
import SwiftUI

struct DetailedCPUElementView: View {
    let data: PTServerManager.ServerProcessInfo

    var body: some View {
        VStack {
            HStack {
                Image(systemName: "cpu")
                Text("CPU")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                Spacer()
                Text(data.cores.count > 1 ? "\(data.cores.count) CORES" : "\(data.cores.count) CORE")
                    .font(.system(size: 10, weight: .regular, design: .monospaced))
            }
            Divider()
            DetailedCPUElementItemView(title: NSLocalizedString("ALL_CORE", comment: "All Core"), data: data.summary)
            Divider()
            ForEach(data.cores.keys.sorted(by: { a, b in
                if a.count < 3 || b.count < 3 {
                    return a < b
                }
                if let droppedA = Int(a.dropFirst(3)),
                   let droppedB = Int(b.dropFirst(3))
                {
                    return droppedA < droppedB
                } else {
                    return a < b
                }
            }), id: \.self) { key in
                DetailedCPUElementItemView(title: key, data: data.cores[key]!)
            }
            Divider()
            LazyVGrid(columns:
                [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                ], content: {
                    HStack {
                        Circle()
                            .foregroundColor(.yellow)
                            .frame(width: 10, height: 10)
                        Text("USER")
                            .font(.system(size: 10, weight: .semibold, design: .default))
                        Spacer()
                    }
                    HStack {
                        Circle()
                            .foregroundColor(.red)
                            .frame(width: 10, height: 10)
                        Text("SYS")
                            .font(.system(size: 10, weight: .semibold, design: .default))
                        Spacer()
                    }
                    HStack {
                        Circle()
                            .foregroundColor(.orange)
                            .frame(width: 10, height: 10)
                        Text("IO")
                            .font(.system(size: 10, weight: .semibold, design: .default))
                        Spacer()
                    }
                    HStack {
                        Circle()
                            .foregroundColor(.blue)
                            .frame(width: 10, height: 10)
                        Text("NICE")
                            .font(.system(size: 10, weight: .semibold, design: .default))
                        Spacer()
                    }
                })
        }
        .padding()
        .background(Color.lightGray)
        .cornerRadius(12)
    }
}

struct DetailedCPUElementItemView: View {
    let title: String
    let data: PTServerManager.ServerProcessInfoCalculatedElement
    var body: some View {
        VStack(spacing: 2) {
            HStack {
                Text(title.uppercased())
                    .font(.system(size: 10, weight: .bold, design: .default))
                Spacer()
                Text(String(format: "%.2f", data.sumUsed) + " %")
                    .font(.system(size: 10, weight: .regular, design: .monospaced))
                    .foregroundColor(data.sumUsed > 75 ? .red : .blue)
            }
            SeparatedProgressView(height: 8,
                                  backgroundColor: .systemGray5,
                                  rounded: true,
                                  progressElements: [
                                      (.yellow, data.sumUser),
                                      (.red, data.sumSystem),
                                      (.orange, data.sumIOWait),
                                      (.blue, data.sumNice),
                                  ],
                                  emptyHolder: 100 - data.sumUsed)
            HStack {
                Text(String(format: "USER %.2f SYSTEM %.2f IO %.2f NICE %.2f", data.sumUser, data.sumSystem, data.sumIOWait, data.sumNice))
                    .font(.system(size: 8, weight: .regular, design: .monospaced))
                Spacer()
            }
            Divider().opacity(0)
        }
    }
}
