//
//  PTCodeClipManager+BuiltIn.swift
//  PTFoundation
//
//  Created by Lakr Aream on 1/20/21.
//

import Foundation

private let imageDocker = "data:image/png;base64, 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"

#if DEBUG
    fileprivate let imageBug = "data:image/png;base64, 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"
#endif

private var buildinClips: [CodeClip]?

public extension PTCodeClipManager {
    /// 获取内建代码捷径
    /// - Returns: 一些代码捷径
    func obtainBuiltinCodeClips() -> [CodeClip] {
        if let ret = buildinClips { return ret }

        var build = [CodeClip]()

        do {
            let clip = CodeClip(name: "docker ps", icon: imageDocker, code:
                """
                docker ps
                """, section: "Builtin", timeout: -1, executor: .bash, target: .remote)
            build.append(clip)
        }

        do {
            let clip = CodeClip(name: "docker prune all", icon: imageDocker, code:
                """
                docker system prune -a -f
                """, section: "Builtin", timeout: -1, executor: .bash, target: .remote)
            build.append(clip)
        }

        do {
            let clip = CodeClip(name: "docker pull all", icon: imageDocker, code:
                """
                docker images | grep -v ^REPO | sed 's/ \\+/:/g' | cut -d: -f1,2 | xargs -L1 docker pull
                """, section: "Builtin", timeout: -1, executor: .bash, target: .remote)
            build.append(clip)
        }

        do {
            let clip = CodeClip(name: "Determine IP", code:
                """
                curl ip.gs
                """, section: "Builtin", timeout: -1, executor: .bash, target: .remote)
            build.append(clip)
        }

        do {
            let clip = CodeClip(name: "List Processes", code:
                """
                ps aux
                """, section: "Builtin", timeout: -1, executor: .bash, target: .remote)
            build.append(clip)
        }

        do {
            let clip = CodeClip(name: "List Zombie", code:
                """
                echo "[*] Finding Zombie..."
                for pid in $(ps axo pid=,stat= | awk '$2~/^Z/ { print $1 }') ; do
                    echo "[*] Zombie with PID: $pid"
                    echo "    $(ps -p $pid -o comm=)"
                    echo "    $(pstree -p -s $pid)"
                done
                echo "[*] Done"
                """, section: "Builtin", timeout: -1, executor: .bash, target: .remote)
            build.append(clip)
        }

        do {
            let clip = CodeClip(name: "apt upgrade", code:
                """
                if (( $EUID != 0 )); then
                    echo "[E] Permission Denied"
                    echo "[i] Please execute this code clip with root"
                    exit -1
                fi
                echo "[*] Updating Metadata..."
                apt update
                echo "[*] Upgrading System..."
                apt upgrade -y
                echo "[*] Done"
                """, section: "Builtin", timeout: -1, executor: .bash, target: .remote)
            build.append(clip)
        }

        do {
            let clip = CodeClip(name: "apt autoremove", code:
                """
                if (( $EUID != 0 )); then
                    echo "[E] Permission Denied"
                    echo "[i] Please execute this code clip with root"
                    exit -1
                fi
                echo "[*] Cleaning System..."
                apt autoremove -y
                echo "[*] Done"
                """, section: "Builtin", timeout: -1, executor: .bash, target: .remote)
            build.append(clip)
        }

        #if DEBUG
            do {
                let clip = CodeClip(name: "COLOR TEST", icon: imageBug, code:
                    """
                    #!/bin/bash
                    apt update -y
                    apt install nodejs npm -y
                    npm install -g colortest
                    colortest
                    """, section: "Builtin", timeout: -1, executor: .bash, target: .remote)
                build.append(clip)
            }
            do {
                let clip = CodeClip(name: "KILL TEST", icon: imageBug, code:
                    """
                    apt update -y
                    apt update -y
                    apt update -y
                    apt update -y
                    apt update -y
                    apt update -y
                    apt update -y
                    apt update -y
                    apt update -y
                    apt update -y
                    apt update -y
                    apt update -y
                    apt update -y
                    apt update -y
                    apt update -y
                    apt update -y
                    """, section: "Builtin", timeout: -1, executor: .bash, target: .remote)
                build.append(clip)
            }

            do {
                let clip = CodeClip(name: "LemonBench", icon: imageBug, code:
                    """
                    if (( $EUID != 0 )); then
                        echo "[E] Permission Denied"
                        echo "[i] Please execute this code clip with root"
                        exit -1
                    fi
                    echo "[*] Installing curl"
                    apt update
                    apt install curl -y
                    echo "[*] Loading LemonBench..."
                    curl -fsL https://ilemonra.in/LemonBenchIntl | bash -s fast
                    echo "[*] Done"
                    """, section: "Builtin", timeout: -1, executor: .bash, target: .remote)
                build.append(clip)
            }
        #endif

        buildinClips = build

        return build
    }
}
