//
//  TabBarBoardView.swift
//  mPillowTalk
//
//  Created by Lakr Aream on 2021/4/29.
//

import PTFoundation
import SwiftUI

struct TabBarBoardView: View {
    let LSNavTitle = NSLocalizedString("NAV_TITLE_BOARD", comment: "Board")

    @State var shouldOpenAddSheet: Bool = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 10) {
                    GatheringDataView()
                    ServerBoardView()
                    VStack {
                        #if DEBUG
                            Divider()
                            Text(NSLocalizedString("COPY_RIGHT_FULL", comment: "Copyright © 2020 Pillow Talk Team. All rights reserved."))
                                .font(.system(size: 8, weight: .semibold, design: .monospaced))
                        #endif
                        Divider().opacity(0)
                            .background(
                                NavigationLink(
                                    destination: AddServerView(),
                                    isActive: $shouldOpenAddSheet,
                                    label: {
                                        Text("").hidden()
                                    }
                                )
                                .frame(width: 0, height: 0, alignment: .center)
                            )
                    }
                }.padding(.horizontal)
            }
            .navigationTitle(LSNavTitle)
            .navigationBarItems(trailing: Group {
                Button(action: {
                    shouldOpenAddSheet.toggle()
                }, label: {
                    Image(systemName: "plus")
                })
            })
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct TabBarBoardView_Previews: PreviewProvider {
    static var previews: some View {
        TabBarBoardView()
    }
}
