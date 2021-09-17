//
//  AddServerView.swift
//  mPillowTalk
//
//  Created by Lakr Aream on 4/19/21.
//

import PTFoundation
import SwiftUI

struct AddServerView: View {
    init(passedData: PassedData? = nil) {
        self.passedData = passedData
    }

    struct PassedData {
        init(underSection: String? = nil,
             modifyServer: PTServerManager.ServerDescriptor? = nil)
        {
            self.underSection = underSection
            self.modifyServer = modifyServer
        }

        let underSection: String?
        let modifyServer: PTServerManager.ServerDescriptor?
    }

    let passedData: PassedData?

    @State var address: String = ""
    @State var port: String = "22"
    @State var username: String = "root"
    @State var password: String = ""
    @State var privateKeyStr: String = ""
    @State var nickname: String = ""
    @State var sectionName: String = ""
    @State var mountpoint: String = ""
    @State var networkInterface: String = ""

    @State var openFileSheet: Bool = false

    @StateObject var windowObserver = WindowObserver()
    struct AccountSelectionElement {
        let title: String
        let represented: PTAccountManager.AccountType
    }

    var accountSelection = [
        AccountSelectionElement(title: NSLocalizedString("SSH_AND_PASSWORD", comment: "SSH + Password"),
                                represented: .secureShellWithPassword),
        AccountSelectionElement(title: NSLocalizedString("SSH_AND_Key", comment: "SSH + Key"),
                                represented: .secureShellWithKey),
    ]
    @State var selectedAccountIndex = 0
    @State var selectedAccountType: PTAccountManager.AccountType? = nil

    let textFiledFont = Font.system(size: 16, weight: .regular, design: .default)

    let LSNavigationTitle = NSLocalizedString("ADD_SERVER", comment: "Add Server")
    let LSNavigationTitleModify = NSLocalizedString("MODIFY", comment: "Modify Server")
    let LSTitleServerBasic = NSLocalizedString("SERVER_BASIC", comment: "Server Basic")

    let LSAddress = NSLocalizedString("ADDRESS", comment: "Address")
    let LSAddressExample = NSLocalizedString("ADDRESS_EXAMPLE", comment: "Example: 192.168.1.1")
    let LSPort = NSLocalizedString("PORT", comment: "Port")
    let LSPortExample = NSLocalizedString("PORT_EXAMPLE", comment: "Example: 22")

    let LSAccount = NSLocalizedString("ACCOUNT", comment: "Account")
    let LSUsername = NSLocalizedString("USERNAME", comment: "Username")
    let LSUsernameExample = NSLocalizedString("USERNAME_EXAMPLE", comment: "Example: root")
    let LSPassword = NSLocalizedString("PASSWORD", comment: "Password")
    let LSPrivateKey = NSLocalizedString("PRIVATE_KEY", comment: "Private Key")

    let LSCustomization = NSLocalizedString("CUSTOMIZATION", comment: "Customization")

