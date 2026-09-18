import Foundation

public enum ContentKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case url
    case text
    case wifi
    case email
    case phone
    case sms
    case vcard
    case event
    case location

    public var id: String { rawValue }
}

public enum AppLanguage: String, Codable, CaseIterable, Identifiable, Sendable {
    case english = "en"
    case turkish = "tr"
    case german = "de"
    case spanish = "es"
    case danish = "da"
    case norwegian = "no"
    case italian = "it"
    case russian = "ru"

    public var id: String { rawValue }
}

public enum ErrorCorrection: String, Codable, CaseIterable, Identifiable, Sendable {
    case low = "L"
    case medium = "M"
    case quartile = "Q"
    case high = "H"

    public var id: String { rawValue }
}

public enum ModuleShape: String, Codable, CaseIterable, Identifiable, Sendable {
    case square
    case rounded
    case dot
    case diamond

    public var id: String { rawValue }
}

public enum FinderShape: String, Codable, CaseIterable, Identifiable, Sendable {
    case square
    case rounded
    case circle

    public var id: String { rawValue }
}

public enum ExportFormat: String, Codable, CaseIterable, Identifiable, Sendable {
    case png
    case jpg
    case webp
    case svg
    case pdf

    public var id: String { rawValue }
}

public enum FrameTemplate: String, Codable, CaseIterable, Identifiable, Sendable {
    case none
    case scanMe01 = "frame-01"
    case scanMe02 = "frame-02"
    case scanMe03 = "frame-03"
    case scanMe04 = "frame-04"
    case scanMe05 = "frame-05"
    case scanMe06 = "frame-06"
    case scanMe08 = "frame-08"
    case scanMe10 = "frame-10"
    case scanMe11 = "frame-11"
    // Keep the previous stored values so existing projects continue to open.
    case scanMe12 = "frame-09"
    case scanMe13 = "frame-07"

    public var id: String { rawValue }
}

public enum WiFiEncryption: String, Codable, CaseIterable, Identifiable, Sendable {
    case wpa = "WPA"
    case wep = "WEP"
    case none = "nopass"

    public var id: String { rawValue }
}

public struct LogoState: Codable, Equatable, Sendable {
    public var data: Data
    public var name: String
    public var scale: Double
    public var padding: Double
    public var cardColor: String
    public var radius: Double
    public var circleCard: Bool

    public init(
        data: Data,
        name: String,
        scale: Double = 0.2,
        padding: Double = 28,
        cardColor: String = "#ffffff",
        radius: Double = 32,
        circleCard: Bool = false
    ) {
        self.data = data
        self.name = name
        self.scale = scale
        self.padding = padding
        self.cardColor = cardColor
        self.radius = radius
        self.circleCard = circleCard
    }

    private enum CodingKeys: String, CodingKey {
        case data, dataUrl, name, scale, padding, cardColor, radius, circleCard
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? "logo"
        scale = try container.decodeIfPresent(Double.self, forKey: .scale) ?? 0.2
        padding = try container.decodeIfPresent(Double.self, forKey: .padding) ?? 28
        cardColor = try container.decodeIfPresent(String.self, forKey: .cardColor) ?? "#ffffff"
        radius = try container.decodeIfPresent(Double.self, forKey: .radius) ?? 32
        circleCard = try container.decodeIfPresent(Bool.self, forKey: .circleCard) ?? false

        if let rawData = try container.decodeIfPresent(Data.self, forKey: .data) {
            data = rawData
        } else if let dataURL = try container.decodeIfPresent(String.self, forKey: .dataUrl),
                  let comma = dataURL.firstIndex(of: ","),
                  let decoded = Data(base64Encoded: String(dataURL[dataURL.index(after: comma)...])) {
            data = decoded
        } else {
            throw DecodingError.dataCorruptedError(forKey: .data, in: container, debugDescription: "Missing or invalid logo image data.")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(data, forKey: .data)
        try container.encode(name, forKey: .name)
        try container.encode(scale, forKey: .scale)
        try container.encode(padding, forKey: .padding)
        try container.encode(cardColor, forKey: .cardColor)
        try container.encode(radius, forKey: .radius)
        try container.encode(circleCard, forKey: .circleCard)
    }
}

public struct StudioState: Codable, Equatable, Sendable {
    public var language: AppLanguage
    public var contentKind: ContentKind

