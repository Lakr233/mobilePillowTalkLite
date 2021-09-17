//
//  PTServerManager.swift
//  PTFoundation
//
//  Created by Lakr Aream on 12/23/20.
//

import Foundation

fileprivate extension Float {
    var safeWrapper: Float {
        if self == .nan || self == .signalingNaN {
            return 0
        }
        if self > Float(Int.max) {
            return 0
        }
        if self < Float(Int.min) {
            return 0
        }
        return self
    }
}

fileprivate extension Double {
    var safeWrapper: Double {
        if self == .nan || self == .signalingNaN {
            return 0
        }
        if self > Double(Int.max) {
            return 0
        }
        if self < Double(Int.min) {
            return 0
        }
        return self
    }
}

public extension PTServerManager {
    /// 服务器结构体
    struct Server: Codable, Hashable, PTUIRepresentable {
        /// 静态定义
        public static let defaultSectionName = "!$DEFAULT_SECTION$"

        /// 服务器基础信息
        public var uuid: PTServerManager.ServerDescriptor
        public var host: String
        public var port: Int32
        public var accountDescriptor: String

        /// 监视内容
        public var supervisionTimeInterval: Int

        /// 标签
        public var tags: [ServerTag: String]

        /// 标签所定义的键值
        public enum ServerTag: String, Codable {
            /// 别名
            case nickName
            /// 组名
            case sectionName
            /// 用于展示的挂载点路径
            case preferredMountPoint
            /// 用于展示的网络接口
            case preferredNetworkInterface
        }

        /// 成员属性初始化
        public init(uuid: String = UUID().uuidString,
                    host: String,
                    port: Int32,
                    accountDescriptor: String,
                    supervisionTimeInterval: Int,
                    tags: [ServerTag: String])
        {
            self.uuid = uuid
            self.host = host
            self.port = port
            self.accountDescriptor = accountDescriptor
            self.supervisionTimeInterval = supervisionTimeInterval
            self.tags = tags
        }

        /// 拷贝 为日后改为 class 保留空间
        /// - Returns: 拷贝对象
        public func copy() -> Self {
            .init(uuid: uuid,
                  host: host,
                  port: port,
                  accountDescriptor: accountDescriptor,
                  supervisionTimeInterval: supervisionTimeInterval,
                  tags: tags)
        }

        /// 获取智能名称
        /// - Returns: 名称字符串
        public func obtainPossibleName() -> String {
            tags[.nickName] ?? (host + ":" + String(port)) // NSLocalizedString("GENERIC_SERVER", comment: "Generic Server")
        }

        /// 获取用户名
        /// - Returns: 用户名 如果有
        public func obtainPossibleUsername() -> String? {
            let account = PTAccountManager.shared.retrieveAccountWith(key: accountDescriptor)
            let username = account?.obtainDecryptedObject()?.account
            return username
        }

        /// 组名
        /// - Returns: 分组字符串
        public func obtainSectionName() -> String {
            tags[.sectionName] ?? PTServerManager.Server.defaultSectionName
        }

        /// 期望监视的挂载点
        /// - Returns: 挂载点字符串
        public func obtainPreferredMountPoint() -> String? {
            tags[.preferredMountPoint]
        }

        /// 期望监视的网络接口
        /// - Returns: 网络接口字符串
        public func obtainPreferredNetworkInterface() -> String? {
            tags[.preferredNetworkInterface]
        }
    }

    /// 服务器状态
    struct ServerStatus: Codable {
        /// 指向引用
        public var serverDescriptor: String
        /// 上次更新的时间 只有更新成功才会更新该字段
        public var previousUpdate: Date? = nil
        /// 是否正在更新
        public var pendingUpdate: Bool = false
        /// 当前状态
        public var information: ServerInfo?
        /// 是否已经更新
        public var statusUpdated: Bool = false
        /// 上次更新是否出错
        public var errorOccurred: Bool = false
    }

    /// 服务器 CPU 信息
    struct ServerProcessInfo: Codable, Equatable {
        public var summary: ServerProcessInfoCalculatedElement
        public var cores: [String: ServerProcessInfoCalculatedElement]
        internal init() {
            summary = ServerProcessInfoCalculatedElement()
            cores = [:]
        }

        internal init(summary: ServerProcessInfoCalculatedElement,
                      cores: [String: ServerProcessInfoCalculatedElement])
        {
            self.summary = summary
            self.cores = cores
        }
    }

    /// 服务器 CPU 信息 这里全部是百分比
    struct ServerProcessInfoCalculatedElement: Codable, Equatable {
        public var sumSystem: Float
        public var sumUser: Float
        public var sumIOWait: Float
        public var sumNice: Float
        public var sumUsed: Float
        internal init() {
            sumSystem = 0
            sumUser = 0
            sumIOWait = 0
            sumNice = 0
            sumUsed = 0
        }

