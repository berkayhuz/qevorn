import AppKit
import SwiftUI
import UniformTypeIdentifiers

private enum StudioTab: String, CaseIterable, Identifiable {
    case content, design, logo, export, project

    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .content: "text.alignleft"
        case .design: "slider.horizontal.3"
        case .logo: "photo"
        case .export: "square.and.arrow.up"
        case .project: "doc.text"
        }
    }

}

private struct BatchRow: Identifiable {
    let id = UUID()
    var name: String
    var payload: String
}

struct StudioView: View {
    @State private var state = StudioState()
    @State private var activeTab: StudioTab = .content
    @State private var preview: QRRenderReport?
    @State private var status = "Ready"
    @State private var isRendering = false
    @State private var isExporting = false
    @State private var batchRows: [BatchRow] = []
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var showLogoImporter = false
    @State private var showProjectImporter = false
    @State private var showCSVImporter = false
    @State private var previewTask: Task<Void, Never>?
    @State private var previewGeneration = 0

    var body: some View {
        HStack(spacing: 0) {
            List(selection: $activeTab) {
                Section(L10n.text("Create", language: state.language)) { sidebarRow(.content) }
                Section(L10n.text("Appearance", language: state.language)) {
                    sidebarRow(.design)
                    sidebarRow(.logo)
                }
                Section(L10n.text("Output", language: state.language)) { sidebarRow(.export) }
                Section(L10n.text("Project", language: state.language)) { sidebarRow(.project) }
            }
            .listStyle(.sidebar)
            .frame(minWidth: 180, idealWidth: 210, maxWidth: 250, maxHeight: .infinity)

            HSplitView {
                inspector
                    .frame(minWidth: 300, idealWidth: 350, maxWidth: 420)
                previewWorkspace
                    .frame(minWidth: 420, idealWidth: 680, maxWidth: .infinity, maxHeight: .infinity)
            }
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Picker(L10n.text("Language", language: state.language), selection: languageBinding) {
                        ForEach(AppLanguage.allCases) { language in Text(language.displayName).tag(language) }
                    }
                    .pickerStyle(.menu)
                    .fixedSize()
                }
                ToolbarItem(placement: .primaryAction) {
                    if isRendering {
                        ProgressView(L10n.text("Rendering", language: state.language)).controlSize(.small)
                    } else {
                        Button {
                            Task { await refreshPreview() }
                        } label: {
                            Label(L10n.text("Preview", language: state.language), systemImage: "arrow.clockwise")
                        }
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        exportSelectedSizes()
                    } label: {
                        Label(L10n.text("Download", language: state.language), systemImage: "square.and.arrow.down")
                    }
                    .disabled(isExporting)
                    .help(L10n.text("Export selected sizes", language: state.language))
                }
            }
        }
        .frame(minWidth: 1080, minHeight: 720)
        .tint(.blue)
        .background {
            WindowTitlebarSeparatorController()
                .frame(width: 0, height: 0)
                .accessibilityHidden(true)
        }
        .task { await refreshPreview() }
        .onChange(of: state) { _, _ in
            schedulePreview()
        }
        .fileImporter(isPresented: $showLogoImporter, allowedContentTypes: [.image], allowsMultipleSelection: false) { result in
            do {
                guard let url = try result.get().first else { return }
                try loadLogo(from: url)
            } catch { present(error) }
        }
        .fileImporter(isPresented: $showCSVImporter, allowedContentTypes: [.commaSeparatedText, .plainText], allowsMultipleSelection: false) { result in
            do {
                guard let url = try result.get().first else { return }
                let data = try Data(contentsOf: url)
                guard data.count <= 2 * 1024 * 1024 else { throw StudioError.message("CSV files must be 2 MB or smaller.") }
                let text = String(decoding: data, as: UTF8.self)
                let rows = try parseCSV(text)
                guard rows.count <= 1000 else { throw StudioError.message("CSV can contain up to 1,000 rows.") }
                batchRows = rows
                status = "\(rows.count) CSV rows ready"
            } catch { present(error) }
        }
        .fileImporter(isPresented: $showProjectImporter, allowedContentTypes: [.json, .data], allowsMultipleSelection: false) { result in
            do {
                guard let url = try result.get().first else { return }
                let data = try Data(contentsOf: url)
                let json = try JSONSerialization.jsonObject(with: data)
                guard let root = json as? [String: Any] else { throw StudioError.message("Invalid project file.") }
                var loadedState: StudioState
                if root["state"] != nil {
                    loadedState = try JSONDecoder().decode(ProjectFile.self, from: data).state
                } else if root["contentKind"] != nil {
                    loadedState = try JSONDecoder().decode(StudioState.self, from: data)
                } else {
                    throw StudioError.message("Invalid project file.")
                }
                if loadedState.exportFormat == .webp { loadedState.exportFormat = .png }
                state = loadedState
                status = "Project opened"
            } catch { present(error) }
        }
        .alert("qevorn", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "Something went wrong.")
        }
    }

    private var inspector: some View {
        Form {
            switch activeTab {
            case .content: contentPanel
            case .design: designPanel
            case .logo: logoPanel
            case .export: exportPanel
            case .project: projectPanel
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .navigationTitle(L10n.text(activeTab.rawValue.capitalized, language: state.language))
    }

    private func sidebarRow(_ tab: StudioTab) -> some View {
        Label(L10n.text(tab.rawValue.capitalized, language: state.language), systemImage: tab.symbol)
            .tag(tab)
    }

    private func formSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        Section {
            content()
        } header: {
            Text(L10n.text(title, language: state.language))
        }
    }

    private var contentPanel: some View {
        Group {
            formSection("Content type") {
                Picker(L10n.text("Content type", language: state.language), selection: $state.contentKind) {
                    ForEach(ContentKind.allCases) { kind in
                        Label(kind.displayName(language: state.language), systemImage: kind.symbol).tag(kind)
                    }
                }
            }
            formSection("Content") {
                switch state.contentKind {
                case .url:
                    input("URL", text: $state.url)
                case .text:
                    input(L10n.text("Text", language: state.language), text: $state.text, multiline: true)
                case .wifi:
                    input("SSID", text: $state.wifiSSID)
                    input(L10n.text("Password", language: state.language), text: $state.wifiPassword, secure: true)
                    picker(L10n.text("Encryption", language: state.language), selection: $state.wifiEncryption) {
                        ForEach(WiFiEncryption.allCases) { value in
                            Text(value.displayName(language: state.language)).tag(value)
                        }
                    }
                    Toggle(L10n.text("Hidden network", language: state.language), isOn: $state.wifiHidden)
                case .email:
                    input(L10n.text("Recipient", language: state.language), text: $state.emailTo)
                    input(L10n.text("Subject", language: state.language), text: $state.emailSubject)
                    input(L10n.text("Message", language: state.language), text: $state.emailBody, multiline: true)
                case .phone:
                    input(L10n.text("Phone", language: state.language), text: $state.phone)
                case .sms:
                    input(L10n.text("Phone", language: state.language), text: $state.phone)
                    input(L10n.text("Message", language: state.language), text: $state.smsBody, multiline: true)
                case .vcard:
                    input(L10n.text("Full name", language: state.language), text: $state.vcardName)
                    input(L10n.text("Company", language: state.language), text: $state.vcardOrg)
                    input(L10n.text("Title", language: state.language), text: $state.vcardTitle)
                    input(L10n.text("Phone", language: state.language), text: $state.vcardPhone)
                    input(L10n.text("Email", language: state.language), text: $state.vcardEmail)
                    input("Web", text: $state.vcardURL)
                case .event:
                    input(L10n.text("Title", language: state.language), text: $state.eventTitle)
                    LabeledContent(L10n.text("Start", language: state.language)) {
                        DatePicker("", selection: $state.eventStart, displayedComponents: [.date, .hourAndMinute])
                            .labelsHidden()
                            .accessibilityLabel(L10n.text("Start", language: state.language))
                    }
                    LabeledContent(L10n.text("End", language: state.language)) {
                        DatePicker("", selection: $state.eventEnd, displayedComponents: [.date, .hourAndMinute])
                            .labelsHidden()
                            .accessibilityLabel(L10n.text("End", language: state.language))
                    }
                    input(L10n.text("Location", language: state.language), text: $state.eventLocation)
                case .location:
                    input(L10n.text("Latitude", language: state.language), text: $state.locationLat)
                    input(L10n.text("Longitude", language: state.language), text: $state.locationLng)
                }
            }
            formSection("Payload") {
                Text(state.payload)
                    .font(.body.monospaced())
                    .textSelection(.enabled)
                    .lineLimit(5)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var designPanel: some View {
        Group {
            formSection("QR style") {
                picker(L10n.text("Module shape", language: state.language), selection: $state.moduleShape) {
                    ForEach(ModuleShape.allCases) { shape in
                        Text(shape.displayName(language: state.language)).tag(shape)
                    }
                }
                picker(L10n.text("Finder shape", language: state.language), selection: $state.finderShape) {
                    ForEach(FinderShape.allCases) { shape in
                        Text(shape.displayName(language: state.language)).tag(shape)
                    }
                }
                Toggle(L10n.text("Transparent background", language: state.language), isOn: $state.transparentBackground)
            }
            formSection("Colors") {
                colorPicker(L10n.text("QR color", language: state.language), hex: $state.foreground)
                colorPicker(L10n.text("Background", language: state.language), hex: $state.background)
                Toggle(L10n.text("Separate finder color", language: state.language), isOn: $state.separateFinders)
                if state.separateFinders {
                    colorPicker(L10n.text("Finder color", language: state.language), hex: $state.finderForeground)
                }
            }
            formSection("Themes") {
                presetButton("Classic") {
                    state.foreground = "#050505"
                    state.background = "#FFFFFF"
                    state.moduleShape = .square
                    state.finderShape = .square
                    state.separateFinders = false
                }
                presetButton("Soft") {
                    state.foreground = "#172033"
                    state.background = "#F8FAFC"
                    state.moduleShape = .rounded
                    state.finderShape = .rounded
                    state.separateFinders = true
                    state.finderForeground = "#0F766E"
                }
                presetButton("Modern") {
                    state.foreground = "#101828"
                    state.background = "#FFFFFF"
                    state.moduleShape = .dot
                    state.finderShape = .circle
                    state.separateFinders = true
                    state.finderForeground = "#2563EB"
                }
            }
            formSection("Error correction") {
                picker(L10n.text("Error correction", language: state.language), selection: $state.errorCorrection) {
                    ForEach(ErrorCorrection.allCases) { level in Text(level.displayName).tag(level) }
                }
                Stepper(
                    "\(L10n.text("Quiet zone", language: state.language)): \(state.margin)",
                    value: $state.margin,
                    in: 0...16
                )
            }
        }
    }

    private var logoPanel: some View {
        Group {
            formSection("Logo") {
                Button {
                    showLogoImporter = true
                } label: {
                    Label(
                        state.logo?.name ?? L10n.text("Choose logo", language: state.language),
                        systemImage: "photo.badge.plus"
                    )
                }
                .buttonStyle(.bordered)
                Text(L10n.text("PNG · JPEG · WebP, max 5 MB", language: state.language))
                    .foregroundStyle(.secondary)

                if let logo = state.logo {
                    HStack {
                        if let image = NSImage(data: logo.data) {
                            Image(nsImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 52, height: 52)
                                .accessibilityLabel(logo.name)
                        }
                        Text(logo.name).lineLimit(1)
                        Spacer()
                        Button(role: .destructive) {
                            state.logo = nil
                        } label: {
                            Label(L10n.text("Remove logo", language: state.language), systemImage: "trash")
                        }
                        .labelStyle(.iconOnly)
                        .help(L10n.text("Remove logo", language: state.language))
                    }
                    slider("Logo scale", value: logoBinding(\.scale), range: 0.08...0.34, format: .percent)
                    slider("Logo padding", value: logoBinding(\.padding), range: 0...80, step: 2, suffix: " px")
                    Toggle(L10n.text("Circular logo card", language: state.language), isOn: logoBinding(\.circleCard))
                    slider("Card radius", value: logoBinding(\.radius), range: 0...220, step: 2, suffix: " px")
                    colorPicker(L10n.text("Logo card color", language: state.language), hex: logoColorBinding)
                } else {
                    Text(L10n.text("Place a brand mark in the center of the QR code.", language: state.language))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var exportPanel: some View {
        Group {
            formSection("Export") {
                picker(L10n.text("Format", language: state.language), selection: $state.exportFormat) {
                    ForEach(ExportFormat.availableForExport) { format in Text(format.displayName).tag(format) }
                }
                input(L10n.text("File name", language: state.language), text: $state.fileName)
                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.text("Export sizes", language: state.language))
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 92), alignment: .leading)],
                        alignment: .leading
                    ) {
                        ForEach([256, 512, 1024, 2048, 4096, 8192], id: \.self) { size in
                            sizeToggle(size)
                        }
                        ForEach(
                            state.exportSizes.filter { ![256, 512, 1024, 2048, 4096, 8192].contains($0) },
                            id: \.self
                        ) { size in
                            sizeToggle(size)
                        }
                    }
                }
                LabeledContent(L10n.text("Custom size", language: state.language)) {
                    HStack {
                        TextField(
                            L10n.text("Custom size", language: state.language),
                            value: $state.customExportSize,
                            format: .number
                        )
                        .frame(maxWidth: 110)
                        Button(L10n.text("Add size", language: state.language)) {
                            let size = min(20_000, max(128, state.customExportSize))
                            if !state.exportSizes.contains(size) {
                                state.exportSizes.append(size)
                                state.exportSizes.sort()
                            }
                        }
                    }
                }
                Button { runDecodeTest() } label: {
                    Label(L10n.text("Run QR decode test", language: state.language), systemImage: "viewfinder")
                }
                Button { exportSelectedSizes() } label: {
                    Label(L10n.text("Export selected sizes", language: state.language), systemImage: "square.and.arrow.down")
                }
                .disabled(isExporting)
                Text(L10n.text("Multiple sizes are saved together in a folder you choose.", language: state.language))
                    .foregroundStyle(.secondary)
            }
            formSection("CSV batch") {
                Button { showCSVImporter = true } label: {
                    Label(L10n.text("Upload CSV", language: state.language), systemImage: "doc.badge.arrow.up")
                }
                if batchRows.isEmpty {
                    Text(L10n.text("CSV columns: name,payload or first column as payload", language: state.language))
                        .foregroundStyle(.secondary)
                } else {
                    Text("\(batchRows.count) \(L10n.text("rows ready", language: state.language))")
                        .fontWeight(.semibold)
                    ForEach(Array(batchRows.prefix(3).enumerated()), id: \.offset) { _, row in
                        LabeledContent(row.name) {
                            Text(row.payload)
                                .lineLimit(1)
                                .truncationMode(.middle)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                Button { exportBatch() } label: {
                    Label(L10n.text("Export CSV batch", language: state.language), systemImage: "square.stack.3d.up")
                }
                .disabled(batchRows.isEmpty || isExporting)
            }
        }
    }

    private var projectPanel: some View {
        Group {
            formSection("Project") {
                Button { saveProject() } label: {
                    Label(L10n.text("Save project as JSON", language: state.language), systemImage: "square.and.arrow.down")
                }
                Button { showProjectImporter = true } label: {
                    Label(L10n.text("Open JSON project", language: state.language), systemImage: "folder")
                }
                Button(role: .destructive) {
                    state = StudioState(language: state.language)
                    status = L10n.text("Ready", language: state.language)
                } label: {
                    Label(L10n.text("Reset to defaults", language: state.language), systemImage: "arrow.counterclockwise")
                }
            }
            formSection("Project summary") {
                LabeledContent(L10n.text("Content", language: state.language), value: state.contentKind.displayName(language: state.language))
                LabeledContent(L10n.text("Export", language: state.language), value: "\(state.exportFormat.displayName) · \(state.exportSizes.count) sizes")
                LabeledContent(L10n.text("Logo", language: state.language), value: state.logo?.name ?? L10n.text("Unavailable", language: state.language))
                Text(L10n.text("Project files keep your content, QR styling, logo, and export settings together.", language: state.language))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var previewWorkspace: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(L10n.text("QR canvas", language: state.language))
                        .font(.title2.weight(.semibold))
                    Text(L10n.text("Live preview", language: state.language))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Label("\(qualityScore)/100", systemImage: qualityScore >= 82 ? "checkmark.shield" : "exclamationmark.shield")
                    .monospacedDigit()
                    .foregroundStyle(.blue)
                if let preview {
                    let side = Int(Double(preview.moduleCount).squareRoot().rounded())
                    Text("\(side) × \(side)")
                        .foregroundStyle(.secondary)
                        .help(L10n.text("Modules", language: state.language))
                }
            }

            ZStack {
                if let preview {
                    Image(decorative: preview.cgImage, scale: 1)
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()
                        .padding(28)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .accessibilityLabel(L10n.text("QR canvas", language: state.language))
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "qrcode").font(.largeTitle).foregroundStyle(.blue)
                        Text(L10n.text("Preparing preview", language: state.language)).foregroundStyle(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(12)

            HStack(alignment: .top, spacing: 16) {
                GroupBox {
                    if let preview, !preview.warnings.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(preview.warnings, id: \.self) { warning in
                                Label(L10n.warning(warning, language: state.language), systemImage: "exclamationmark.triangle")
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        Label(L10n.text("No critical risk detected.", language: state.language), systemImage: "checkmark.circle")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                } label: {
                    Label(L10n.text("Quality control", language: state.language), systemImage: "checkmark.shield")
                }
                .frame(maxWidth: .infinity)

                GroupBox {
                    VStack(spacing: 6) {
                        summaryRow(L10n.text("Modules", language: state.language), value: preview.map { "\($0.moduleCount)" } ?? "—")
                        summaryRow(L10n.text("Dark modules", language: state.language), value: preview.map { "\($0.darkModuleCount)" } ?? "—")
                        summaryRow(L10n.text("PNG memory estimate", language: state.language), value: preview.map { String(format: "%.1f MB", $0.estimatedMemoryMB) } ?? "—")
                    }
                } label: {
                    Label(L10n.text("Technical summary", language: state.language), systemImage: "slider.horizontal.3")
                }
                .frame(maxWidth: 300)
            }

            HStack(spacing: 8) {
                if isRendering { ProgressView().controlSize(.small) }
                Text(status).lineLimit(1)
                Text("·").foregroundStyle(.tertiary)
                Text("\(state.payload.count) \(L10n.text("character payload", language: state.language))")
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Spacer()
            }
            .font(.callout)
            .foregroundStyle(.secondary)
        }
        .padding(20)
    }

    private var qualityScore: Int {
        guard let preview else { return 0 }
        return max(30, min(100, 100 - preview.warnings.count * 14 - Int(max(0, preview.density - 0.52) * 80)))
    }

    private func input(_ title: String, text: Binding<String>, secure: Bool = false, multiline: Bool = false) -> some View {
        LabeledContent(L10n.text(title, language: state.language)) {
            if multiline {
                TextEditor(text: text)
                    .frame(minHeight: 64, maxHeight: 110)
                    .accessibilityLabel(L10n.text(title, language: state.language))
            } else if secure {
                SecureField(title, text: text)
                    .accessibilityLabel(L10n.text(title, language: state.language))
                    .frame(maxWidth: 220)
            } else {
                TextField(title, text: text)
                    .accessibilityLabel(L10n.text(title, language: state.language))
                    .frame(maxWidth: 260)
            }
        }
    }

    private func picker<Value: Hashable, Content: View>(
        _ title: String,
        selection: Binding<Value>,
        @ViewBuilder content: () -> Content
    ) -> some View {
        Picker(title, selection: selection, content: content)
            .pickerStyle(.menu)
    }

    private func colorPicker(_ title: String, hex: Binding<String>) -> some View {
        ColorPicker(
            title,
            selection: Binding(
                get: { Color(hex: hex.wrappedValue) },
                set: { hex.wrappedValue = $0.hexString }
            ),
            supportsOpacity: false
        )
    }

    private func slider(
        _ title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double = 0.01,
        format: SliderFormat = .number,
        suffix: String = ""
    ) -> some View {
        LabeledContent(L10n.text(title, language: state.language)) {
            HStack(spacing: 10) {
                Slider(value: value, in: range, step: step)
                    .accessibilityValue(format == .percent ? "\(Int(value.wrappedValue * 100))%" : "\(Int(value.wrappedValue))\(suffix)")
                Text(format == .percent ? "\(Int(value.wrappedValue * 100))%" : "\(Int(value.wrappedValue))\(suffix)")
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .frame(minWidth: 44, alignment: .trailing)
            }
        }
    }

    private func logoBinding<Value>(_ keyPath: WritableKeyPath<LogoState, Value>) -> Binding<Value> where Value: Equatable {
        Binding(get: { state.logo![keyPath: keyPath] }, set: { value in state.logo?[keyPath: keyPath] = value })
    }

    private var logoColorBinding: Binding<String> {
        Binding(get: { state.logo?.cardColor ?? "#FFFFFF" }, set: { value in state.logo?.cardColor = value })
    }

    private func presetButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(L10n.text(title, language: state.language), action: action)
            .buttonStyle(.bordered)
    }

    private func sizeToggle(_ size: Int) -> some View {
        Toggle(
            "\(size)",
            isOn: Binding(
                get: { state.exportSizes.contains(size) },
                set: { selected in
                    if selected {
                        if !state.exportSizes.contains(size) { state.exportSizes.append(size) }
                    } else {
                        state.exportSizes.removeAll { $0 == size }
                    }
                    state.exportSizes.sort()
                }
            )
        )
        .toggleStyle(.checkbox)
    }

    private func summaryRow(_ title: String, value: String) -> some View {
        LabeledContent(title, value: value)
    }

    private var languageBinding: Binding<AppLanguage> {
        Binding(get: { state.language }, set: changeLanguage)
    }

    private func changeLanguage(_ language: AppLanguage) {
        let previousDefaults = StudioState(language: state.language)
        let nextDefaults = StudioState(language: language)
        if state.text == previousDefaults.text { state.text = nextDefaults.text }
        if state.emailSubject == previousDefaults.emailSubject { state.emailSubject = nextDefaults.emailSubject }
        if state.emailBody == previousDefaults.emailBody { state.emailBody = nextDefaults.emailBody }
        if state.smsBody == previousDefaults.smsBody { state.smsBody = nextDefaults.smsBody }
        if state.eventLocation == previousDefaults.eventLocation { state.eventLocation = nextDefaults.eventLocation }
        state.language = language
    }

    @MainActor
    private func refreshPreview() async {
        previewGeneration += 1
        let generation = previewGeneration
        isRendering = true
        let value = state
        do {
            let report = try await Task.detached(priority: .userInitiated) {
                try QRRenderingEngine.render(state: value, size: 768)
            }.value
            guard generation == previewGeneration else { return }
            preview = report
            status = L10n.text("Preview updated", language: state.language)
        } catch {
            guard generation == previewGeneration else { return }
            status = error.localizedDescription
        }
        if generation == previewGeneration { isRendering = false }
    }

    @MainActor
    private func schedulePreview() {
        previewTask?.cancel()
        previewTask = Task {
            do { try await Task.sleep(for: .milliseconds(180)) }
            catch { return }
            guard !Task.isCancelled else { return }
            await refreshPreview()
        }
    }

    private func runDecodeTest() {
        let value = state
        status = L10n.text("Decode test is running", language: state.language)
        Task {
            do {
                let passed = try await Task.detached(priority: .userInitiated) {
                    try QRRenderingEngine.decodeTest(state: value)
                }.value
                status = L10n.text(passed ? "Decode test passed." : "Decode test failed.", language: state.language)
            } catch { present(error) }
        }
    }

    private func exportSelectedSizes() {
        let sizes = Array(Set(state.exportSizes)).sorted().filter { $0 >= 128 }
        guard !sizes.isEmpty else { present(StudioError.message("Choose at least one export size.")); return }
        guard sizes.count == 1 else { exportToFolder(sizes: sizes); return }
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "\(state.fileName)-\(sizes[0]).\(state.exportFormat.fileExtension)"
        panel.allowedContentTypes = [state.exportFormat.contentType]
        panel.canCreateDirectories = true
        guard panel.runModal() == .OK, let url = panel.url else { status = "Save cancelled"; return }
        let value = state
        let size = sizes[0]
        isExporting = true
        Task {
            do {
                let data = try await Task.detached(priority: .userInitiated) {
                    try QRRenderingEngine.export(state: value, format: value.exportFormat, size: size)
                }.value
                try data.write(to: url, options: .atomic)
                status = "Saved \(url.lastPathComponent)"
            } catch { present(error) }
            isExporting = false
        }
    }

    private func exportToFolder(sizes: [Int]) {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.prompt = L10n.text("Choose folder", language: state.language)
        guard panel.runModal() == .OK, let folder = panel.url else { status = "Folder selection cancelled"; return }
        let value = state
        isExporting = true
        Task {
            do {
                for size in sizes {
                    let data = try await Task.detached(priority: .userInitiated) {
                        try QRRenderingEngine.export(state: value, format: value.exportFormat, size: size)
                    }.value
                    try data.write(to: folder.appendingPathComponent("\(safeFileName(value.fileName))-\(size).\(value.exportFormat.fileExtension)"), options: .atomic)
                }
                status = "\(sizes.count) files saved to \(folder.lastPathComponent)"
            } catch { present(error) }
            isExporting = false
        }
    }

    private func exportBatch() {
        let sizes = Array(Set(state.exportSizes)).sorted().filter { $0 >= 128 }
        guard batchRows.count * sizes.count <= 250 else { present(StudioError.message("Batch export can create up to 250 files at once.")); return }
        guard let folder = chooseFolder() else { return }
        let value = state
        let rows = batchRows
        isExporting = true
        Task {
            do {
                for row in rows {
                    var rowState = value
                    rowState.contentKind = .text
                    rowState.text = row.payload
                    for size in sizes {
                        let data = try await Task.detached(priority: .userInitiated) {
                            try QRRenderingEngine.export(state: rowState, format: rowState.exportFormat, size: size)
                        }.value
                        let name = "\(safeFileName(value.fileName))-\(safeFileName(row.name))-\(size).\(value.exportFormat.fileExtension)"
                        try data.write(to: uniqueURL(in: folder, named: name), options: .atomic)
                    }
                }
                status = "\(rows.count * sizes.count) batch files saved"
            } catch { present(error) }
            isExporting = false
        }
    }

    private func saveProject() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "\(safeFileName(state.fileName)).qrstudio.json"
        panel.allowedContentTypes = [.json]
        panel.canCreateDirectories = true
        guard panel.runModal() == .OK, let url = panel.url else { status = "Save cancelled"; return }
        do {
            let data = try JSONEncoder.pretty.encode(ProjectFile(version: 1, state: state))
            try data.write(to: url, options: .atomic)
            status = "Project saved"
        } catch { present(error) }
    }

    private func loadLogo(from url: URL) throws {
        let hasAccess = url.startAccessingSecurityScopedResource()
        defer { if hasAccess { url.stopAccessingSecurityScopedResource() } }
        let data = try Data(contentsOf: url)
        guard data.count <= 5 * 1024 * 1024 else { throw StudioError.message("Logo must be 5 MB or smaller.") }
        let ext = url.pathExtension.lowercased()
        guard ["png", "jpg", "jpeg", "webp"].contains(ext) else {
            throw StudioError.message("Choose a PNG, JPEG, or WebP image for the logo.")
        }
        guard let image = NSImage(data: data), let bitmap = NSBitmapImageRep(data: image.tiffRepresentation ?? Data()) else {
            throw StudioError.message("Choose a PNG, JPEG, or WebP image for the logo.")
        }
        guard bitmap.pixelsWide * bitmap.pixelsHigh <= 16_000_000 else { throw StudioError.message("Logo resolution is too large. Limit: 16 MP.") }
        state.logo = LogoState(data: data, name: url.lastPathComponent, scale: state.logo?.scale ?? 0.2, padding: state.logo?.padding ?? 28, cardColor: state.logo?.cardColor ?? "#FFFFFF", radius: state.logo?.radius ?? 32, circleCard: state.logo?.circleCard ?? false)
        if state.errorCorrection == .low { state.errorCorrection = .high }
    }

    private func chooseFolder() -> URL? {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true; panel.canChooseFiles = false; panel.canCreateDirectories = true
        panel.prompt = L10n.text("Choose folder", language: state.language)
        return panel.runModal() == .OK ? panel.url : nil
    }

    private func present(_ error: Error) {
        errorMessage = error.localizedDescription
        showError = true
        status = error.localizedDescription
    }

    private func parseCSV(_ text: String) throws -> [BatchRow] {
        var table: [[String]] = []
        var row: [String] = []
        var cell = ""
        var quoted = false
        let chars = Array(text)
        var i = 0
        while i < chars.count {
            let ch = chars[i]
            if ch == "\"" && quoted && i + 1 < chars.count && chars[i + 1] == "\"" {
                cell.append("\""); i += 1
            } else if ch == "\"" {
                quoted.toggle()
            } else if ch == "," && !quoted {
                row.append(cell); cell = ""
            } else if (ch == "\n" || ch == "\r") && !quoted {
                row.append(cell); table.append(row); row = []; cell = ""
                if ch == "\r" && i + 1 < chars.count && chars[i + 1] == "\n" { i += 1 }
            } else { cell.append(ch) }
            i += 1
        }
        row.append(cell); table.append(row)
        table = table.filter { $0.contains(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty }) }
        guard !table.isEmpty else { throw StudioError.message("CSV is empty.") }
        let headers = table[0].map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
        let hasHeader = headers.contains("payload") || headers.contains("url") || headers.contains("name")
        let payloadIndex = hasHeader ? max(headers.firstIndex(of: "payload") ?? -1, headers.firstIndex(of: "url") ?? -1) : 0
        let nameIndex = hasHeader ? (headers.firstIndex(of: "name") ?? -1) : -1
        let source = hasHeader ? Array(table.dropFirst()) : table
        return source.enumerated().compactMap { offset, values in
            let payload = (values[safe: payloadIndex] ?? values.first ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !payload.isEmpty else { return nil }
            let name = (nameIndex >= 0 ? values[safe: nameIndex] : nil) ?? "row-\(offset + 1)"
            return BatchRow(name: safeFileName(name), payload: payload)
        }
    }

    private func chooseFolderForExport() -> URL? { chooseFolder() }
    private func safeFileName(_ name: String) -> String {
        let cleaned = name.map { "<>:\"/\\|?*".contains($0) || $0.isNewline ? "-" : String($0) }.joined().trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? "qevorn" : cleaned
    }
    private func uniqueURL(in folder: URL, named name: String) -> URL {
        let base = folder.appendingPathComponent(name)
        guard FileManager.default.fileExists(atPath: base.path) else { return base }
        let ext = base.pathExtension; let stem = base.deletingPathExtension().lastPathComponent
        var index = 2
        while true {
            let url = folder.appendingPathComponent("\(stem)-\(index).\(ext)")
            if !FileManager.default.fileExists(atPath: url.path) { return url }
            index += 1
        }
    }
}

private struct WindowTitlebarSeparatorController: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        WindowTitlebarSeparatorView(frame: .zero)
    }

    func updateNSView(_ view: NSView, context: Context) {
        view.window?.titlebarSeparatorStyle = .none
    }
}

private final class WindowTitlebarSeparatorView: NSView {
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.titlebarSeparatorStyle = .none
    }
}

private enum SliderFormat { case number, percent }
private struct ProjectFile: Codable { var version: Int; var state: StudioState }
private enum StudioError: LocalizedError { case message(String); var errorDescription: String? { if case .message(let text) = self { return text }; return nil } }

private extension Collection {
    subscript(safe index: Index) -> Element? { indices.contains(index) ? self[index] : nil }
}

private extension Color {
    init(hex: String) {
        let clean = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        let value = UInt64(clean, radix: 16) ?? 0xFFFFFF
        let r, g, b: UInt64
        if clean.count == 6 { r = (value >> 16) & 0xFF; g = (value >> 8) & 0xFF; b = value & 0xFF }
        else { r = 255; g = 255; b = 255 }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: 1)
    }
    var hexString: String {
        guard let components = NSColor(self).usingColorSpace(.deviceRGB)?.cgColor.components, components.count >= 3 else { return "#FFFFFF" }
        return String(format: "#%02X%02X%02X", Int(components[0] * 255), Int(components[1] * 255), Int(components[2] * 255))
    }
}

private extension JSONEncoder {
    static var pretty: JSONEncoder { let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]; return encoder }
}

private extension ContentKind {
    var symbol: String {
        switch self {
        case .url: "link"
        case .text: "text.alignleft"
        case .wifi: "wifi"
        case .email: "envelope"
        case .phone: "phone"
        case .sms: "message"
        case .vcard: "person.crop.rectangle"
        case .event: "calendar"
        case .location: "mappin.and.ellipse"
        }
    }
}
