//
//  SettingElementView.swift
//  mPillowTalk
//
//  Created by Lakr Aream on 5/18/21.
//

import SwiftUI

struct SettingElementView: View {
    let icon: String
    let title: String
    let subTitle: String

    var body: some View {
        Group {
            HStack {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: icon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20)
                        Text(title)
                    }
                    .font(.system(size: 18, weight: .semibold, design: .default))
                    Text(subTitle)
                        .font(.system(size: 14, weight: .regular, design: .default))
                        .opacity(0.5)
                }
                Spacer()
                Image(systemName: "arrow.forward")
                    .foregroundColor(.overridableAccentColor)
            }
            .padding()
        }
        .background(Color.black.opacity(0.001)) // fuck
    }
}

struct SettingToggleView: View {
    let icon: String
    let title: String
    let subTitle: String
    let update: () -> (Bool)
    let callback: (Bool) -> Void
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init(icon: String, title: String, subTitle: String, update: @escaping (() -> (Bool)), callback: @escaping ((Bool) -> Void)) {
        self.icon = icon
        self.title = title
        self.subTitle = subTitle
        self.update = update
        self.callback = callback
    }

    @State var status: Bool = false

    var body: some View {
        Group {
            HStack {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: icon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20)
                        Text(title)
                    }
                    .font(.system(size: 18, weight: .semibold, design: .default))
                    Text(subTitle)
                        .font(.system(size: 14, weight: .regular, design: .default))
                        .opacity(0.5)
                }
                Spacer()
                Button(action: {
                    status.toggle()
                    callback(status)
                }, label: {
                    Image(systemName: status ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(.overridableAccentColor)
                })
                    .onReceive(timer, perform: { _ in
                        status = update()
                    })
            }
            .padding()
        }
        .onAppear {
            status = update()
        }
        .background(Color.black.opacity(0.001)) // fuck
    }
}

struct SettingButtonView: View {
    let icon: String
    let title: String
    let subTitle: String
    let callback: (String) -> Void

    @Binding var buttonStr: String

    init(icon: String,
         title: String,
         subTitle: String,
         callback: @escaping ((String) -> Void),
         buttonStr: Binding<String>)
    {
        self.icon = icon
        self.title = title
        self.subTitle = subTitle
        self.callback = callback
        _buttonStr = buttonStr
    }

    var body: some View {
        Group {
            HStack {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: icon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20)
                        Text(title)
                    }
                    .font(.system(size: 18, weight: .semibold, design: .default))
                    Text(subTitle)
                        .font(.system(size: 14, weight: .regular, design: .default))
                        .opacity(0.5)
                }
                Spacer()
                Button(action: {
                    callback(buttonStr)
                }, label: {
                    Text(buttonStr)
                        .foregroundColor(.overridableAccentColor)
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                })
            }
            .padding()
        }
        .background(Color.black.opacity(0.001)) // fuck
    }
}

struct SettingElementView_Previews: PreviewProvider {
    static var previews: some View {
        SettingElementView(icon: "gear",
                           title: "General",
                           subTitle: "Configure the main features of Pillow Talk")
            .previewLayout(.fixed(width: 400, height: 100))
        SettingToggleView(icon: "gear",
                          title: "General",
                          subTitle: "Some some some long not long string",
                          update: {
                              true
                          },
                          callback: { _ in

                          })
            .previewLayout(.fixed(width: 400, height: 100))
        SettingButtonView(icon: "gear",
                          title: "General",
                          subTitle: "Some some some long not long string",
                          callback: { _ in

                          },
                          buttonStr: .constant("000"))
            .previewLayout(.fixed(width: 400, height: 100))
    }
}
