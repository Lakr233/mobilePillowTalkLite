//
//  BootView.swift
//  mPillowTalk
//
//  Created by Lakr Aream on 4/17/21.
//

import SwiftUI

struct BootView: View {
    @Binding var foundationInitialized: Bool
    @ObservedObject var appearance = AppearanceStore.shared
    var body: some View {
        Group {
            if !foundationInitialized {
                ProgressView()
            } else {
                MainView()
            }
        }
        .colorScheme(appearance.colorScheme)
        .transition(.opacity)
    }
}

struct BootView_Previews: PreviewProvider {
    @State static var foundationInitializedNO = false
    @State static var foundationInitializedYES = true
    static var previews: some View {
        BootView(foundationInitialized: $foundationInitializedNO)
        BootView(foundationInitialized: $foundationInitializedYES)
    }
}
