//
//  HardwareModel.swift
//  SwiftBonjour
//
//  Created by Rachel on 5/19/21.
//

#if os(macOS)
    import Foundation
    typealias HostClassType = Host
#else
    import UIKit
    typealias HostClassType = UIDevice
#endif

enum DeviceType {
    case unknown
    case ipodtouch
    case iphoneLegacy
    case iphone
    case ipadLegacy
    case ipad
    case appletv
    case applewatch
    case homepod
    case macbook
    case macmini
    case imac
    case macproGen1
    case macproGen2
    case macproGen3
    case macproGen3Server

    var symbolName: String {
        switch self {
        case .unknown:
            return "bonjour"
        case .ipodtouch:
            return "ipodtouch"
        case .iphone:
            return "iphone"
        case .iphoneLegacy:
            return "iphone.homebutton"
        case .ipad:
            return "ipad"
        case .ipadLegacy:
            return "ipad.homebutton"
        case .appletv:
            return "appletv"
        case .applewatch:
            return "applewatch"
        case .homepod:
            return "homepod"
        case .macbook:
            return "laptopcomputer"
        case .macmini:
            return "macmini"
        case .imac:
            return "desktopcomputer"
        case .macproGen1:
            return "macpro.gen1"
        case .macproGen2:
            return "macpro.gen2"
        case .macproGen3:
            return "macpro.gen3"
        case .macproGen3Server:
            return "macpro.gen3.server"
        }
    }
}

extension HostClassType {
    static let hardwareModel: String = {
        #if os(macOS)
            let service = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOPlatformExpertDevice"))
            defer { IOObjectRelease(service) }

            guard let modelData = IORegistryEntryCreateCFProperty(service, "model" as CFString, kCFAllocatorDefault, 0).takeRetainedValue() as? Data else {
                fatalError("IORegistryEntryCreateCFProperty")
            }
            return modelData.withUnsafeBytes { String(cString: ($0.baseAddress?.assumingMemoryBound(to: UInt8.self))!) }
        #else
            var systemInfo = utsname()
            uname(&systemInfo)
            let machineMirror = Mirror(reflecting: systemInfo.machine)
            let identifier = machineMirror.children.reduce("") { identifier, element in
                guard let value = element.value as? Int8, value != 0 else { return identifier }
                return identifier + String(UnicodeScalar(UInt8(value)))
            }
            return identifier
        #endif
    }()

