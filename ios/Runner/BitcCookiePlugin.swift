import Flutter
import Foundation
import WebKit

final class BitcCookiePlugin: NSObject, FlutterPlugin {
  private static let channelName = "schedulr/bitc_cookie"
  private static let pluginKey = "SchedulrBitcCookiePlugin"
  private let store = WKWebsiteDataStore.default().httpCookieStore

  static func register(with registry: FlutterPluginRegistry) {
    guard let registrar = registry.registrar(forPlugin: pluginKey) else { return }
    register(with: registrar)
  }

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: registrar.messenger())
    let instance = BitcCookiePlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "readCookies":
      store.getAllCookies { [weak self] cookies in
        guard let self else { return }
        let values = cookies.filter { self.isAllowed($0.domain) }.map(self.serialize)
        result(values)
      }
    case "writeCookies":
      guard let arguments = call.arguments as? [String: Any],
            let rawCookies = arguments["cookies"] as? [[String: Any]] else {
        result(FlutterError(code: "invalid_cookies", message: "cookies must be a list", details: nil))
        return
      }
      let cookies = rawCookies.compactMap { [weak self] value in self?.deserialize(value) }
      guard cookies.count == rawCookies.count else {
        result(FlutterError(code: "invalid_cookies", message: "cookie fields are invalid", details: nil))
        return
      }
      let group = DispatchGroup()
      cookies.forEach { cookie in
        group.enter()
        store.setCookie(cookie) { group.leave() }
      }
      group.notify(queue: .main) { result(nil) }
    case "clearCookies":
      store.getAllCookies { [weak self] cookies in
        guard let self else { return }
        let target = cookies.filter { self.isAllowed($0.domain) }
        let group = DispatchGroup()
        target.forEach { cookie in
          group.enter()
          self.store.delete(cookie) { group.leave() }
        }
        group.notify(queue: .main) { result(nil) }
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func isAllowed(_ domain: String) -> Bool {
    let host = domain.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "."))
    return host == "bitc.edu.cn" || host.hasSuffix(".bitc.edu.cn")
  }

  private func serialize(_ cookie: HTTPCookie) -> [String: Any] {
    var value: [String: Any] = [
      "name": cookie.name,
      "value": cookie.value,
      "domain": cookie.domain,
      "path": cookie.path,
      "secure": cookie.isSecure,
      "httpOnly": cookie.isHTTPOnly,
    ]
    if let expires = cookie.expiresDate {
      value["expiresAt"] = expires.timeIntervalSince1970
    }
    return value
  }

  private func deserialize(_ raw: [String: Any]) -> HTTPCookie? {
    guard let name = raw["name"] as? String,
          let value = raw["value"] as? String,
          let domain = raw["domain"] as? String,
          let path = raw["path"] as? String,
          isAllowed(domain) else { return nil }
    var properties: [HTTPCookiePropertyKey: Any] = [
      .name: name,
      .value: value,
      .domain: domain,
      .path: path,
    ]
    if let secure = raw["secure"] as? Bool, secure { properties[.secure] = "TRUE" }
    if let expiresAt = raw["expiresAt"] as? NSNumber {
      properties[.expires] = Date(timeIntervalSince1970: expiresAt.doubleValue)
    }
    return HTTPCookie(properties: properties)
  }
}