        internal init(system: Float, user: Float,
                      iowait: Float, nice: Float,
                      sum: Float)
        {
            sumSystem = system.safeWrapper
            sumUser = user.safeWrapper
            sumIOWait = iowait.safeWrapper
            sumNice = nice.safeWrapper
            sumUsed = sum.safeWrapper
        }

        public func description() -> String {
            "system: \(sumSystem), user: \(sumUser), iowait: \(sumIOWait), nice: \(sumNice)"
        }
    }

    /// 服务器 CPU 的立即信息
    struct ServerProcessStatus: Codable, Equatable {
        public let user: Float
        public let nice: Float
        public let system: Float
        public let idle: Float
        public let iowait: Float
        public let irq: Float
        public let softIrq: Float
        public let steal: Float
        public let guest: Float

        internal init(user: Float, nice: Float, system: Float, idle: Float, iowait: Float, irq: Float, softIrq: Float, steal: Float, guest: Float) {
            self.user = user.safeWrapper
            self.nice = nice.safeWrapper
            self.system = system.safeWrapper
            self.idle = idle.safeWrapper
            self.iowait = iowait.safeWrapper
            self.irq = irq.safeWrapper
            self.softIrq = softIrq.safeWrapper
            self.steal = steal.safeWrapper
            self.guest = guest.safeWrapper
        }

        public func description() -> String {
            """
            user: \(user)
            nice: \(nice)
            system: \(system)
            idle: \(idle)
            iowait: \(iowait)
            irq: \(irq)
            softIrq: \(softIrq)
            steal: \(steal)
            guest: \(guest)
            """
        }
    }

    /// 服务器 RAM 信息
    struct ServerMemoryInfo: Codable, Equatable {
        public let memTotal: Float
        public let memFree: Float
        public let memBuffers: Float
        public let memCached: Float
        public let swapTotal: Float
        public let swapFree: Float
        public let phyUsed: Float
        public let swapUsed: Float
        internal init() {
            memTotal = 0
            memFree = 0
            memBuffers = 0
            memCached = 0
            swapTotal = 0
            swapFree = 0
            phyUsed = 0
            swapUsed = 0
        }

        internal init(total: Float, free: Float, buffers: Float, cached: Float, swapTotal: Float, swapFree: Float) {
            memTotal = total.safeWrapper
            memFree = free.safeWrapper
            memBuffers = buffers.safeWrapper
            memCached = cached.safeWrapper
            self.swapTotal = swapTotal.safeWrapper
            self.swapFree = swapFree.safeWrapper
            if total != 0 {
                phyUsed = (
                    (total - free - memCached - memBuffers) / total
                ).safeWrapper
                swapUsed = (
                    (swapTotal - swapFree) / total
                ).safeWrapper
            } else {
                phyUsed = 0
                swapUsed = 0
            }
        }

        public func description() -> String {
            """
            total: \(Int(memTotal)) kB
            free: \(Int(memFree)) kB
            buffers: \(Int(memBuffers)) kB
            cached: \(Int(memCached)) kB
            swap: \(Int(swapFree))/\(Int(swapTotal)) kB
            """
        }
    }

    /// 服务器 NET 信息
    struct ServerNetworkInfo: Codable {
        public let device: String
        public let rxBytesPerSec: Int
        public let txBytesPerSec: Int

        internal init(device: String, rxBytesPerSec: Int, txBytesPerSec: Int) {
            self.device = device
            self.rxBytesPerSec = rxBytesPerSec
            self.txBytesPerSec = txBytesPerSec
        }

        public func description() -> String {
            """
            interface: \(device)
            rxBytes: \(rxBytesPerSec)/s txBytes: \(txBytesPerSec)/s
            """
        }
    }

    /// 服务器 文件系统 信息
    struct ServerFileSystemInfo: Codable {
        public let mountPoint: String
        public let usedBytes: Int
        public let freeBytes: Int
        public let usedPercent: Float

        internal init() {
            mountPoint = ""
            usedBytes = 0
            freeBytes = 0
            usedPercent = 0
        }

        internal init(mountPoint: String, free: Int, used: Int) {
            self.mountPoint = mountPoint
            usedBytes = used
            freeBytes = free
            if (free + used) != 0 {
                usedPercent = (
                    Float(used) / Float(free + used) * 100
                ).safeWrapper
            } else {
                usedPercent = 0
            }
        }

        public func description() -> String {
            """
            mount point: \(mountPoint)
            used: \(usedBytes) bytes free: \(freeBytes) bytes
            """
        }
    }