    static func displayTypeForHardwareModel(_ identifier: String) -> DeviceType { // swiftlint:disable:this cyclomatic_complexity
        if identifier.hasPrefix("iMac") {
            return .imac
        } else if identifier.hasPrefix("Macmini") {
            return .macmini
        } else if identifier.hasPrefix("MacBook") {
            return .macbook
        } else if identifier.hasPrefix("MacPro1") || identifier.hasPrefix("MacPro2") || identifier.hasPrefix("MacPro3") || identifier.hasPrefix("MacPro4") {
            return .macproGen1
        } else if identifier.hasPrefix("MacPro5") || identifier.hasPrefix("MacPro6") {
            return .macproGen2
        } else if identifier.hasPrefix("MacPro7") {
            return .macproGen3
        }
        switch identifier {
        case "iPod5,1": return .ipodtouch
        case "iPod7,1": return .ipodtouch
        case "iPod9,1": return .ipodtouch
        case "iPhone3,1", "iPhone3,2", "iPhone3,3": return .iphoneLegacy
        case "iPhone4,1": return .iphoneLegacy
        case "iPhone5,1", "iPhone5,2": return .iphoneLegacy
        case "iPhone5,3", "iPhone5,4": return .iphoneLegacy
        case "iPhone6,1", "iPhone6,2": return .iphoneLegacy
        case "iPhone7,2": return .iphoneLegacy
        case "iPhone7,1": return .iphoneLegacy
        case "iPhone8,1": return .iphoneLegacy
        case "iPhone8,2": return .iphoneLegacy
        case "iPhone8,4": return .iphoneLegacy
        case "iPhone9,1", "iPhone9,3": return .iphoneLegacy
        case "iPhone9,2", "iPhone9,4": return .iphoneLegacy
        case "iPhone10,1", "iPhone10,4": return .iphoneLegacy
        case "iPhone10,2", "iPhone10,5": return .iphoneLegacy
        case "iPhone10,3", "iPhone10,6": return .iphone
        case "iPhone11,2": return .iphone
        case "iPhone11,4", "iPhone11,6": return .iphone
        case "iPhone11,8": return .iphone
        case "iPhone12,1": return .iphone
        case "iPhone12,3": return .iphone
        case "iPhone12,5": return .iphone
        case "iPhone12,8": return .iphoneLegacy
        case "iPhone13,1": return .iphone
        case "iPhone13,2": return .iphone
        case "iPhone13,3": return .iphone
        case "iPhone13,4": return .iphone
        case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4": return .ipadLegacy
        case "iPad3,1", "iPad3,2", "iPad3,3": return .ipadLegacy
        case "iPad3,4", "iPad3,5", "iPad3,6": return .ipadLegacy
        case "iPad6,11", "iPad6,12": return .ipadLegacy
        case "iPad7,5", "iPad7,6": return .ipadLegacy
        case "iPad7,11", "iPad7,12": return .ipadLegacy
        case "iPad11,6", "iPad11,7": return .ipadLegacy
        case "iPad4,1", "iPad4,2", "iPad4,3": return .ipadLegacy
        case "iPad5,3", "iPad5,4": return .ipadLegacy
        case "iPad11,3", "iPad11,4": return .ipadLegacy
        case "iPad13,1", "iPad13,2": return .ipad
        case "iPad2,5", "iPad2,6", "iPad2,7": return .ipadLegacy
        case "iPad4,4", "iPad4,5", "iPad4,6": return .ipadLegacy
        case "iPad4,7", "iPad4,8", "iPad4,9": return .ipadLegacy
        case "iPad5,1", "iPad5,2": return .ipadLegacy
        case "iPad11,1", "iPad11,2": return .ipadLegacy
        case "iPad6,3", "iPad6,4": return .ipadLegacy
        case "iPad7,3", "iPad7,4": return .ipadLegacy
        case "iPad8,1", "iPad8,2", "iPad8,3", "iPad8,4": return .ipad
        case "iPad8,9", "iPad8,10": return .ipad
        case "iPad6,7", "iPad6,8": return .ipad
        case "iPad7,1", "iPad7,2": return .ipad
        case "iPad8,5", "iPad8,6", "iPad8,7", "iPad8,8": return .ipad
        case "iPad8,11", "iPad8,12": return .ipad
        case "AppleTV5,3": return .appletv
        case "AppleTV6,2": return .appletv
        case "AudioAccessory1,1": return .homepod
        case "AudioAccessory5,1": return .homepod
        case "i386", "x86_64": return .unknown
        default: return .unknown
        }
    }

    static let displayDeviceType: DeviceType = {
        displayTypeForHardwareModel(hardwareModel)
    }()

