import AppKit
import Combine
import SwiftUI

struct MenuBarPopoverView: View {
    @EnvironmentObject private var serviceStore: ServiceStore
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var preferences: PreferencesStore
    @Environment(\.openWindow) private var openWindow
    @StateObject private var viewModel = TorrentListViewModel()
    @State private var showingAddTorrent = false

    var body: some View {
        VStack(spacing: 12) {
            header

            if selectedService != nil {
                TorrentListView(viewModel: viewModel, compact: true)

                HStack(spacing: 8) {
                    Button("Start All") {
                        Task { await viewModel.start() }
                    }
                    Button("Stop All") {
                        Task { await viewModel.stop() }
                    }
                    Spacer()
                    Button("Settings", action: openSettings)
                }
                .buttonStyle(.bordered)
            } else {
                emptyState
            }
        }
        .padding(12)
        .frame(width: 420)
        .onAppear(perform: configureViewModel)
        .onChange(of: appState.selectedServiceID) { _, _ in configureViewModel() }
        .onReceive(refreshTimer) { _ in
            guard preferences.autoRefresh, selectedService != nil else { return }
            Task { await viewModel.refresh() }
        }
        .sheet(isPresented: $showingAddTorrent) {
            AddTorrentView(
                onAdd: { link, dir in
                    showingAddTorrent = false
                    Task { await viewModel.addTorrent(magnetLink: link, downloadDir: dir) }
                },
                onCancel: { showingAddTorrent = false }
            )
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Menu {
                ForEach(serviceStore.services) { service in
                    Button(service.name) {
                        appState.selectedServiceID = service.id
                    }
                }
                if !serviceStore.services.isEmpty {
                    Divider()
                }
                Button("Manage Services", action: openSettings)
            } label: {
                Label(selectedService?.name ?? "No Service", systemImage: "antenna.radiowaves.left.and.right")
            }

            Spacer()

            Button {
                Task { await viewModel.refresh() }
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .help("Refresh")

            Button {
                showingAddTorrent = true
            } label: {
                Image(systemName: "plus")
            }
            .help("Add Torrent")
            .disabled(selectedService == nil)

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Image(systemName: "power")
            }
            .help("Quit")
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Text("No Transmission services configured.")
                .font(.headline)
            Text("Add your first service in Settings.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Button("Open Settings", action: openSettings)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }

    private var selectedService: ServiceConfig? {
        let configured = serviceStore.service(id: appState.selectedServiceID)
        if let configured {
            return configured
        }
        return serviceStore.services.first
    }

    private var refreshTimer: Publishers.Autoconnect<Timer.TimerPublisher> {
        Timer.publish(every: max(5, preferences.autoRefreshInterval), on: .main, in: .common)
            .autoconnect()
    }

    private func configureViewModel() {
        if appState.selectedServiceID == nil, let first = serviceStore.services.first {
            appState.selectedServiceID = first.id
        }
        viewModel.configure(with: selectedService)
    }

    private func openSettings() {
        openWindow(id: "settings")
    }
}