    public var url: String
    public var text: String
    public var wifiSSID: String
    public var wifiPassword: String
    public var wifiEncryption: WiFiEncryption
    public var wifiHidden: Bool
    public var emailTo: String
    public var emailSubject: String
    public var emailBody: String
    public var phone: String
    public var smsBody: String
    public var vcardName: String
    public var vcardOrg: String
    public var vcardTitle: String
    public var vcardPhone: String
    public var vcardEmail: String
    public var vcardURL: String
    public var eventTitle: String
    public var eventStart: Date
    public var eventEnd: Date
    public var eventLocation: String
    public var locationLat: String
    public var locationLng: String

    public var errorCorrection: ErrorCorrection
    public var margin: Int
    public var moduleShape: ModuleShape
    public var finderShape: FinderShape
    public var foreground: String
    public var background: String
    public var finderForeground: String
    public var separateFinders: Bool
    public var transparentBackground: Bool
    public var frameTemplate: FrameTemplate
    public var frameText: String
    public var frameAccent: String
    public var logo: LogoState?
    public var exportFormat: ExportFormat
    public var exportSizes: [Int]
    public var customExportSize: Int
    public var fileName: String

    public init(language: AppLanguage = .turkish) {
        self.language = language
        self.contentKind = .url

        self.url = "https://example.com"
        self.text = Self.defaultText(for: language)
        self.wifiSSID = "Studio WiFi"
        self.wifiPassword = "super-secure-password"
        self.wifiEncryption = .wpa
        self.wifiHidden = false
        self.emailTo = "hello@example.com"
        self.emailSubject = Self.defaultEmailSubject(for: language)
        self.emailBody = Self.defaultEmailBody(for: language)
        self.phone = "+905551112233"
        self.smsBody = Self.defaultSMSBody(for: language)
        self.vcardName = "QR Studio"
        self.vcardOrg = "Design Lab"
        self.vcardTitle = "Product"
        self.vcardPhone = "+905551112233"
        self.vcardEmail = "hello@example.com"
        self.vcardURL = "https://example.com"
        self.eventTitle = "QR Studio Demo"
        self.eventStart = Self.makeDefaultEventDate(hour: 10)
        self.eventEnd = Self.makeDefaultEventDate(hour: 11)
        self.eventLocation = Self.defaultEventLocation(for: language)
        self.locationLat = "41.0082"
        self.locationLng = "28.9784"

        self.errorCorrection = .high
        self.margin = 4
        self.moduleShape = .square
        self.finderShape = .square
        self.foreground = "#050505"
        self.background = "#ffffff"
        self.finderForeground = "#0057ff"
        self.separateFinders = false
        self.transparentBackground = false
        self.frameTemplate = .none
        self.frameText = "Scan me"
        self.frameAccent = "#38bdf8"
        self.logo = nil
        self.exportFormat = .png
        self.exportSizes = [1024, 2048]
        self.customExportSize = 3000
        self.fileName = "qevorn-export"
    }

