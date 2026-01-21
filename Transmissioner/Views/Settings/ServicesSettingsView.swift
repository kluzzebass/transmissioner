import SwiftUI

struct ServicesSettingsView: View {
    @Binding var services: [ServiceConfig]
    @State private var editingService: ServiceConfig?
    @State private var editorID = UUID()
    @State private var showingAddEditor = false

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Transmission Services")
                    .font(.title2.weight(.semibold))
                Spacer()
                Button("Add Service") {
                    editorID = UUID()
                    showingAddEditor = true
                }
            }

            List {
                ForEach(services) { service in
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
                            services.removeAll { $0.id == service.id }
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
        .sheet(item: $editingService) { service in
            ServiceEditorView(service: service) { updated in
                if let index = services.firstIndex(where: { $0.id == updated.id }) {
                    services[index] = updated
                } else {
                    services.append(updated)
                }
                editingService = nil
            } onCancel: {
                editingService = nil
            }
        }
        .sheet(isPresented: $showingAddEditor) {
            ServiceEditorView(service: nil) { updated in
                services.append(updated)
                showingAddEditor = false
            } onCancel: {
                showingAddEditor = false
            }
            .id(editorID)
        }
    }

    private func move(_ service: ServiceConfig, direction: Int) {
        guard let index = services.firstIndex(of: service) else { return }
        let destination = max(0, min(services.count, index + direction))
        let moving = services[index]
        services.remove(at: index)
        let insertIndex = min(destination, services.count)
        services.insert(moving, at: insertIndex)
    }

    private func isFirst(_ service: ServiceConfig) -> Bool {
        services.first == service
    }

    private func isLast(_ service: ServiceConfig) -> Bool {
        services.last == service
    }
}
