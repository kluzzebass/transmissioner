import SwiftUI

struct MainWindowView: View {
    @EnvironmentObject private var serviceStore: ServiceStore
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var preferences: PreferencesStore
    @StateObject private var viewModel = TorrentListViewModel()
    @State private var showingAddTorrent = false

    var body: some View {
        VStack(spacing: 12) {
            toolbar

            if selectedService != nil {
                TorrentListView(viewModel: viewModel, compact: false)
            } else {
                Text("Add a Transmission service in Settings to get started.")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding(16)
        .onAppear(perform: configureViewModel)
        .onChange(of: appState.selectedServiceID) { _, _ in configureViewModel() }
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

    private var toolbar: some View {
        HStack(spacing: 12) {
            if let selection = serviceSelectionBinding {
                Picker("Service", selection: selection) {
                    ForEach(serviceStore.services) { service in
                        Text(service.name).tag(service.id)
                    }
                }
                .frame(width: 200)
            } else {
                Text("No services")
                    .foregroundColor(.secondary)
            }

            Button("Refresh") { Task { await viewModel.refresh() } }
            Button("Start All") { Task { await viewModel.start() } }
            Button("Stop All") { Task { await viewModel.stop() } }
            Button("Add Torrent") { showingAddTorrent = true }

            Spacer()

            Toggle("Auto Refresh", isOn: $preferences.autoRefresh)
                .toggleStyle(.switch)
                .frame(width: 140)
        }
    }

    private var selectedService: ServiceConfig? {
        let configured = serviceStore.service(id: appState.selectedServiceID)
        if let configured {
            return configured
        }
        return serviceStore.services.first
    }

    private var serviceSelectionBinding: Binding<UUID>? {
        guard let first = serviceStore.services.first else { return nil }
        return Binding(
            get: { appState.selectedServiceID ?? first.id },
            set: { newValue in appState.selectedServiceID = newValue }
        )
    }

    private func configureViewModel() {
        if appState.selectedServiceID == nil, let first = serviceStore.services.first {
            appState.selectedServiceID = first.id
        }
        viewModel.configure(with: selectedService)
    }
}
