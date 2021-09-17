//
//  GatheringDataView.swift
//  mPillowTalk
//
//  Created by Lakr Aream on 2021/4/30.
//

import PTFoundation
import SwiftUI

struct GatheringDataView: View {
    @State var currentDate: String = ""

    /*
     让这个 View 去和 Agent 对接当前的状态
     */
    @ObservedObject var agent = Agent.shared
    @State var ringColors: [Color] = [Color.overridableAccentColor]

    let LSTitleTint = NSLocalizedString("SUMMARY", comment: "Summary")

    let LSTitleWelcome = NSLocalizedString("WELCOME_ABROAD", comment: "Welcome Abroad")
    let LSTitleInUpdate = NSLocalizedString("SERVER_IN_UPDATE_%d", comment: "Updating %d")

    let LSSubTitleNotOne = NSLocalizedString("NO_SERVER_REGISTERED_TINT", comment: "No server registered. Register a server now!")
    let LSSubTitleReg = NSLocalizedString("%d_SERVER_REGISTERED", comment: "%d servers registered")
    let LSSubTitleTakeTime = NSLocalizedString("THIS_WILL_TAKE_TIME_TINT", comment: "This will take some time, please keep the app running in front.")

    @State var title: String = ""
    @State var subTitle: String = ""
    @State var dateStr: String = ""

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var head: some View {
        HStack {
            Image(systemName: "newspaper")
            Text(LSTitleTint.uppercased())
            Spacer()
            NavigationLink(
                destination: AppLogView(showCurrentLog: true),
                label: {
                    Image(systemName: "scroll")
                }
            )
        }
        .font(.system(size: 15, weight: .regular, design: .default))
        .foregroundColor(.overridableAccentColor)
    }

    var body: some View {
        VStack {
//            head
//            Divider()
            NavigationLink(
                destination: AppLogView(showCurrentLog: true),
                label: {
                    container
                }
            )
            .buttonStyle(PlainButtonStyle())
        }
        .onAppear {
            updateStrings()
        }
        .onReceive(timer) { _ in
            updateStrings()
        }
    }

    func updateStrings() {
        let cnt = PTServerManager.shared.obtainAcquireInProgressCount()
        if cnt > 0 {
            title = String(format: LSTitleInUpdate, cnt)
            subTitle = LSSubTitleTakeTime
        } else {
            title = LSTitleWelcome
            if agent.serverDescriptorsSorted.count == 0 {
                subTitle = LSSubTitleNotOne
            } else {
                subTitle = String(format: LSSubTitleReg, agent.serverDescriptorsSorted.count)
            }
        }
        dateStr = Date().description(with: .current)
    }

    var container: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: .infinity))]) {
            VStack(alignment: .leading) {
                Text(title)
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                if subTitle.count > 0 {
                    Text(subTitle)
                        .font(.system(size: 10, weight: .regular, design: .default))
                        .opacity(0.5)
                }
                Divider()
                Text(dateStr)
                    .font(.system(size: 8, weight: .regular, design: .default))
                    .opacity(0.5)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .foregroundColor(.lightGray)
            )
        }
        .animation(Animation.interactiveSpring())
    }
}

struct GatheringDataView_Previews: PreviewProvider {
    static var previews: some View {
        GatheringDataView()
            .previewLayout(.fixed(width: 400, height: 200))
        GatheringDataView()
            .previewLayout(.fixed(width: 600, height: 200))
    }
}
