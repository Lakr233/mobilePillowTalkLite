//
//  TabBarTerminalView.swift
//  mPillowTalk
//
//  Created by Lakr Aream on 2021/4/29.
//

import SwiftUI

struct TabBarTerminalView: View {
    var body: some View {
        NavigationView {
            TerminalLoader()
                .navigationTitle(NSLocalizedString("REMOTE_LOGIN", comment: "Remote Login"))
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct TabBarTerminalView_Previews: PreviewProvider {
    static var previews: some View {
        TabBarTerminalView()
    }
}
