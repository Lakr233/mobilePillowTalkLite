//
//  ServerManagerView.swift
//  mPillowTalk
//
//  Created by Lakr Aream on 2021/4/29.
//

import PTFoundation
import SwiftUI

struct ServerManagerView: View {
    @ObservedObject var agent = Agent.shared

    @State var addServerViewPresented: Bool = false

    @State var endingString: String = ""
    let LSEnding = NSLocalizedString("%d_SECTIONS_%d_SERVERS", comment: "%d section(s), %d server(s)")

    var body: some View {
        ScrollView {
            VStack {
                ForEach(agent.serverSectionsSorted, id: \.self) { sectionName in
                    ServerSectionList(sectionName: sectionName)
                }
                if agent.serverSectionsSorted.count == 0 {
                    NoServerGuider()
                } else {
                    SectionAddServerButton(sectionName: nil)
                }
                Divider()
                Text(endingString)
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                NavigationLink(destination: AddServerView(),
                               isActive: $addServerViewPresented,
                               label: { Divider().opacity(0) })
            }
            .padding()
            .onReceive([agent.serverDescriptorsSorted].publisher.first()) { _ in
                updateEndingString()
            }
            .onReceive([agent.$serverSectionsSorted].publisher.first()) { _ in
                updateEndingString()
            }
            .onAppear {
                updateEndingString()
            }
        }
        .navigationTitle(NSLocalizedString("MANAGEMENT", comment: "Management"))
        .navigationBarItems(trailing:
            Button(action: {
                addServerViewPresented.toggle()
            }, label: {
                Text(NSLocalizedString("ADD", comment: "Add"))
            })
        )
    }

    func updateEndingString() {
        endingString = String(format: LSEnding, agent.serverSectionsSorted.count, agent.serverDescriptorsSorted.count)
    }
}

struct ServerManagerView_Previews: PreviewProvider {
    static var previews: some View {
        ServerManagerView()
            .previewLayout(.fixed(width: 500, height: 1000))
    }
}
