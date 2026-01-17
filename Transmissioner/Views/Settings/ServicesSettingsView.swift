import SwiftUI

struct ServicesSettingsView: View {
    @EnvironmentObject private var serviceStore: ServiceStore
    @State private var editingService: ServiceConfig?
    @State private var showingEditor = false

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Transmission Services")
                    .font(.title2.weight(.semibold))
                Spacer()
                Button("Add Service") {
                    editingService = nil
                    showingEditor = true
                }
            }

            List {
                ForEach(serviceStore.services) { service in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(service.name)
                                .font(.headline)
                            Text(service.rpcURL.absoluteString)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button("Edit") {
                            editingService = service
                            showingEditor = true
                        }
                        Button {
                            move(service, direction: -1)
                        } label: {
                            Image(systemName: "chevron.up")
                        }
                        .buttonStyle(.borderless)
                        .help("Move Up")
                        .disabled(isFirst(service))

                        Button {
                            move(service, direction: 1)
                        } label: {
                            Image(systemName: "chevron.down")
                        }
                        .buttonStyle(.borderless)
                        .help("Move Down")
                        .disabled(isLast(service))

                        Button(role: .destructive) {
                            serviceStore.remove(service)
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.borderless)
                    }
                }
            }
            .listStyle(.inset)

            Spacer()
        }
        .padding(16)
        .sheet(isPresented: $showingEditor) {
            ServiceEditorView(service: editingService) { updated in
                if serviceStore.services.contains(where: { $0.id == updated.id }) {
                    serviceStore.update(updated)
                } else {
                    serviceStore.add(updated)
                }
                showingEditor = false
            } onCancel: {
                showingEditor = false
            }
        }
    }

    private func move(_ service: ServiceConfig, direction: Int) {
        guard let index = serviceStore.services.firstIndex(of: service) else { return }
        let destination = max(0, min(serviceStore.services.count, index + direction))
        serviceStore.move(from: IndexSet(integer: index), to: destination)
    }

    private func isFirst(_ service: ServiceConfig) -> Bool {
        serviceStore.services.first == service
    }

    private func isLast(_ service: ServiceConfig) -> Bool {
        serviceStore.services.last == service
    }
}
