import SwiftUI

struct TorrentListView: View {
    @ObservedObject var viewModel: TorrentListViewModel
    let compact: Bool
    let onUserInteraction: () -> Void
    @State private var pendingRemoval: PendingRemoval?
    @State private var searchText = ""
    @State private var statusFilter: StatusFilter = .all
    @State private var sortOrder: SortOrder = .name

    var body: some View {
        ZStack {
            VStack(spacing: 8) {
                filterRow

                if viewModel.isLoading {
                    HStack(spacing: 8) {
                        ProgressView()
                            .controlSize(.small)
                        Text("Connecting to Transmission…")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                if let lastError = viewModel.lastError {
                    Text(lastError)
                        .foregroundColor(.red)
                        .font(.caption)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                List {
                    ForEach(filteredTorrents) { torrent in
                        TorrentRowView(
                            torrent: torrent,
                            globalSeedRatioLimit: viewModel.sessionSeedRatioLimit,
                            globalSeedRatioLimited: viewModel.sessionSeedRatioLimited,
                            onToggle: { Task { await toggle(torrent) } },
                            onRequestRemove: { pendingRemoval = PendingRemoval(torrent: torrent, deleteData: false) },
                            onRequestRemoveWithData: { pendingRemoval = PendingRemoval(torrent: torrent, deleteData: true) },
                            onVerify: { Task { await viewModel.verify(ids: [torrent.id]) } },
                            onReannounce: { Task { await viewModel.reannounce(ids: [torrent.id]) } }
                        )
                        .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
                    }
                }
                .listStyle(.inset)
            }

            if viewModel.isLoading && viewModel.torrents.isEmpty {
                VStack(spacing: 8) {
                    ProgressView()
                    Text("Loading torrents…")
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
            }

        if let pending = pendingRemoval {
                Color.black.opacity(0.25)
                    .ignoresSafeArea()
                    .onTapGesture {
                    pendingRemoval = nil
                    }

                VStack(spacing: 12) {
                Text(pending.deleteData ? "Remove & Delete Data" : "Remove Torrent")
                        .font(.headline)
                Text(pending.deleteData
                     ? "This will remove “\(pending.torrent.name)” and delete its local data."
                     : "This will remove “\(pending.torrent.name)” from Transmission.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    HStack {
                        Button("Cancel") {
                        pendingRemoval = nil
                        }
                        Spacer()
                    Button(pending.deleteData ? "Delete Data" : "Remove") {
                        pendingRemoval = nil
                        Task { await viewModel.remove(ids: [pending.torrent.id], deleteData: pending.deleteData) }
                        }
                    .buttonStyle(.borderedProminent)
                    .tint(pending.deleteData ? .red : .accentColor)
                    }
                }
                .padding(16)
                .frame(maxWidth: 360)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
                .shadow(radius: 10)
            .padding(20)
            }
        }
        .frame(minHeight: compact ? 220 : 320)
    }

    private func toggle(_ torrent: TorrentInfo) async {
        if torrent.isActive {
            await viewModel.stop(ids: [torrent.id])
        } else {
            await viewModel.start(ids: [torrent.id])
        }
    }

    private func remove(_ torrent: TorrentInfo) async {
        await viewModel.remove(ids: [torrent.id], deleteData: false)
    }

    private struct PendingRemoval: Identifiable {
        let id = UUID()
        let torrent: TorrentInfo
        let deleteData: Bool
    }

    private var filterRow: some View {
        HStack(spacing: 8) {
            TextField("Search torrents", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .onChange(of: searchText) { _, _ in
                    onUserInteraction()
                }

            Menu {
                Picker("Status", selection: $statusFilter) {
                    ForEach(StatusFilter.allCases) { filter in
                        Text(filter.label).tag(filter)
                    }
                }
                .onChange(of: statusFilter) { _, _ in
                    onUserInteraction()
                }
            } label: {
                Label(statusFilter.label, systemImage: "line.3.horizontal.decrease.circle")
            }
            .onTapGesture {
                onUserInteraction()
            }

            Menu {
                Picker("Sort", selection: $sortOrder) {
                    ForEach(SortOrder.allCases) { order in
                        Text(order.label).tag(order)
                    }
                }
                .onChange(of: sortOrder) { _, _ in
                    onUserInteraction()
                }
            } label: {
                Label(sortOrder.label, systemImage: "arrow.up.arrow.down")
            }
            .onTapGesture {
                onUserInteraction()
            }
        }
    }

    private var filteredTorrents: [TorrentInfo] {
        var result = viewModel.torrents

        if !searchText.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }

        result = result.filter { statusFilter.matches($0) }

        switch sortOrder {
        case .name:
            return result.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .progress:
            return result.sorted { $0.percentDone > $1.percentDone }
        case .eta:
            return result.sorted { $0.eta < $1.eta }
        case .activity:
            return result.sorted { $0.isActive && !$1.isActive }
        }
    }

    private enum StatusFilter: String, CaseIterable, Identifiable {
        case all
        case downloading
        case seeding
        case completed
        case stopped
        case error

        var id: String { rawValue }

        var label: String {
            switch self {
            case .all: return "All"
            case .downloading: return "Downloading"
            case .seeding: return "Seeding"
            case .completed: return "Completed"
            case .stopped: return "Stopped"
            case .error: return "Error"
            }
        }

        func matches(_ torrent: TorrentInfo) -> Bool {
            switch self {
            case .all:
                return true
            case .error:
                return (torrent.errorString?.isEmpty == false)
            case .downloading:
                return torrent.status == TransmissionStatus.downloading.rawValue
            case .seeding:
                return torrent.status == TransmissionStatus.seeding.rawValue
            case .completed:
                return torrent.isFinished
            case .stopped:
                return torrent.status == TransmissionStatus.stopped.rawValue
            }
        }
    }

    private enum SortOrder: String, CaseIterable, Identifiable {
        case name
        case progress
        case eta
        case activity

        var id: String { rawValue }

        var label: String {
            switch self {
            case .name: return "Name"
            case .progress: return "Progress"
            case .eta: return "ETA"
            case .activity: return "Active"
            }
        }
    }
}
