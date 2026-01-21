import SwiftUI

struct TransmissionSettingsView: View {
    @EnvironmentObject private var serviceStore: ServiceStore
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var preferences: PreferencesStore

    @State private var isLoading = false
    @State private var errorMessage: String?

    @State private var encryption: EncryptionMode = .preferred
    @State private var peerLimitGlobal: Int = 200
    @State private var peerLimitPerTorrent: Int = 50

    @State private var downloadLimitEnabled = false
    @State private var uploadLimitEnabled = false
    @State private var downloadLimit = 1000
    @State private var uploadLimit = 200
    @State private var scheduleEnabled = false
    @State private var scheduleBeginTime = TransmissionSettingsView.defaultTime(hour: 8, minute: 0)
    @State private var scheduleEndTime = TransmissionSettingsView.defaultTime(hour: 18, minute: 0)
    @State private var scheduleDays: Set<ScheduleDay> = Set(ScheduleDay.allCases)

    @State private var blocklistEnabled = false
    @State private var blocklistURL: String = ""
    @State private var blocklistSize: Int = 0

    @State private var peerPort: Int = 51413
    @State private var randomOnStart = false
    @State private var portOpen: Bool?

    @State private var selectedTab: SectionID = .session

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Menu {
                    ForEach(serviceStore.services) { service in
                        Button(service.name) {
                            appState.selectedServiceID = service.id
                        }
                    }
                } label: {
                    Label(selectedService?.name ?? "No Service", systemImage: "antenna.radiowaves.left.and.right")
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .frame(maxWidth: 240, alignment: .leading)
                }
                .controlSize(.small)
                .disabled(serviceStore.services.isEmpty)

