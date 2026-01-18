import SwiftUI

struct BandwidthLimitsView: View {
    @EnvironmentObject private var serviceStore: ServiceStore
    @EnvironmentObject private var appState: AppState
    @State private var isLoadingSession = false
    @State private var sessionError: String?
    @State private var downloadLimitEnabled = false
    @State private var uploadLimitEnabled = false
    @State private var downloadLimit = 1000
    @State private var uploadLimit = 200
    @State private var scheduleEnabled = false
    @State private var scheduleBeginTime = BandwidthLimitsView.defaultTime(hour: 8, minute: 0)
    @State private var scheduleEndTime = BandwidthLimitsView.defaultTime(hour: 18, minute: 0)
    @State private var scheduleDays: Set<ScheduleDay> = Set(ScheduleDay.allCases)

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Bandwidth Limits")
                    .font(.title2.weight(.semibold))
                Spacer()
                if isLoadingSession {
                    ProgressView()
                        .controlSize(.small)
                }
            }

            VStack(alignment: .leading, spacing: 16) {
                limitRow(
                    title: "Download",
                    isEnabled: $downloadLimitEnabled,
                    value: $downloadLimit,
                    toggleLabel: "Limit download speed"
                )

                Divider()

                limitRow(
                    title: "Upload",
                    isEnabled: $uploadLimitEnabled,
                    value: $uploadLimit,
                    toggleLabel: "Limit upload speed"
                )

                Divider()

                scheduleSection
            }

            if let sessionError {
                Text(sessionError)
                    .font(.caption)
                    .foregroundColor(.red)
            }

            HStack {
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
                Button("OK") {
                    applySessionLimits()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(20)
        .frame(minWidth: 420)
        .onAppear(perform: loadSessionLimits)
        .onChange(of: appState.selectedServiceID) { _, _ in
            loadSessionLimits()
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

    private func loadSessionLimits() {
        guard let service = selectedService else {
            sessionError = "Select a service to edit bandwidth limits."
            return
        }
        sessionError = nil
        isLoadingSession = true
        Task {
            defer { isLoadingSession = false }
            do {
                let client = TransmissionRPCClient(config: service)
                let session: SessionGetResponseArguments = try await client.request(
                    method: "session-get",
                    arguments: SessionGetArguments()
                )
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
            } catch {
                sessionError = error.localizedDescription
            }
        }
    }

    private func applySessionLimits() {
        guard let service = selectedService else { return }
        sessionError = nil
        isLoadingSession = true
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
        Task {
            defer { isLoadingSession = false }
            do {
                let client = TransmissionRPCClient(config: service)
                let _: EmptyResponse = try await client.request(
                    method: "session-set",
                    arguments: args
                )
            } catch {
                sessionError = error.localizedDescription
            }
        }
    }


    private static func defaultTime(hour: Int, minute: Int) -> Date {
        Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
    }

    private func timeFromMinutes(_ minutes: Int) -> Date {
        let clamped = max(0, min(1439, minutes))
        let hour = clamped / 60
        let minute = clamped % 60
        return BandwidthLimitsView.defaultTime(hour: hour, minute: minute)
    }

    private func minutes(from date: Date) -> Int {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
        let hour = max(0, min(23, comps.hour ?? 0))
        let minute = max(0, min(59, comps.minute ?? 0))
        return hour * 60 + minute
    }

    private var selectedService: ServiceConfig? {
        let configured = serviceStore.service(id: appState.selectedServiceID)
        if let configured {
            return configured
        }
        return serviceStore.services.first
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

}
