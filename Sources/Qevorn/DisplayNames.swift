import Foundation
import UniformTypeIdentifiers

extension AppLanguage {
    var displayName: String {
        switch self {
        case .english: "English"
        case .turkish: "Türkçe"
        case .german: "Deutsch"
        case .spanish: "Español"
        case .danish: "Dansk"
        case .norwegian: "Norsk"
        case .italian: "Italiano"
        case .russian: "Русский"
        }
    }
}

extension ContentKind {
    func displayName(language: AppLanguage) -> String {
        let key: String
        switch self {
        case .url: key = "Website URL"
        case .text: key = "Plain text"
        case .wifi: key = "Wi-Fi"
        case .email: key = "Email"
        case .phone: key = "Phone"
        case .sms: key = "SMS"
        case .vcard: key = "Contact card"
        case .event: key = "Event"
        case .location: key = "Location"
        }
        return L10n.text(key, language: language)
    }
}

extension WiFiEncryption {
    func displayName(language: AppLanguage) -> String {
        switch self {
        case .wpa: "WPA"
        case .wep: "WEP"
        case .none: L10n.text("No password", language: language)
        }
    }
}

extension ModuleShape {
    func displayName(language: AppLanguage) -> String {
        switch self {
        case .square: L10n.text("Square", language: language)
        case .rounded: L10n.text("Rounded", language: language)
        case .dot: L10n.text("Dots", language: language)
        case .diamond: L10n.text("Diamond", language: language)
        }
    }
}

extension FinderShape {
    func displayName(language: AppLanguage) -> String {
        switch self {
        case .square: L10n.text("Square", language: language)
        case .rounded: L10n.text("Rounded", language: language)
        case .circle: L10n.text("Circle", language: language)
        }
    }
}

extension ErrorCorrection {
    var displayName: String {
        switch self {
        case .low: "L · 7%"
        case .medium: "M · 15%"
        case .quartile: "Q · 25%"
        case .high: "H · 30%"
        }
    }
}

extension ExportFormat {
    static var availableForExport: [ExportFormat] { [.png, .jpg, .svg, .pdf] }

    var displayName: String { rawValue.uppercased() }

    var fileExtension: String {
        switch self {
        case .jpg: "jpg"
        case .webp: "webp"
        case .png: "png"
        case .svg: "svg"
        case .pdf: "pdf"
        }
    }

    var contentType: UTType {
        switch self {
        case .png: .png
        case .jpg: .jpeg
        case .webp: UTType("org.webmproject.webp") ?? .image
        case .svg: .svg
        case .pdf: .pdf
        }
    }
}

extension FrameTemplate {
    func displayName(language: AppLanguage) -> String {
        if self == .none { return L10n.text("None", language: language) }
        switch self {
        case .scanMe12: return "Scan me 12"
        case .scanMe13: return "Scan me 13"
        default: return "Scan me \(rawValue.suffix(2))"
        }
    }
}