                Spacer()

                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                }
            }
            Divider()

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
            }

            TabView(selection: $selectedTab) {
                sessionTab
                    .tabItem { Text("Session") }
                    .tag(SectionID.session)
                bandwidthTab
                    .tabItem { Text("Bandwidth") }
                    .tag(SectionID.bandwidth)
                blocklistTab
                    .tabItem { Text("Blocklist") }
                    .tag(SectionID.blocklist)
                portTab
                    .tabItem { Text("Port") }
                    .tag(SectionID.port)
            }
            .frame(height: 300)
        }
        .padding(16)
        .frame(minWidth: 630)
        .onAppear(perform: loadSession)
        .onChange(of: appState.selectedServiceID) { _, _ in loadSession() }
        .onChange(of: appState.serverSettingsSection) { _, newValue in
            guard let newValue, let tab = SectionID(rawValue: newValue) else { return }
            selectedTab = tab
        }
    }

    private var sessionTab: some View {
        GroupBox("Session Settings") {
            VStack(alignment: .leading, spacing: 8) {
                Picker("Encryption", selection: $encryption) {
                    ForEach(EncryptionMode.allCases) { mode in
                        Text(mode.label).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                Stepper(value: $peerLimitGlobal, in: 1...5_000) {
                    LabeledContent("Global peers", value: "\(peerLimitGlobal)")
                        .monospacedDigit()
                }
                Stepper(value: $peerLimitPerTorrent, in: 1...1_000) {
                    LabeledContent("Peers per torrent", value: "\(peerLimitPerTorrent)")
                        .monospacedDigit()
                }

                HStack {
                    Spacer()
                    Button("Apply Session Settings") { Task { await applySessionSettings() } }
                        .buttonStyle(.borderedProminent)
                }
            }
        }
    }

    private var bandwidthTab: some View {
        GroupBox("Bandwidth Limits") {
            VStack(alignment: .leading, spacing: 12) {
                limitRow(
                    title: "Download",
                    isEnabled: $downloadLimitEnabled,
                    value: $downloadLimit,
                    toggleLabel: "Limit download speed"
                )

                Divider()

                HStack(spacing: 12) {
                    Toggle("Limit upload speed", isOn: $uploadLimitEnabled)
                    Spacer()
                    Stepper(value: $uploadLimit, in: 10...100000, step: 50) {
                        Text("\(uploadLimit) kB/s")
                            .monospacedDigit()
                    }
                    .disabled(!uploadLimitEnabled)
                }

                Divider()

                scheduleSection

                HStack {
                    Spacer()
                    Button("Apply Bandwidth Limits") { Task { await applyBandwidthLimits() } }
                        .buttonStyle(.borderedProminent)
                }
            }
        }
    }

    private var blocklistTab: some View {
        GroupBox("Blocklist") {
            VStack(alignment: .leading, spacing: 8) {
                Toggle("Enable blocklist", isOn: $blocklistEnabled)
                LabeledContent("Blocklist URL") {
                    TextField("", text: $blocklistURL)
                        .textFieldStyle(.roundedBorder)
                        .frame(minWidth: 260)
                }
                LabeledContent("Entries") {
                    Text("\(blocklistSize)")
                        .monospacedDigit()
                }

                HStack {
                    Button("Update Now") { Task { await updateBlocklist() } }
                    Spacer()
                    Button("Apply Blocklist") { Task { await applyBlocklistSettings() } }
                        .buttonStyle(.borderedProminent)
                }
            }
        }
    }

    private var portTab: some View {
        GroupBox("Port Settings") {
            VStack(alignment: .leading, spacing: 8) {
                Stepper(value: $peerPort, in: 1...65_535) {
                    LabeledContent("Peer port", value: "\(peerPort)")
                        .monospacedDigit()
                }
                Toggle("Randomize port on start", isOn: $randomOnStart)
                LabeledContent("Port status") {
                    Text(portStatusText)
                        .foregroundColor(portStatusColor)
                }

                HStack {
                    Button("Test Port") { Task { await testPort() } }
                    Spacer()
                    Button("Apply Port Settings") { Task { await applyPortSettings() } }
                        .buttonStyle(.borderedProminent)
                }
            }
        }
    }


    private func limitRow(
        title: String,
        isEnabled: Binding<Bool>,
        value: Binding<Int>,
        toggleLabel: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)

            HStack(spacing: 12) {
                Toggle(toggleLabel, isOn: isEnabled)
                Spacer()
                Stepper(value: value, in: 10...100000, step: 50) {
                    Text("\(value.wrappedValue) kB/s")
                        .monospacedDigit()
                }
                .disabled(!isEnabled.wrappedValue)
            }
        }
    }

    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Alternate Speed Schedule")
                .font(.headline)

            Toggle("Enable schedule", isOn: $scheduleEnabled)

            HStack(spacing: 12) {
                Text("Start")
                    .foregroundColor(.secondary)
                DatePicker(
                    "",
                    selection: $scheduleBeginTime,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.field)
                .labelsHidden()
                .disabled(!scheduleEnabled)
            }

            HStack(spacing: 12) {
                Text("End")
                    .foregroundColor(.secondary)
                DatePicker(
                    "",
                    selection: $scheduleEndTime,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.field)
                .labelsHidden()
                .disabled(!scheduleEnabled)
            }

            HStack(spacing: 8) {
                Text("Days")
                    .foregroundColor(.secondary)
                ForEach(ScheduleDay.allCases, id: \.self) { day in
                    Button(day.label) {
                        if scheduleDays.contains(day) {
                            scheduleDays.remove(day)
                        } else {
                            scheduleDays.insert(day)
                        }
                    }
                    .buttonStyle(.bordered)
                    .tint(scheduleDays.contains(day) ? .accentColor : .gray)
                    .disabled(!scheduleEnabled)
                }
            }
        }
    }

    private func loadSession() {
        guard let service = selectedService else {
            errorMessage = "Select a service to edit settings."
            return
        }

        errorMessage = nil
        isLoading = true

        Task {
            defer { isLoading = false }
            do {
                let client = TransmissionRPCClient(
                    config: service,
                    allowInsecureTLS: preferences.allowInsecureTLS
                )
                let session: SessionGetResponseArguments = try await client.request(
                    method: "session-get",
                    arguments: SessionGetArguments()
                )

                encryption = EncryptionMode(session.encryption)
                peerLimitGlobal = max(1, session.peerLimitGlobal ?? peerLimitGlobal)
                peerLimitPerTorrent = max(1, session.peerLimitPerTorrent ?? peerLimitPerTorrent)

                downloadLimit = session.speedLimitDown ?? downloadLimit
                uploadLimit = session.speedLimitUp ?? uploadLimit
                downloadLimitEnabled = session.speedLimitDownEnabled ?? false
                uploadLimitEnabled = session.speedLimitUpEnabled ?? false

                scheduleEnabled = session.altSpeedTimeEnabled ?? false
                let beginMinutes = session.altSpeedTimeBegin ?? minutes(from: scheduleBeginTime)
                let endMinutes = session.altSpeedTimeEnd ?? minutes(from: scheduleEndTime)
                scheduleBeginTime = timeFromMinutes(beginMinutes)
                scheduleEndTime = timeFromMinutes(endMinutes)
                if let dayMask = session.altSpeedTimeDay {
                    scheduleDays = ScheduleDay.fromMask(dayMask)
                }

                blocklistEnabled = session.blocklistEnabled ?? false
                blocklistURL = session.blocklistURL ?? ""
                blocklistSize = session.blocklistSize ?? 0

                peerPort = session.peerPort ?? peerPort
                randomOnStart = session.peerPortRandomOnStart ?? false
                portOpen = session.portIsOpen
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func applySessionSettings() async {
        guard let service = selectedService else { return }
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            let client = TransmissionRPCClient(
                config: service,
                allowInsecureTLS: preferences.allowInsecureTLS
            )
            let args = SessionSetPeerLimitsArguments(
                encryption: encryption.rawValue,
                peerLimitGlobal: peerLimitGlobal,
                peerLimitPerTorrent: peerLimitPerTorrent
            )
            let _: EmptyResponse = try await client.request(method: "session-set", arguments: args)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func applyBandwidthLimits() async {
        guard let service = selectedService else { return }
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        let args = SessionSetArguments(
            speedLimitDown: downloadLimit,
            speedLimitDownEnabled: downloadLimitEnabled,
            speedLimitUp: uploadLimit,
            speedLimitUpEnabled: uploadLimitEnabled,
            altSpeedTimeEnabled: scheduleEnabled,
            altSpeedTimeBegin: minutes(from: scheduleBeginTime),
            altSpeedTimeEnd: minutes(from: scheduleEndTime),
            altSpeedTimeDay: ScheduleDay.mask(from: scheduleDays)
        )

        do {
            let client = TransmissionRPCClient(
                config: service,
                allowInsecureTLS: preferences.allowInsecureTLS
            )
            let _: EmptyResponse = try await client.request(
                method: "session-set",
                arguments: args
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func applyBlocklistSettings() async {
        guard let service = selectedService else { return }
        let trimmedURL = blocklistURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedURL.isEmpty else {
            errorMessage = "Blocklist URL is required."
            return
        }

        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            let client = TransmissionRPCClient(
                config: service,
                allowInsecureTLS: preferences.allowInsecureTLS
            )
            let args = SessionSetBlocklistArguments(blocklistEnabled: blocklistEnabled, blocklistURL: trimmedURL)
            let _: EmptyResponse = try await client.request(method: "session-set", arguments: args)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func updateBlocklist() async {
        guard let service = selectedService else { return }
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            let client = TransmissionRPCClient(
                config: service,
                allowInsecureTLS: preferences.allowInsecureTLS
            )
            let response: BlocklistUpdateResponseArguments = try await client.request(
                method: "blocklist-update",
                arguments: EmptyArguments()
            )
            blocklistSize = response.blocklistSize
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func applyPortSettings() async {
        guard let service = selectedService else { return }
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            let client = TransmissionRPCClient(
                config: service,
                allowInsecureTLS: preferences.allowInsecureTLS
            )
            let args = SessionSetPortArguments(peerPort: peerPort, peerPortRandomOnStart: randomOnStart)
            let _: EmptyResponse = try await client.request(method: "session-set", arguments: args)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func testPort() async {
        guard let service = selectedService else { return }
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            let client = TransmissionRPCClient(
                config: service,
                allowInsecureTLS: preferences.allowInsecureTLS
            )
            let response: PortTestResponseArguments = try await client.request(
                method: "port-test",
                arguments: EmptyArguments()
            )
            portOpen = response.portIsOpen
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private var portStatusText: String {
        switch portOpen {
        case true: return "Open"
        case false: return "Closed"
        default: return "Unknown"
        }
    }

    private var portStatusColor: Color {
        switch portOpen {
        case true: return .green
        case false: return .red
        default: return .secondary
        }
    }

    private var selectedService: ServiceConfig? {
        let configured = serviceStore.service(id: appState.selectedServiceID)
        if let configured {
            return configured
        }
        return serviceStore.services.first
    }

    private static func defaultTime(hour: Int, minute: Int) -> Date {
        Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
    }

    private func timeFromMinutes(_ minutes: Int) -> Date {
        let clamped = max(0, min(1439, minutes))
        let hour = clamped / 60
        let minute = clamped % 60
        return TransmissionSettingsView.defaultTime(hour: hour, minute: minute)
    }

    private func minutes(from date: Date) -> Int {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
        let hour = max(0, min(23, comps.hour ?? 0))
        let minute = max(0, min(59, comps.minute ?? 0))
        return hour * 60 + minute
    }

    private enum ScheduleDay: Int, CaseIterable {
        case sunday = 1
        case monday = 2
        case tuesday = 4
        case wednesday = 8
        case thursday = 16
        case friday = 32
        case saturday = 64

        var label: String {
            switch self {
            case .sunday: return "S"
            case .monday: return "M"
            case .tuesday: return "T"
            case .wednesday: return "W"
            case .thursday: return "T"
            case .friday: return "F"
            case .saturday: return "S"
            }
        }

        static func mask(from days: Set<ScheduleDay>) -> Int {
            days.reduce(0) { $0 | $1.rawValue }
        }

        static func fromMask(_ mask: Int) -> Set<ScheduleDay> {
            Set(allCases.filter { mask & $0.rawValue != 0 })
        }
    }

    private enum EncryptionMode: String, CaseIterable, Identifiable {
        case required
        case preferred
        case tolerated

        init(_ rawValue: String?) {
            switch rawValue {
            case "required": self = .required
            case "tolerated": self = .tolerated
            default: self = .preferred
            }
        }

        var id: String { rawValue }

        var label: String {
            switch self {
            case .required: return "Required"
            case .preferred: return "Preferred"
            case .tolerated: return "Tolerated"
            }
        }
    }

    private enum SectionID: String {
        case session
        case bandwidth
        case blocklist
        case port
    }
}