    let LSNickname = NSLocalizedString("NICKNAME", comment: "Nickname")
    let LSNicknameExample = NSLocalizedString("NICKNAME_EXAMPLE", comment: "Example: iServer")
    let LSSectionName = NSLocalizedString("SECTION_NAME", comment: "Section Name")
    let LSMountPoint = NSLocalizedString("MOUNT_POINT", comment: "Mount Point")
    let LSMountPointExample = NSLocalizedString("MOUNT_POINT_EXAMPLE", comment: "Example: /coreData/sdd")
    let LSNetInterface = NSLocalizedString("NETWORK_INTERFACE", comment: "Network Interface")
    let LSNetInterfaceExample = NSLocalizedString("NETWORK_INTERFACE_EXAMPLE", comment: "Example: enp0s1")

    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        Group {
            ScrollView {
                VStack(spacing: 12) {
                    serverAddr
                    accountTypeSelector
                    customization
                    HStack {
                        Button(action: {
                            windowObserver.window?.topMostViewController?.dismiss(animated: true, completion: nil)
                            presentationMode.wrappedValue.dismiss()
                        }, label: {
                            HStack {
                                Spacer()
                                Image(systemName: "xmark")
                                Spacer()
                            }
                            .padding(10)
                            .foregroundColor(.overridableAccentColor)
                            .font(.system(size: 20, weight: .regular, design: .default))
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .foregroundColor(.white)
                                        .opacity(0.05)
                                    RoundedRectangle(cornerRadius: 8)
                                        .foregroundColor(.white)
                                        .shadow(radius: 6)
                                        .opacity(0.2)
                                }
                            )
                            .frame(maxWidth: 500)
                        })
                        Button(action: {
                            addServer()
                        }, label: {
                            HStack {
                                Spacer()
                                Image(systemName: "arrow.right")
                                Spacer()
                            }
                            .padding(10)
                            .foregroundColor(.overridableAccentColor)
                            .font(.system(size: 20, weight: .regular, design: .default))
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .foregroundColor(.white)
                                        .opacity(0.05)
                                    RoundedRectangle(cornerRadius: 8)
                                        .foregroundColor(.white)
                                        .shadow(radius: 6)
                                        .opacity(0.2)
                                }
                            )
                        })
                    }
                }
                .padding()
            }
            .navigationTitle(passedData?.modifyServer == nil ? LSNavigationTitle : LSNavigationTitleModify)
            .navigationBarItems(trailing:
                Button(action: {
                    addServer()
                }, label: {
                    Image(systemName: "arrow.right.circle.fill")
                })
            )
            .background(
                HostingWindowFinder { [weak windowObserver] window in
                    windowObserver?.window = window
                }
            )
        }
        .onAppear {
            if let serverDescriptor = passedData?.modifyServer,
               let server = PTServerManager.shared.obtainServer(withKey: serverDescriptor)
            {
                address = server.host
                port = String(server.port)
                if let account = PTAccountManager
                    .shared
                    .retrieveAccountWith(key: server.accountDescriptor)?
                    .obtainDecryptedObject()
                {
                    username = account.account
                    password = account.key
                    if let data = account.representedObject,
                       let key = String(data: data, encoding: .utf8)
                    {
                        privateKeyStr = key
                        selectedAccountIndex = 1
                        selectedAccountType = .secureShellWithKey
                    }
                }
                nickname = server.tags[.nickName, default: ""]
                if let sectionName = server.tags[.sectionName],
                   sectionName != PTServerManager.Server.defaultSectionName
                {
                    self.sectionName = sectionName
                }
                mountpoint = server.tags[.preferredMountPoint, default: ""]
                networkInterface = server.tags[.preferredNetworkInterface, default: ""]
            }
        }
        .sheet(isPresented: $openFileSheet, content: {
            DocumentPicker(fileContent: $privateKeyStr)
        })
    }

    var serverAddr: some View {
        AddServerStepView(title: LSTitleServerBasic,
                          icon: "externaldrive.connected.to.line.below.fill") {
            VStack {
                InputElementView(title: LSAddress,
                                 placeholder: LSAddressExample,
                                 required: true,
                                 validator: {
                                     isServerAddrValid(addr: address)
                                 },
                                 type: .URL,
                                 useInlineTextField: true,
                                 binder: $address)
                InputElementView(title: LSPort,
                                 placeholder: LSPortExample,
                                 required: true,
                                 validator: {
                                     if let port = Int(port), port >= 0, port <= 65535 {
                                         return true
                                     }
                                     return false
                                 },
                                 type: nil,
                                 useInlineTextField: true,
                                 binder: $port)
            }
        }
    }

    var accountTypeSelector: some View {
        AddServerStepView(title: LSAccount,
                          icon: "key.fill") {
            VStack(spacing: 12) {
                Picker(selection: $selectedAccountIndex,
                       label: Text(""), content: {
                           ForEach(0 ..< accountSelection.count) {
                               Text(self.accountSelection[$0].title)
                           }
                       })
                    .pickerStyle(SegmentedPickerStyle())
                    .onReceive([self.selectedAccountIndex].publisher.first()) { _ in
                        selectedAccountType = accountSelection[selectedAccountIndex].represented
                    }
                Group {
                    if selectedAccountType == .secureShellWithPassword {
                        usePassword
                    } else if selectedAccountType == .secureShellWithKey {
                        useKey
                    } else {
                        Text("Unknown Error")
                    }
                }
            }
        }
        .animation(.interactiveSpring(response: 0.25,
                                      dampingFraction: 1,
                                      blendDuration: 0))
    }

    var usePassword: some View {
        VStack {
            InputElementView(title: LSUsername,
                             placeholder: LSUsernameExample,
                             required: true,
                             validator: {
                                 username.count > 0
                             },
                             type: .username,
                             useInlineTextField: true,
                             binder: $username)
            InputElementView(title: LSPassword,
                             placeholder: "",
                             required: true,
                             validator: {
                                 password.count > 0
                             },
                             type: .password,
                             useInlineTextField: true,
                             binder: $password)
        }
    }

    var useKey: some View {
        VStack {
            InputElementView(title: LSUsername,
                             placeholder: LSUsernameExample,
                             required: true,
                             validator: {
                                 username.count > 0
                             },
                             type: .username,
                             useInlineTextField: true,
                             binder: $username)
            InputElementView(title: LSPassword,
                             placeholder: "",
                             required: false,
                             validator: { true },
                             type: .password,
                             useInlineTextField: true,
                             binder: $password)
            InputElementView(title: LSPrivateKey,
                             placeholder: "OPENSSH PRIVATE KEY",
                             required: true,
                             validator: {
                                 privateKeyStr.count > 0
                             },
                             type: nil,
                             useInlineTextField: false,
                             binder: $privateKeyStr)
            TextEditor(text: $privateKeyStr)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .frame(height: 50)
                .padding()
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .foregroundColor(.lightGray)
                            .opacity(0.5)
                        if privateKeyStr.count < 1 {
                            Text("OPENSSH PRIVATE KEY".uppercased())
                                .font(.system(size: 12, weight: .regular, design: .default))
                        }
                    }
                )
            HStack {
                Spacer()
                Button(action: {
                    openFileSheet.toggle()
                }, label: {
                    HStack {
                        Image(systemName: "folder")
                            .frame(width: 20, height: 16)
                    }
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                })
            }
        }
    }

    var customization: some View {
        AddServerStepView(title: LSCustomization,
                          icon: "lasso.sparkles") {
            VStack(spacing: 12) {
                InputElementView(title: LSNickname,
                                 placeholder: LSNicknameExample,
                                 required: false,
                                 validator: { true },
                                 type: .nickname,
                                 useInlineTextField: true,
                                 binder: $nickname)
                InputElementView(title: LSSectionName,
                                 placeholder: NSLocalizedString("DEFAULT_SECTION_NAME", comment: "Default"),
                                 required: false,
                                 validator: { true },
                                 type: nil,
                                 useInlineTextField: true,
                                 binder: $sectionName)
                    .onAppear {
                        if let passed = passedData,
                           let section = passed.underSection,
                           section != PTServerManager.Server.defaultSectionName
                        {
                            sectionName = section
                        }
                    }
                InputElementView(title: LSMountPoint,
                                 placeholder: LSMountPointExample,
                                 required: false,
                                 validator: { true },
                                 type: nil,
                                 useInlineTextField: true,
                                 binder: $mountpoint)
                InputElementView(title: LSNetInterface,
                                 placeholder: LSNetInterfaceExample,
                                 required: false,
                                 validator: { true },
                                 type: nil,
                                 useInlineTextField: true,
                                 binder: $networkInterface)
            }
        }
    }

    func addServer() {
        func obtainViewController() -> UIViewController? {
            let vc: UIViewController? = windowObserver.window?.topMostViewController
            return vc
        }

        func failed() {
            let alert = UIAlertController(title: NSLocalizedString("ERROR", comment: "Error"),
                                          message: NSLocalizedString("ALERT_ERROR_SUBMIT_NEW_SERVER_TINT", comment: "An error occurred during submission, check your sheet carefully."),
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("DONE", comment: "Done"),
                                          style: .default,
                                          handler: nil))
            obtainViewController()?.present(alert, animated: true, completion: nil)
        }

        func complete() {
            obtainViewController()?.dismiss(animated: true, completion: nil)
            presentationMode.wrappedValue.dismiss()
        }

        guard let type = selectedAccountType else {
            failed()
            return
        }
        switch type {
        case .secureShellWithKey:
            let host = address
            let username = username
            let password = password
            let key = privateKeyStr
            guard host.count > 0,
                  isServerAddrValid(addr: host),
                  let port = Int32(port),
                  username.count > 0,
                  key.count > 0
            else {
                failed()
                return
            }
            guard let account = PTAccountManager.shared.createAccountWith(user: username,
                                                                          candidate: password,
                                                                          attachData: key.data(using: .utf8),
                                                                          type: .secureShellWithKey)
            else {
                failed()
                return
            }
            var tags: [PTServerManager.Server.ServerTag: String] = [:]
            if nickname.count > 0 { tags[.nickName] = nickname }
            if mountpoint.count > 0 { tags[.preferredMountPoint] = mountpoint }
            if networkInterface.count > 0 { tags[.preferredNetworkInterface] = networkInterface }
            if sectionName.count > 0 { tags[.sectionName] = sectionName }
            let server = PTServerManager.Server(host: host,
                                                port: port,
                                                accountDescriptor: account,
                                                supervisionTimeInterval: 0,
                                                tags: tags)
            guard let server = PTServerManager.shared.createServer(withObject: server,
                                                                   onRecoverableError: { interrupt, _ in
                                                                       debugPrint(interrupt)
                                                                       return PTServerManager.RegistrationSolution.continueRegistration
                                                                   })
            else {
                PTAccountManager.shared.removeAccount(withKey: account)
                failed()
                return
            }
            debugPrint(server)
            PTServerManager.shared.superviseOnServer(withKey: server,
                                                     interval: Agent.shared.supervisionInterval)
            complete()
        case .secureShellWithPassword:
            let host = address
            let username = username
            let password = password
            guard host.count > 0,
                  isServerAddrValid(addr: host),
                  let port = Int32(port),
                  username.count > 0,
                  password.count > 0
            else {
                failed()
                return
            }
            guard let account = PTAccountManager.shared.createAccountWith(user: username,
                                                                          candidate: password,
                                                                          attachData: nil,
                                                                          type: .secureShellWithPassword)
            else {
                failed()
                return
            }
            var tags: [PTServerManager.Server.ServerTag: String] = [:]
            if nickname.count > 0 { tags[.nickName] = nickname }
            if mountpoint.count > 0 { tags[.preferredMountPoint] = mountpoint }
            if networkInterface.count > 0 { tags[.preferredNetworkInterface] = networkInterface }
            if sectionName.count > 0 { tags[.sectionName] = sectionName }
            let server = PTServerManager.Server(host: host,
                                                port: port,
                                                accountDescriptor: account,
                                                supervisionTimeInterval: 0,
                                                tags: tags)
            guard let server = PTServerManager.shared.createServer(withObject: server,
                                                                   onRecoverableError: { interrupt, _ in
                                                                       debugPrint(interrupt)
                                                                       return PTServerManager.RegistrationSolution.continueRegistration
                                                                   })
            else {
                PTAccountManager.shared.removeAccount(withKey: account)
                failed()
                return
            }
            debugPrint(server)
            PTServerManager.shared.superviseOnServer(withKey: server,
                                                     interval: Agent.shared.supervisionInterval)
            complete()
        }

        // if fail, not here
        if let passedData = passedData,
           let modify = passedData.modifyServer,
           let server = PTServerManager.shared.obtainServer(withKey: modify)
        {
            debugPrint("Removing old server that was modified: \(server.uuid)")
            PTAccountManager.shared.removeAccount(withKey: server.accountDescriptor)
            PTServerManager.shared.removeServerFromRegisteredList(withKey: server.uuid)
        }
    }
}

struct AddServerView_Previews: PreviewProvider {
    static var previews: some View {
        AddServerView()
            .preferredColorScheme(.light)
            .previewLayout(.fixed(width: 300, height: 900))
        AddServerView()
            .preferredColorScheme(.light)
            .previewLayout(.fixed(width: 600, height: 900))
        AddServerView()
            .preferredColorScheme(.dark)
            .previewLayout(.fixed(width: 600, height: 900))
    }
}