    static func displayNameForHardwareModel(_ identifier: String) -> String { // swiftlint:disable:this cyclomatic_complexity
        switch identifier {
        case "iPod5,1": return "iPod touch (5th generation)"
        case "iPod7,1": return "iPod touch (6th generation)"
        case "iPod9,1": return "iPod touch (7th generation)"
        case "iPhone3,1", "iPhone3,2", "iPhone3,3": return "iPhone 4"
        case "iPhone4,1": return "iPhone 4s"
        case "iPhone5,1", "iPhone5,2": return "iPhone 5"
        case "iPhone5,3", "iPhone5,4": return "iPhone 5c"
        case "iPhone6,1", "iPhone6,2": return "iPhone 5s"
        case "iPhone7,2": return "iPhone 6"
        case "iPhone7,1": return "iPhone 6 Plus"
        case "iPhone8,1": return "iPhone 6s"
        case "iPhone8,2": return "iPhone 6s Plus"
        case "iPhone8,4": return "iPhone SE"
        case "iPhone9,1", "iPhone9,3": return "iPhone 7"
        case "iPhone9,2", "iPhone9,4": return "iPhone 7 Plus"
        case "iPhone10,1", "iPhone10,4": return "iPhone 8"
        case "iPhone10,2", "iPhone10,5": return "iPhone 8 Plus"
        case "iPhone10,3", "iPhone10,6": return "iPhone X"
        case "iPhone11,2": return "iPhone XS"
        case "iPhone11,4", "iPhone11,6": return "iPhone XS Max"
        case "iPhone11,8": return "iPhone XR"
        case "iPhone12,1": return "iPhone 11"
        case "iPhone12,3": return "iPhone 11 Pro"
        case "iPhone12,5": return "iPhone 11 Pro Max"
        case "iPhone12,8": return "iPhone SE (2nd generation)"
        case "iPhone13,1": return "iPhone 12 mini"
        case "iPhone13,2": return "iPhone 12"
        case "iPhone13,3": return "iPhone 12 Pro"
        case "iPhone13,4": return "iPhone 12 Pro Max"
        case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4": return "iPad 2"
        case "iPad3,1", "iPad3,2", "iPad3,3": return "iPad (3rd generation)"
        case "iPad3,4", "iPad3,5", "iPad3,6": return "iPad (4th generation)"
        case "iPad6,11", "iPad6,12": return "iPad (5th generation)"
        case "iPad7,5", "iPad7,6": return "iPad (6th generation)"
        case "iPad7,11", "iPad7,12": return "iPad (7th generation)"
        case "iPad11,6", "iPad11,7": return "iPad (8th generation)"
        case "iPad4,1", "iPad4,2", "iPad4,3": return "iPad Air"
        case "iPad5,3", "iPad5,4": return "iPad Air 2"
        case "iPad11,3", "iPad11,4": return "iPad Air (3rd generation)"
        case "iPad13,1", "iPad13,2": return "iPad Air (4th generation)"
        case "iPad2,5", "iPad2,6", "iPad2,7": return "iPad mini"
        case "iPad4,4", "iPad4,5", "iPad4,6": return "iPad mini 2"
        case "iPad4,7", "iPad4,8", "iPad4,9": return "iPad mini 3"
        case "iPad5,1", "iPad5,2": return "iPad mini 4"
        case "iPad11,1", "iPad11,2": return "iPad mini (5th generation)"
        case "iPad6,3", "iPad6,4": return "iPad Pro (9.7-inch)"
        case "iPad7,3", "iPad7,4": return "iPad Pro (10.5-inch)"
        case "iPad8,1", "iPad8,2", "iPad8,3", "iPad8,4": return "iPad Pro (11-inch) (1st generation)"
        case "iPad8,9", "iPad8,10": return "iPad Pro (11-inch) (2nd generation)"
        case "iPad6,7", "iPad6,8": return "iPad Pro (12.9-inch) (1st generation)"
        case "iPad7,1", "iPad7,2": return "iPad Pro (12.9-inch) (2nd generation)"
        case "iPad8,5", "iPad8,6", "iPad8,7", "iPad8,8": return "iPad Pro (12.9-inch) (3rd generation)"
        case "iPad8,11", "iPad8,12": return "iPad Pro (12.9-inch) (4th generation)"
        case "AppleTV5,3": return "Apple TV"
        case "AppleTV6,2": return "Apple TV 4K"
        case "AudioAccessory1,1": return "HomePod"
        case "AudioAccessory5,1": return "HomePod mini"
        case "i386", "x86_64": return "Simulator \(displayNameForHardwareModel(ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] ?? "iOS"))"
        default: return identifier
        }
    }

    static let displayHardwareModel: String = {
        displayNameForHardwareModel(hardwareModel)
    }()
}
