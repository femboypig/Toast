import Foundation
import UIKit
import SwiftSignalKit
import TelegramCore
import Postbox

private func hexStringToData(_ hex: String) -> Data? {
    var data = Data(capacity: hex.count / 2)
    var index = hex.startIndex
    while index < hex.endIndex {
        let nextIndex = hex.index(index, offsetBy: 2, limitedBy: hex.endIndex) ?? hex.endIndex
        let byteString = String(hex[index..<nextIndex])
        if let byte = UInt8(byteString, radix: 16) {
            data.append(byte)
        } else {
            return nil
        }
        index = nextIndex
    }
    return data
}

private extension fd_set {
    mutating func zero() {
        self = fd_set()
    }
    mutating func set(_ fd: Int32) {
        let intOffset = Int(fd / 32)
        let bitOffset = fd % 32
        withUnsafeMutablePointer(to: &self) { ptr in
            let rawPtr = UnsafeMutableRawPointer(ptr).assumingMemoryBound(to: Int32.self)
            rawPtr[intOffset] |= (1 << bitOffset)
        }
    }
}

public final class ToastAntiCensorship {
    public static let shared = ToastAntiCensorship()

    private let queue = DispatchQueue(label: "org.toast.antiCensorship", qos: .utility)
    private var accountManager: AccountManager<TelegramAccountManagerTypes>?
    private var isChecking = false
    private var lastFailoverTime: CFAbsoluteTime = 0.0

    private struct BuiltInProxy {
        let host: String
        let port: Int32
        let secretHex: String
        let tag: String
    }

    private let defaultProxies: [BuiltInProxy] = [
        BuiltInProxy(
            host: "149.154.175.50",
            port: 443,
            secretHex: "ee000000000000000000000000000000007777772e676f6f676c652e636f6d",
            tag: "Toast_BuiltIn_Google"
        ),
        BuiltInProxy(
            host: "91.108.56.170",
            port: 443,
            secretHex: "ee000000000000000000000000000000007777772e636c6f7564666c6172652e636f6d",
            tag: "Toast_BuiltIn_Cloudflare"
        ),
        BuiltInProxy(
            host: "149.154.167.51",
            port: 443,
            secretHex: "ee0000000000000000000000000000000079616e6465782e7275",
            tag: "Toast_BuiltIn_Yandex"
        ),
        BuiltInProxy(
            host: "91.108.4.155",
            port: 443,
            secretHex: "ee000000000000000000000000000000007777772e6d6963726f736f66742e636f6d",
            tag: "Toast_BuiltIn_Microsoft"
        ),
        BuiltInProxy(
            host: "91.108.8.10",
            port: 443,
            secretHex: "ee000000000000000000000000000000007777772e6170706c652e636f6d",
            tag: "Toast_BuiltIn_Apple"
        )
    ]

    private init() {}

    public func configure(accountManager: AccountManager<TelegramAccountManagerTypes>) {
        self.accountManager = accountManager
        self.applyCurrentLevel()
    }

    public func applyCurrentLevel() {
        self.queue.async {
            let level = ToastSettings.shared.bypassLevel
            guard let accountManager = self.accountManager else { return }

            if level == .max {
                self.performHealthCheckAndFailover(force: false)
            } else {
                // Disable built-in proxy if active
                let _ = updateProxySettingsInteractively(accountManager: accountManager, { current in
                    guard let active = current.activeServer else { return current }
                    let isBuiltIn = self.defaultProxies.contains(where: { $0.host == active.host && $0.port == active.port })
                    if isBuiltIn {
                        var updated = current
                        updated.enabled = false
                        return updated
                    }
                    return current
                }).start()
            }
        }
    }

    public func reportConnectionFailure() {
        self.queue.async {
            guard ToastSettings.shared.bypassLevel == .max else { return }
            let now = CFAbsoluteTimeGetCurrent()
            if now - self.lastFailoverTime > 10.0 {
                self.lastFailoverTime = now
                self.performHealthCheckAndFailover(force: true)
            }
        }
    }

    private func performHealthCheckAndFailover(force: Bool) {
        guard !self.isChecking else { return }
        self.isChecking = true

        let proxies = self.defaultProxies
        let group = DispatchGroup()
        var latencies: [(BuiltInProxy, Double)] = []
        let lock = NSLock()

        for proxy in proxies {
            group.enter()
            self.pingProxy(host: proxy.host, port: proxy.port) { latency in
                if let latency = latency {
                    lock.lock()
                    latencies.append((proxy, latency))
                    lock.unlock()
                }
                group.leave()
            }
        }

        group.notify(queue: self.queue) { [weak self] in
            guard let self = self, let accountManager = self.accountManager else { return }
            self.isChecking = false

            latencies.sort(by: { $0.1 < $1.1 })
            guard let best = latencies.first?.0 ?? proxies.first else { return }
            guard let secretData = hexStringToData(best.secretHex) else { return }

            let targetServer = ProxyServerSettings(
                host: best.host,
                port: best.port,
                connection: .mtp(secret: secretData)
            )

            let _ = updateProxySettingsInteractively(accountManager: accountManager, { current in
                var updated = current
                var servers = updated.servers

                if !servers.contains(where: { $0.host == targetServer.host && $0.port == targetServer.port }) {
                    servers.insert(targetServer, at: 0)
                }
                updated.servers = servers
                updated.activeServer = targetServer
                updated.enabled = true
                return updated
            }).start()
        }
    }

    private func pingProxy(host: String, port: Int32, completion: @escaping (Double?) -> Void) {
        DispatchQueue.global(qos: .utility).async {
            let startTime = CFAbsoluteTimeGetCurrent()
            var hints = addrinfo()
            hints.ai_family = AF_INET
            hints.ai_socktype = SOCK_STREAM

            var res: UnsafeMutablePointer<addrinfo>?
            let portString = "\(port)"
            guard getaddrinfo(host, portString, &hints, &res) == 0, let addr = res else {
                completion(nil)
                return
            }
            defer { freeaddrinfo(res) }

            let sock = socket(addr.pointee.ai_family, addr.pointee.ai_socktype, addr.pointee.ai_protocol)
            guard sock >= 0 else {
                completion(nil)
                return
            }
            defer { close(sock) }

            let flags = fcntl(sock, F_GETFL, 0)
            let _ = fcntl(sock, F_SETFL, flags | O_NONBLOCK)

            let connectRes = connect(sock, addr.pointee.ai_addr, addr.pointee.ai_addrlen)
            if connectRes == 0 {
                let elapsed = (CFAbsoluteTimeGetCurrent() - startTime) * 1000.0
                completion(elapsed)
                return
            }

            var fdSet = fd_set()
            fdSet.zero()
            fdSet.set(sock)
            var tv = timeval(tv_sec: 1, tv_usec: 500000) // 1.5 seconds

            let selectRes = select(sock + 1, nil, &fdSet, nil, &tv)
            if selectRes > 0 {
                var err: Int32 = 0
                var len = socklen_t(MemoryLayout<Int32>.size)
                getsockopt(sock, SOL_SOCKET, SO_ERROR, &err, &len)
                if err == 0 {
                    let elapsed = (CFAbsoluteTimeGetCurrent() - startTime) * 1000.0
                    completion(elapsed)
                    return
                }
            }
            completion(nil)
        }
    }
}