    /// 服务器 系统 信息
    struct ServerSystemInfo: Codable {
        public let releaseName: String
        public let uptimeSec: Int
        public let hostname: String
        public let runningProcs: Int
        public let totalProcs: Int
        public let load1: Float
        public let load5: Float
        public let load15: Float
        internal init() {
            releaseName = ""
            uptimeSec = 0
            hostname = ""
            runningProcs = 0
            totalProcs = 0
            load1 = 0
            load5 = 0
            load15 = 0
        }

        internal init(release: String,
                      uptimeInSec: Int, hostname: String,
                      runningProcs: Int, totalProcs: Int,
                      load1: Float, load5: Float, load15: Float)
        {
            releaseName = release
            uptimeSec = uptimeInSec
            self.hostname = hostname
            self.runningProcs = runningProcs
            self.totalProcs = totalProcs
            self.load1 = load1.safeWrapper
            self.load5 = load5.safeWrapper
            self.load15 = load15.safeWrapper
        }

        public func description() -> String {
            """
            release: \(releaseName)
            uptime: \(uptimeSec) second
            hostname: \(hostname)
            running process: \(runningProcs) total: \(totalProcs)
            load1: \(load1) load5: \(load5) load15: \(load15)
            """
        }
    }

    /// 服务器信息总集合
    struct ServerInfo: Codable {
        public let ServerProcessInfo: ServerProcessInfo
        public let ServerFileSystemInfo: [ServerFileSystemInfo]
        public let ServerMemoryInfo: ServerMemoryInfo
        public let ServerSystemInfo: ServerSystemInfo
        public let ServerNetworkInfo: [ServerNetworkInfo]
        /// 这个变量不是服务器数据获取的时间 不要开放咯
        private var compileAt = Date()

        internal init(ServerProcessInfo: PTServerManager.ServerProcessInfo,
                      ServerFileSystemInfo: [PTServerManager.ServerFileSystemInfo],
                      ServerMemoryInfo: PTServerManager.ServerMemoryInfo,
                      ServerSystemInfo: PTServerManager.ServerSystemInfo,
                      ServerNetworkInfo: [PTServerManager.ServerNetworkInfo])
        {
            self.ServerProcessInfo = ServerProcessInfo
            self.ServerFileSystemInfo = ServerFileSystemInfo
            self.ServerMemoryInfo = ServerMemoryInfo
            self.ServerSystemInfo = ServerSystemInfo
            self.ServerNetworkInfo = ServerNetworkInfo
        }

        public func description() -> String? {
            var sysSection = ""
            for item in ServerSystemInfo.description().components(separatedBy: "\n") {
                sysSection += "> \(item)\n"
            }

            var cpuSection = "> "
            cpuSection += ServerProcessInfo.summary.description()
            cpuSection += "\n"
            for key in ServerProcessInfo.cores.keys.sorted() {
                if let value = ServerProcessInfo.cores[key] {
                    cpuSection += "- [\(key)]\n- > "
                    cpuSection += value.description()
                    cpuSection += "\n"
                }
            }

            var ramSection = ""
            for item in ServerMemoryInfo.description().components(separatedBy: "\n") {
                ramSection += "> \(item)\n"
            }

            var netSection = ""
            for item in ServerNetworkInfo.sorted(by: { a, b -> Bool in
                a.device < b.device
            }) {
                let str = item.description()
                netSection += "> "
                for line in str.components(separatedBy: "\n") {
                    if !netSection.hasSuffix("> ") {
                        netSection += "  "
                    }
                    netSection += line
                    netSection += "\n"
                }
            }

            var fileSection = ""
            for item in ServerFileSystemInfo.sorted(by: { a, b -> Bool in
                if ServerInfoHumanReadable.filterIsMountPointRegular(str: a.mountPoint) {
                    if ServerInfoHumanReadable.filterIsMountPointRegular(str: b.mountPoint) {
                        return a.mountPoint < b.mountPoint // 都常规
                    } else {
                        return true // a 应该在前面 因为 b 不常规
                    }
                } else {
                    if ServerInfoHumanReadable.filterIsMountPointRegular(str: b.mountPoint) {
                        return false // a 应该在后面 应为 b 常规
                    } else {
                        return a.mountPoint < b.mountPoint // 都不常规
                    }
                }
            }) {
                fileSection += "> "
                if !ServerInfoHumanReadable.filterIsMountPointRegular(str: item.mountPoint) {
                    fileSection += "Irregular Mount Point\n"
                }
                for line in item.description().components(separatedBy: "\n") {
                    if !fileSection.hasSuffix("> ") {
                        fileSection += "  "
                    }
                    fileSection += line
                    fileSection += "\n"
                }
            }

            let final = """
            Server Raw Data - Generated by PillowTalk

            [MISC]
            \(sysSection)
            [CPU]
            \(cpuSection)
            [RAM]
            \(ramSection)
            [NET]
            \(netSection)
            [FileSystem]
            \(fileSection)
            ---
            \(DateFormatter.localizedString(from: compileAt, dateStyle: .long, timeStyle: .long))
            """
            return final
        }
    }

