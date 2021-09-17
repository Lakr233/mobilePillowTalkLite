//
//  TabBarMiscView.swift
//  mPillowTalk
//
//  Created by Lakr Aream on 2021/4/29.
//

import SwiftUI

struct TabBarMiscView: View {
    var body: some View {
        NavigationView {
            SettingView()
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct TabBarMiscView_Previews: PreviewProvider {
    static var previews: some View {
        TabBarMiscView()
    }
}
