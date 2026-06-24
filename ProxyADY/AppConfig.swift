import Foundation
import UIKit

struct AppConfig {
    static let appName = "Proxy"
    static let ipaBindURL = URL(string: SecureText.endpoint())!
    static let designURL = SecureText.apiURL(SecureText.fileDesign())
    static let portsURL = SecureText.apiURL(SecureText.filePorts())
    static let securityURL = SecureText.apiURL(SecureText.fileSecurity())
}

enum SecureText {
    private static func x(_ bytes: [UInt8], _ key: UInt8) -> String {
        String(bytes: bytes.map { $0 ^ key }, encoding: .utf8) ?? ""
    }
    static func endpoint() -> String {
        x([33,61,61,57,115,102,102,120,112,120,103,123,124,123,103,123,120,121,103,120,121,112,102,40,57,32,102,32,57,40,22,43,32,39,45,103,57,33,57], 73)
    }
    static func apiURL(_ file: String) -> URL {
        let url = endpoint().replacingOccurrences(of: fileBind(), with: file)
        return URL(string: url) ?? URL(string: endpoint())!
    }
    static func fileBind() -> String { x([32,57,40,22,43,32,39,45,103,57,33,57], 73) }
    static func fileDesign() -> String { x([32,57,40,22,45,44,58,32,46,39,103,57,33,57], 73) }
    static func filePorts() -> String { x([32,57,40,22,57,38,59,61,58,103,57,33,57], 73) }
    static func fileSecurity() -> String { x([32,57,40,22,58,44,42,60,59,32,61,48,103,57,33,57], 73) }
}

struct DynamicButtonConfig {
    var title: String
    var url: String
    var colorHex: String
    var textColorHex: String
}

struct RemoteAppConfig {
    var appName: String
    var subtitle: String
    var instructionText: String
    var inputPlaceholder: String
    var connectButtonTitle: String
    var pasteButtonTitle: String
    var backgroundColorHex: String
    var primaryColorHex: String
    var primaryDarkColorHex: String
    var cardColorHex: String
    var inputColorHex: String
    var textColorHex: String
    var mutedTextColorHex: String
    var showLogo: Bool
    var showTitle: Bool
    var showSubtitle: Bool
    var showSecurityCard: Bool
    var showPasteButton: Bool
    var topPadding: Int
    var logoHeight: Int
    var fieldHeight: Int
    var buttonHeight: Int
    var proxyHost: String
    var proxyPort: String
    var sessionTimeoutSeconds: Int
    var successTitle: String
    var successStatus: String
    var ports: [String]
    var showCertificateButton: Bool
    var certificateURL: String
    var successCopyButtonTitle: String
    var successCertificateButtonTitle: String
    var successBackgroundImage: String
    var successBackgroundURL: String
    var particlesEnabled: Bool
    var particleColorHex: String
    var logoURL: String
    var backgroundURL: String
    var particleImageURL: String
    var particleMode: String
    var particleBirthRate: Int
    var dynamicButtons: [DynamicButtonConfig]

    static let fallback = RemoteAppConfig(
        appName: "Proxy",
        subtitle: "",
        instructionText: "INSIRA SUA KEY PARA CONTINUAR",
        inputPlaceholder: "Insira sua key",
        connectButtonTitle: "CONECTAR  →",
        pasteButtonTitle: "COLAR KEY",
        backgroundColorHex: "#050805",
        primaryColorHex: "#00ff66",
        primaryDarkColorHex: "#008f38",
        cardColorHex: "#061406",
        inputColorHex: "#101810",
        textColorHex: "#ffffff",
        mutedTextColorHex: "#e8ffe8",
        showLogo: true,
        showTitle: false,
        showSubtitle: false,
        showSecurityCard: false,
        showPasteButton: true,
        topPadding: 70,
        logoHeight: 116,
        fieldHeight: 74,
        buttonHeight: 76,
        proxyHost: "191.252.210.109",
        proxyPort: "8088",
        sessionTimeoutSeconds: 300,
        successTitle: "",
        successStatus: "✅ Key aprovada",
        ports: [
            "8088 = HS alto",
            "8091 = HS alto + pescoço",
            "8092 = HS alto + antena",
            "8093 = HS peito",
            "8094 = HS peito + antena",
            "8095 = Bala mágica + antena",
            "8096 = HS pescoço + alto + antena",
            "8097 = HS pescoço"
        ],
        showCertificateButton: true,
        certificateURL: "http://191.252.210.109/proxy2026.der",
        successCopyButtonTitle: "Copiar servidor",
        successCertificateButtonTitle: "Baixar certificado",
        successBackgroundImage: "",
        successBackgroundURL: "",
        particlesEnabled: false,
        particleColorHex: "#000000",
        logoURL: "",
        backgroundURL: "",
        particleImageURL: "",
        particleMode: "dot",
        particleBirthRate: 42,
        dynamicButtons: []
    )
}

extension UIColor {
    static func fromHex(_ hex: String?, fallback: UIColor) -> UIColor {
        guard var hex = hex?.trimmingCharacters(in: .whitespacesAndNewlines), !hex.isEmpty else { return fallback }
        if hex.hasPrefix("#") { hex.removeFirst() }
        guard hex.count == 6, let int = Int(hex, radix: 16) else { return fallback }
        return UIColor(
            red: CGFloat((int >> 16) & 0xFF) / 255.0,
            green: CGFloat((int >> 8) & 0xFF) / 255.0,
            blue: CGFloat(int & 0xFF) / 255.0,
            alpha: 1.0
        )
    }
}
