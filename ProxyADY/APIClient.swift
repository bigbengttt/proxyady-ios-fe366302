import Foundation
import UIKit
import Security
import Darwin
import MachO

struct LicenseResponse {
    let success: Bool
    let message: String
    let error: String?
    let data: LicenseData?
}

struct LicenseData {
    let key: String
    let ip: String
    let expiresAt: String
    let sessionExpiresAt: String
    let timeLeft: Int
    let proxyHost: String
    let proxyPort: String
}

enum APIClient {
    private static let savedKeyStorage = "proxyady_saved_key"
    private static let keychainService = "com.proxyady.secure"
    private static let keychainAccount = "license_key"

    static var savedKey: String? {
        if let key = KeychainStore.read(service: keychainService, account: keychainAccount) {
            let v = key.trimmingCharacters(in: .whitespacesAndNewlines)
            return v.isEmpty ? nil : v
        }
        let legacy = UserDefaults.standard.string(forKey: savedKeyStorage)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !legacy.isEmpty { saveKey(legacy) }
        return legacy.isEmpty ? nil : legacy
    }

    static func saveKey(_ key: String) {
        let clean = key.trimmingCharacters(in: .whitespacesAndNewlines)
        KeychainStore.save(clean, service: keychainService, account: keychainAccount)
        UserDefaults.standard.removeObject(forKey: savedKeyStorage)
    }

    static func clearSavedKey() {
        KeychainStore.delete(service: keychainService, account: keychainAccount)
        UserDefaults.standard.removeObject(forKey: savedKeyStorage)
    }
    private static var remoteConfig = RemoteAppConfig.fallback
    static var config: RemoteAppConfig { remoteConfig }
    static var displayName: String { remoteConfig.appName.isEmpty ? AppConfig.appName : remoteConfig.appName }

    static func loadOnlineConfig(completion: @escaping (RemoteAppConfig) -> Void) {
        let now = String(Int(Date().timeIntervalSince1970))
        var bindComponents = URLComponents(url: AppConfig.ipaBindURL, resolvingAgainstBaseURL: false)
        bindComponents?.queryItems = [
            URLQueryItem(name: "config", value: "1"),
            URLQueryItem(name: "t", value: now)
        ]

        let endpoints: [URL] = [
            bindComponents?.url ?? AppConfig.ipaBindURL,
            AppConfig.designURL,
            AppConfig.portsURL,
            AppConfig.securityURL
        ]

        let group = DispatchGroup()
        let lock = NSLock()
        var merged: [String: Any] = [:]

        for url in endpoints {
            group.enter()
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.timeoutInterval = 8
            request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")

            URLSession.shared.dataTask(with: request) { data, _, _ in
                defer { group.leave() }
                guard let data = data,
                      let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }
                let payload = (root["data"] as? [String: Any]) ?? root
                lock.lock()
                merged.merge(payload) { _, new in new }
                lock.unlock()
            }.resume()
        }