    /// The encoded content for the currently selected QR content type.
    public var payload: String {
        switch contentKind {
        case .text:
            return text.isEmpty ? " " : text
        case .wifi:
            return "WIFI:T:\(wifiEncryption.rawValue);S:\(Self.escapeWiFiField(wifiSSID));P:\(Self.escapeWiFiField(wifiPassword));H:\(wifiHidden ? "true" : "false");;"
        case .email:
            return "mailto:\(emailTo)?subject=\(Self.encodeURIComponent(emailSubject))&body=\(Self.encodeURIComponent(emailBody))"
        case .phone:
            return "tel:\(phone)"
        case .sms:
            return "SMSTO:\(phone):\(smsBody)"
        case .vcard:
            return [
                "BEGIN:VCARD",
                "VERSION:3.0",
                "FN:\(vcardName)",
                "ORG:\(vcardOrg)",
                "TITLE:\(vcardTitle)",
                "TEL:\(vcardPhone)",
                "EMAIL:\(vcardEmail)",
                "URL:\(vcardURL)",
                "END:VCARD",
            ].joined(separator: "\n")
        case .event:
            return [
                "BEGIN:VEVENT",
                "SUMMARY:\(eventTitle)",
                "DTSTART:\(Self.formatICalendarDate(eventStart))",
                "DTEND:\(Self.formatICalendarDate(eventEnd))",
                "LOCATION:\(eventLocation)",
                "END:VEVENT",
            ].joined(separator: "\n")
        case .location:
            return "geo:\(locationLat),\(locationLng)"
        case .url:
            return url.isEmpty ? "https://example.com" : url
        }
    }

    private static func escapeWiFiField(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: ";", with: "\\;")
            .replacingOccurrences(of: ",", with: "\\,")
            .replacingOccurrences(of: ":", with: "\\:")
    }

    /// Mirrors JavaScript's `encodeURIComponent` for email subject and body values.
    private static func encodeURIComponent(_ value: String) -> String {
        let allowed = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_.!~*'()")
        return value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
    }