    /// 返回给 UI 的数据
    struct ServerInfoHumanReadable: PTUIRepresentable, Identifiable {
        public var id: UUID = .init()

        public var serverDescriptor: String

        public var serverTitle: String
        public var serverSubtitle: String
        public var updatedAt: Int
        public var newState: String
        public var cpuThreshold: Double
        public var ramThreshold: Double
        public var diskThreshold: Double
        public var rxBytes: Int
        public var txBytes: Int
        public var networkDescription: String

        public var lastUpdateFailed: Bool

        public static func filterIsMountPointRegular(str: String) -> Bool {
            if str.starts(with: "/var/lib/docker/overlay") {
                return false
            }
            if str.starts(with: "/var/lib/docker/containers") {
                return false
            }
            if str.starts(with: "/run") {
                return false
            }
            if str.starts(with: "/dev") {
                return false
            }
            if str.starts(with: "/snap") {
                return false
            }
            return true
        }

        public init(serverDescriptor key: String) {
            let server = PTServerManager.shared.obtainServer(withKey: key)
            let status = PTServerManager.shared.obtainServerStatus(withKey: key)

            self.init(serverObject: server, infoSet: status)
        }

        public init(serverObject: Server?, infoSet: ServerStatus?) {
            serverDescriptor = serverObject?.uuid ?? ""

            let server = serverObject
            let status = infoSet

            if status?.pendingUpdate ?? false {
                newState = "animatebleLoading"
            } else if status?.statusUpdated ?? false {
                newState = "normal"
            } else if status?.information != nil {
                newState = "outdate"
            } else {
                newState = "error"
            }

            lastUpdateFailed = status?.errorOccurred ?? false

            var diskPercent: Double?
            if let pmt = server?.obtainPreferredMountPoint() {
                inner: for item in status?.information?.ServerFileSystemInfo ?? [] where item.mountPoint == pmt {
                    diskPercent = Double(item.usedPercent) / 100
                    break inner
                }
                diskPercent = 0
            }
            if diskPercent == nil {
                var sumUsed: Double = 0
                var sumFree: Double = 0
                for item in status?.information?.ServerFileSystemInfo ?? [] where PTServerManager.ServerInfoHumanReadable.filterIsMountPointRegular(str: item.mountPoint) {
                    sumUsed += Double(item.usedBytes)
                    sumFree += Double(item.freeBytes)
                }
                let sum = sumUsed + sumFree
                if sum != 0 {
                    diskPercent = sumUsed / sum
                }
            }

            serverTitle = server?.obtainPossibleName() ?? server?.uuid ?? ""
            serverSubtitle = status?.information?.ServerSystemInfo.releaseName ?? ""

            var intotal = 0
            var outtotal = 0
            if let interface = server?.obtainPreferredNetworkInterface() {
                for item in status?.information?.ServerNetworkInfo ?? [] where item.device == interface {
                    intotal += item.rxBytesPerSec
                    outtotal += item.txBytesPerSec
                }
            } else {
                for item in status?.information?.ServerNetworkInfo ?? [] {
                    intotal += item.rxBytesPerSec
                    outtotal += item.txBytesPerSec
                }
            }
            txBytes = outtotal
            rxBytes = intotal
            var inoutTotal = intotal + outtotal

            let foo = ["B", "KB", "MB", "GB", "TB", "PB"]
            var levelR = 0
            var levelT = 0
            var levelA = 0
            while intotal >= 1000, levelR < foo.count - 1 {
                intotal /= 1000
                levelR += 1
            }
            while outtotal >= 1000, levelT < foo.count - 1 {
                outtotal /= 1000
                levelT += 1
            }
            while inoutTotal >= 1000, levelA < foo.count - 1 {
                inoutTotal /= 1000
                levelA += 1
            }
            networkDescription = "RX:\(intotal)\(foo[levelR])/s TX:\(outtotal)\(foo[levelT])/s"
            if serverSubtitle.count > 28 {
                serverSubtitle += " NET:\(inoutTotal)\(foo[levelA])/s"
            } else {
                serverSubtitle += " RX:\(intotal)\(foo[levelR])/s TX:\(outtotal)\(foo[levelT])/s"
            }
            while serverSubtitle.hasPrefix(" ") {
                serverSubtitle.removeFirst()
            }

            updatedAt = Int(status?.previousUpdate?.timeIntervalSince1970 ?? 0)
            cpuThreshold = (
                Double(status?.information?.ServerProcessInfo.summary.sumUsed ?? 0) / 100
            ).safeWrapper
            ramThreshold = (
                Double(status?.information?.ServerMemoryInfo.phyUsed ?? 0)
            ).safeWrapper
            diskThreshold = (diskPercent ?? 0).safeWrapper
        }
    }
}