        group.notify(queue: .main) {
            remoteConfig = parseConfig(merged)
            completion(remoteConfig)
        }
    }

    static func validateKey(_ key: String, completion: @escaping (LicenseResponse) -> Void) {
        guard DeviceIntegrity.isAllowed else {
            clearSavedKey()
            completion(LicenseResponse(success: false, message: "Ambiente não permitido", error: "DEVICE_BLOCKED", data: nil))
            return
        }
        loadOnlineConfig { _ in
            var request = URLRequest(url: AppConfig.ipaBindURL)
            request.httpMethod = "POST"
            request.timeoutInterval = 15
            request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")

            let body: [String: Any] = [
                "action": "bind",
                "key": key.trimmingCharacters(in: .whitespacesAndNewlines),
                "device_id": UIDevice.current.identifierForVendor?.uuidString ?? "",
                "device_model": UIDevice.current.model,
                "bundle": Bundle.main.bundleIdentifier ?? ""
            ]
            request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])

            URLSession.shared.dataTask(with: request) { data, _, error in
                if let error = error {
                    DispatchQueue.main.async {
                        completion(LicenseResponse(success: false, message: "Falha de conexão", error: error.localizedDescription, data: nil))
                    }
                    return
                }
                guard let data = data,
                      let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    DispatchQueue.main.async {
                        completion(LicenseResponse(success: false, message: "Resposta inválida da VPS", error: "INVALID_JSON", data: nil))
                    }
                    return
                }
                let success = (root["success"] as? Bool) ?? false
                let message = (root["message"] as? String) ?? (success ? "Key aprovada" : "Key recusada")
                let errorText = root["error"] as? String
                let payload = root["data"] as? [String: Any]
                let proxy = payload?["proxy"] as? [String: Any]
                let timeLeft = (payload?["time_left"] as? Int) ?? (root["time_left"] as? Int) ?? remoteConfig.sessionTimeoutSeconds
                let license = LicenseData(
                    key: (payload?["key"] as? String) ?? (root["key"] as? String) ?? key,
                    ip: (payload?["ip"] as? String) ?? (root["ip"] as? String) ?? "",
                    expiresAt: (payload?["expires_at"] as? String) ?? (root["expires_at"] as? String) ?? "",
                    sessionExpiresAt: (payload?["session_expires_at"] as? String) ?? (root["session_expires_at"] as? String) ?? "",
                    timeLeft: timeLeft,
                    proxyHost: (proxy?["host"] as? String) ?? (root["host"] as? String) ?? remoteConfig.proxyHost,
                    proxyPort: String(describing: proxy?["port"] ?? root["port"] ?? remoteConfig.proxyPort)
                )
                DispatchQueue.main.async {
                    if success { saveKey(key) } else { clearSavedKey() }
                    completion(LicenseResponse(success: success, message: message, error: errorText, data: success ? license : nil))
                }
            }.resume()
        }
    }

    static func sendHeartbeat(completion: ((Bool) -> Void)? = nil) {
        closeAppIfSavedKeyInvalid()
        completion?(true)
    }

    static func startHeartbeat() {
        closeAppIfSavedKeyInvalid()
    }

    static func deactivate(completion: ((Bool) -> Void)? = nil) { completion?(true) }

    static func closeAppIfSavedKeyInvalid() {
        guard let key = savedKey else { return }
        validateKey(key) { response in
            if !response.success {
                clearSavedKey()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    exit(0)
                }
            }
        }
    }

    private static func parseConfig(_ payload: [String: Any]) -> RemoteAppConfig {
        let data = (payload["data"] as? [String: Any]) ?? payload
        let theme = data["theme"] as? [String: Any]
        let colors = data["colors"] as? [String: Any]
        let texts = data["texts"] as? [String: Any]
        let fb = RemoteAppConfig.fallback
        let ui = data["ui"] as? [String: Any]
        return RemoteAppConfig(
            appName: str(data["app_name"]) ?? str(data["name"]) ?? fb.appName,
            subtitle: str(texts?["subtitle"]) ?? str(data["subtitle"]) ?? fb.subtitle,
            instructionText: str(texts?["instruction_login"]) ?? str(texts?["login_title"]) ?? str(ui?["instruction_text"]) ?? fb.instructionText,
            inputPlaceholder: str(texts?["input_placeholder"]) ?? str(ui?["input_placeholder"]) ?? fb.inputPlaceholder,
            connectButtonTitle: str(texts?["connect_button"]) ?? str(ui?["connect_button_title"]) ?? fb.connectButtonTitle,
            pasteButtonTitle: str(texts?["paste_button"]) ?? str(ui?["paste_button_title"]) ?? fb.pasteButtonTitle,
            backgroundColorHex: str(colors?["background"]) ?? str(colors?["screen_bg"]) ?? str(theme?["background_color"]) ?? fb.backgroundColorHex,
            primaryColorHex: str(colors?["primary"]) ?? str(theme?["primary_color"]) ?? str(theme?["glow_color"]) ?? fb.primaryColorHex,
            primaryDarkColorHex: str(colors?["primary_dark"]) ?? str(colors?["button_gradient_1"]) ?? fb.primaryDarkColorHex,
            cardColorHex: str(colors?["card_bg"]) ?? fb.cardColorHex,
            inputColorHex: str(colors?["input_bg"]) ?? fb.inputColorHex,
            textColorHex: str(colors?["text_primary"]) ?? str(theme?["title_color"]) ?? fb.textColorHex,
            mutedTextColorHex: str(colors?["text_secondary"]) ?? str(theme?["text_color"]) ?? fb.mutedTextColorHex,
            showLogo: bool(ui?["show_logo"]) ?? fb.showLogo,
            showTitle: bool(ui?["show_title"]) ?? fb.showTitle,
            showSubtitle: bool(ui?["show_subtitle"]) ?? fb.showSubtitle,
            showSecurityCard: bool(ui?["show_security_card"]) ?? fb.showSecurityCard,
            showPasteButton: bool(ui?["show_paste_button"]) ?? fb.showPasteButton,
            topPadding: int(ui?["top_padding"]) ?? fb.topPadding,
            logoHeight: int(ui?["logo_height"]) ?? fb.logoHeight,
            fieldHeight: int(ui?["field_height"]) ?? fb.fieldHeight,
            buttonHeight: int(ui?["button_height"]) ?? fb.buttonHeight,
            proxyHost: str(data["proxy_host"]) ?? str(data["host"]) ?? fb.proxyHost,
            proxyPort: str(data["default_port"]) ?? str(data["port"]) ?? fb.proxyPort,
            sessionTimeoutSeconds: int(data["session_timeout_seconds"]) ?? fb.sessionTimeoutSeconds,
            successTitle: str(data["success_title"]) ?? str(data["title"]) ?? str(data["app_name"]) ?? fb.successTitle,
            successStatus: str(data["success_status"]) ?? str(data["welcome_title"]) ?? fb.successStatus,
            ports: stringArray(data["ports"]) ?? fb.ports,
            showCertificateButton: bool(data["show_certificate"]) ?? bool(data["show_certificate_button"]) ?? fb.showCertificateButton,
            certificateURL: str(data["certificate_url"]) ?? fb.certificateURL,
            successCopyButtonTitle: str(data["copy_button_text"]) ?? str(data["button_text"]) ?? str(ui?["copy_button_text"]) ?? fb.successCopyButtonTitle,
            successCertificateButtonTitle: str(data["certificate_button_text"]) ?? str(ui?["certificate_button_text"]) ?? fb.successCertificateButtonTitle,
            successBackgroundImage: str(data["success_background_image"]) ?? fb.successBackgroundImage,
            successBackgroundURL: str(data["success_background_url"]) ?? str(data["background_url"]) ?? str(ui?["background_url"]) ?? fb.successBackgroundURL,
            particlesEnabled: bool(data["particles"]) ?? bool(data["particles_enabled"]) ?? bool(ui?["particles"]) ?? fb.particlesEnabled,
            particleColorHex: str(data["particle_color"]) ?? str(colors?["particle_color"]) ?? str(colors?["particle"]) ?? str(colors?["primary"]) ?? fb.particleColorHex,
            logoURL: str(data["logo_url"]) ?? str(data["logo"]) ?? str(ui?["logo_url"]) ?? fb.logoURL,
            backgroundURL: str(data["login_background_url"]) ?? str(data["background_url"]) ?? str(ui?["background_url"]) ?? fb.backgroundURL,
            particleImageURL: str(data["particle_image_url"]) ?? str(data["animation_image_url"]) ?? str(ui?["particle_image_url"]) ?? fb.particleImageURL,
            particleMode: str(data["particle_mode"]) ?? str(data["particle_type"]) ?? str(ui?["particle_mode"]) ?? fb.particleMode,
            particleBirthRate: int(data["particle_birth_rate"]) ?? int(data["particle_rate"]) ?? int(ui?["particle_birth_rate"]) ?? fb.particleBirthRate,
            dynamicButtons: buttonArray(data["buttons"]) ?? buttonArray(ui?["buttons"]) ?? fb.dynamicButtons
        )
    }

    private static func str(_ value: Any?) -> String? {
        if let s = value as? String { return s }
        if let i = value as? Int { return String(i) }
        return nil
    }

    private static func int(_ value: Any?) -> Int? {
        if let i = value as? Int { return i }
        if let s = value as? String { return Int(s) }
        return nil
    }

    private static func stringArray(_ value: Any?) -> [String]? {
        if let arr = value as? [String] { return arr }
        if let arr = value as? [[String: Any]] {
            return arr.compactMap { item in
                if let text = item["text"] as? String { return text }
                if let port = item["port"] { return "\(port) = \(item["name"] ?? item["label"] ?? "")" }
                return nil
            }
        }
        return nil
    }

    private static func buttonArray(_ value: Any?) -> [DynamicButtonConfig]? {
        guard let arr = value as? [[String: Any]] else { return nil }
        let buttons = arr.compactMap { item -> DynamicButtonConfig? in
            guard let title = str(item["title"]) ?? str(item["text"]),
                  let url = str(item["url"]) ?? str(item["link"]),
                  !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  !url.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
            return DynamicButtonConfig(
                title: title,
                url: url,
                colorHex: str(item["color"]) ?? str(item["background"]) ?? "",
                textColorHex: str(item["text_color"]) ?? "#ffffff"
            )
        }
        return buttons
    }

    private static func bool(_ value: Any?) -> Bool? {
        if let b = value as? Bool { return b }
        if let i = value as? Int { return i != 0 }
        if let s = value as? String {
            let v = s.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            if ["1", "true", "yes", "sim", "on"].contains(v) { return true }
            if ["0", "false", "no", "nao", "não", "off"].contains(v) { return false }
        }
        return nil
    }
}


enum KeychainStore {
    static func save(_ value: String, service: String, account: String) {
        delete(service: service, account: account)
        guard let data = value.data(using: .utf8) else { return }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        SecItemAdd(query as CFDictionary, nil)
    }

    static func read(service: String, account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func delete(service: String, account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}

enum DeviceIntegrity {
    static var isAllowed: Bool {
        // Liberado: não bloquear TrollStore, jailbreak ou ambiente modificado.
        return true
    }
}