    private static func formatICalendarDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = .current
        formatter.dateFormat = "yyyyMMdd'T'HHmm"
        return formatter.string(from: date)
    }

    private static func makeDefaultEventDate(hour: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        return calendar.date(from: DateComponents(year: 2026, month: 6, day: 24, hour: hour)) ?? .now
    }

    private static func defaultText(for language: AppLanguage) -> String {
        switch language {
        case .english: "Comprehensive QR code generated with QR Studio."
        case .turkish: "QR Studio ile üretilen kapsamlı QR kodu."
        case .german: "Umfassender QR-Code, erstellt mit QR Studio."
        case .spanish: "Código QR completo generado con QR Studio."
        case .danish: "Omfattende QR-kode genereret med QR Studio."
        case .norwegian: "Omfattende QR-kode generert med QR Studio."
        case .italian: "Codice QR completo generato con QR Studio."
        case .russian: "Комплексный QR-код, созданный в QR Studio."
        }
    }

    private static func defaultEmailSubject(for language: AppLanguage) -> String {
        switch language {
        case .english: "Hello"
        case .turkish: "Merhaba"
        case .german: "Hallo"
        case .spanish: "Hola"
        case .danish: "Hej"
        case .norwegian: "Hei"
        case .italian: "Ciao"
        case .russian: "Привет"
        }
    }

    private static func defaultEmailBody(for language: AppLanguage) -> String {
        switch language {
        case .english: "QR Studio test message"
        case .turkish: "QR Studio test mesajı"
        case .german: "QR Studio Testnachricht"
        case .spanish: "Mensaje de prueba de QR Studio"
        case .danish: "QR Studio testbesked"
        case .norwegian: "QR Studio testmelding"
        case .italian: "Messaggio di test QR Studio"
        case .russian: "Тестовое сообщение QR Studio"
        }
    }

    private static func defaultSMSBody(for language: AppLanguage) -> String {
        switch language {
        case .english: "Hello"
        case .turkish: "Merhaba"
        case .german: "Hallo"
        case .spanish: "Hola"
        case .danish: "Hej"
        case .norwegian: "Hei"
        case .italian: "Ciao"
        case .russian: "Привет"
        }
    }

    private static func defaultEventLocation(for language: AppLanguage) -> String {
        language == .spanish ? "Estambul" : language == .russian ? "Стамбул" : language == .turkish ? "İstanbul" : "Istanbul"
    }

    private enum CodingKeys: String, CodingKey {
        case language, contentKind, url, text, wifiSSID, wifiPassword, wifiEncryption, wifiHidden
        case emailTo, emailSubject, emailBody, phone, smsBody
        case vcardName, vcardOrg, vcardTitle, vcardPhone, vcardEmail, vcardURL
        case eventTitle, eventStart, eventEnd, eventLocation, locationLat, locationLng
        case errorCorrection, margin, moduleShape, finderShape, foreground, background, finderForeground
        case separateFinders, transparentBackground, frameTemplate, frameText, frameAccent, logo
        case exportFormat, exportSizes, customExportSize, fileName
        case wifiSsid
        case vcardUrl
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedLanguage = try container.decodeIfPresent(AppLanguage.self, forKey: .language) ?? .turkish
        self.init(language: decodedLanguage)

        contentKind = try container.decodeIfPresent(ContentKind.self, forKey: .contentKind) ?? contentKind
        url = try container.decodeIfPresent(String.self, forKey: .url) ?? url
        text = try container.decodeIfPresent(String.self, forKey: .text) ?? text
        wifiSSID = try container.decodeIfPresent(String.self, forKey: .wifiSSID)
            ?? container.decodeIfPresent(String.self, forKey: .wifiSsid)
            ?? wifiSSID
        wifiPassword = try container.decodeIfPresent(String.self, forKey: .wifiPassword) ?? wifiPassword
        wifiEncryption = try container.decodeIfPresent(WiFiEncryption.self, forKey: .wifiEncryption) ?? wifiEncryption
        wifiHidden = try container.decodeIfPresent(Bool.self, forKey: .wifiHidden) ?? wifiHidden
        emailTo = try container.decodeIfPresent(String.self, forKey: .emailTo) ?? emailTo
        emailSubject = try container.decodeIfPresent(String.self, forKey: .emailSubject) ?? emailSubject
        emailBody = try container.decodeIfPresent(String.self, forKey: .emailBody) ?? emailBody
        phone = try container.decodeIfPresent(String.self, forKey: .phone) ?? phone
        smsBody = try container.decodeIfPresent(String.self, forKey: .smsBody) ?? smsBody
        vcardName = try container.decodeIfPresent(String.self, forKey: .vcardName) ?? vcardName
        vcardOrg = try container.decodeIfPresent(String.self, forKey: .vcardOrg) ?? vcardOrg
        vcardTitle = try container.decodeIfPresent(String.self, forKey: .vcardTitle) ?? vcardTitle
        vcardPhone = try container.decodeIfPresent(String.self, forKey: .vcardPhone) ?? vcardPhone
        vcardEmail = try container.decodeIfPresent(String.self, forKey: .vcardEmail) ?? vcardEmail
        vcardURL = try container.decodeIfPresent(String.self, forKey: .vcardURL)
            ?? container.decodeIfPresent(String.self, forKey: .vcardUrl)
            ?? vcardURL
        eventTitle = try container.decodeIfPresent(String.self, forKey: .eventTitle) ?? eventTitle
        eventStart = try Self.decodeDate(container, key: .eventStart) ?? eventStart
        eventEnd = try Self.decodeDate(container, key: .eventEnd) ?? eventEnd
        eventLocation = try container.decodeIfPresent(String.self, forKey: .eventLocation) ?? eventLocation
        locationLat = try container.decodeIfPresent(String.self, forKey: .locationLat) ?? locationLat
        locationLng = try container.decodeIfPresent(String.self, forKey: .locationLng) ?? locationLng
        errorCorrection = try container.decodeIfPresent(ErrorCorrection.self, forKey: .errorCorrection) ?? errorCorrection
        margin = try container.decodeIfPresent(Int.self, forKey: .margin) ?? margin
        moduleShape = try container.decodeIfPresent(ModuleShape.self, forKey: .moduleShape) ?? moduleShape
        finderShape = try container.decodeIfPresent(FinderShape.self, forKey: .finderShape) ?? finderShape
        foreground = try container.decodeIfPresent(String.self, forKey: .foreground) ?? foreground
        background = try container.decodeIfPresent(String.self, forKey: .background) ?? background
        finderForeground = try container.decodeIfPresent(String.self, forKey: .finderForeground) ?? finderForeground
        separateFinders = try container.decodeIfPresent(Bool.self, forKey: .separateFinders) ?? separateFinders
        transparentBackground = try container.decodeIfPresent(Bool.self, forKey: .transparentBackground) ?? transparentBackground
        frameTemplate = try container.decodeIfPresent(FrameTemplate.self, forKey: .frameTemplate) ?? frameTemplate
        frameText = try container.decodeIfPresent(String.self, forKey: .frameText) ?? frameText
        frameAccent = try container.decodeIfPresent(String.self, forKey: .frameAccent) ?? frameAccent
        logo = try container.decodeIfPresent(LogoState.self, forKey: .logo) ?? logo
        exportFormat = try container.decodeIfPresent(ExportFormat.self, forKey: .exportFormat) ?? exportFormat
        exportSizes = try container.decodeIfPresent([Int].self, forKey: .exportSizes) ?? exportSizes
        customExportSize = try container.decodeIfPresent(Int.self, forKey: .customExportSize) ?? customExportSize
        fileName = try container.decodeIfPresent(String.self, forKey: .fileName) ?? fileName
    }

    private static func decodeDate(_ container: KeyedDecodingContainer<CodingKeys>, key: CodingKeys) throws -> Date? {
        if let value = try? container.decode(Date.self, forKey: key) { return value }
        guard let text = try container.decodeIfPresent(String.self, forKey: key) else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: text) { return date }
        let local = DateFormatter()
        local.locale = Locale(identifier: "en_US_POSIX")
        local.timeZone = .current
        local.dateFormat = "yyyy-MM-dd'T'HH:mm"
        return local.date(from: text)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(language, forKey: .language)
        try container.encode(contentKind, forKey: .contentKind)
        try container.encode(url, forKey: .url)
        try container.encode(text, forKey: .text)
        try container.encode(wifiSSID, forKey: .wifiSSID)
        try container.encode(wifiPassword, forKey: .wifiPassword)
        try container.encode(wifiEncryption, forKey: .wifiEncryption)
        try container.encode(wifiHidden, forKey: .wifiHidden)
        try container.encode(emailTo, forKey: .emailTo)
        try container.encode(emailSubject, forKey: .emailSubject)
        try container.encode(emailBody, forKey: .emailBody)
        try container.encode(phone, forKey: .phone)
        try container.encode(smsBody, forKey: .smsBody)
        try container.encode(vcardName, forKey: .vcardName)
        try container.encode(vcardOrg, forKey: .vcardOrg)
        try container.encode(vcardTitle, forKey: .vcardTitle)
        try container.encode(vcardPhone, forKey: .vcardPhone)
        try container.encode(vcardEmail, forKey: .vcardEmail)
        try container.encode(vcardURL, forKey: .vcardURL)
        try container.encode(eventTitle, forKey: .eventTitle)
        try container.encode(eventStart, forKey: .eventStart)
        try container.encode(eventEnd, forKey: .eventEnd)
        try container.encode(eventLocation, forKey: .eventLocation)
        try container.encode(locationLat, forKey: .locationLat)
        try container.encode(locationLng, forKey: .locationLng)
        try container.encode(errorCorrection, forKey: .errorCorrection)
        try container.encode(margin, forKey: .margin)
        try container.encode(moduleShape, forKey: .moduleShape)
        try container.encode(finderShape, forKey: .finderShape)
        try container.encode(foreground, forKey: .foreground)
        try container.encode(background, forKey: .background)
        try container.encode(finderForeground, forKey: .finderForeground)
        try container.encode(separateFinders, forKey: .separateFinders)
        try container.encode(transparentBackground, forKey: .transparentBackground)
        try container.encode(frameTemplate, forKey: .frameTemplate)
        try container.encode(frameText, forKey: .frameText)
        try container.encode(frameAccent, forKey: .frameAccent)
        try container.encodeIfPresent(logo, forKey: .logo)
        try container.encode(exportFormat, forKey: .exportFormat)
        try container.encode(exportSizes, forKey: .exportSizes)
        try container.encode(customExportSize, forKey: .customExportSize)
        try container.encode(fileName, forKey: .fileName)
    }
}
