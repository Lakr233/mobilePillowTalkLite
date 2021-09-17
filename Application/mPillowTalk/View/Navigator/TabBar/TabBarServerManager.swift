//
//  TabBarServerManager.swift
//  mPillowTalk
//
//  Created by Lakr Aream on 5/18/21.
//

import SwiftUI

struct TabBarServerManager: View {
    var body: some View {
        NavigationView {
            ServerManagerView()
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct TabBarServerManager_Previews: PreviewProvider {
    static var previews: some View {
        TabBarServerManager()
    }
}
