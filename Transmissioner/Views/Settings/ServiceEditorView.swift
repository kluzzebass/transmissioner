import SwiftUI

struct ServiceEditorView: View {
    struct Draft {
        var name: String
        var baseURL: String
        var rpcPath: String
        var username: String
        var password: String

        init(service: ServiceConfig?) {
            name = service?.name ?? "Transmission"
            baseURL = service?.baseURL.absoluteString ?? "http://localhost:9091"
            rpcPath = service?.rpcPath ?? "transmission/rpc"
            username = service?.username ?? ""
            password = service?.password ?? ""
        }
    }

    let service: ServiceConfig?
    let onSave: (ServiceConfig) -> Void
    let onCancel: () -> Void

    @State private var draft: Draft
    @State private var errorMessage: String?
    @State private var testMessage: String?
    @State private var isTesting = false

    init(service: ServiceConfig?, onSave: @escaping (ServiceConfig) -> Void, onCancel: @escaping () -> Void) {
        self.service = service
        self.onSave = onSave
        self.onCancel = onCancel
        _draft = State(initialValue: Draft(service: service))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(service == nil ? "Add Service" : "Edit Service")
                .font(.title2.weight(.semibold))

            Form {
                TextField("Name", text: $draft.name)
                TextField("Base URL", text: $draft.baseURL)
                TextField("RPC Path", text: $draft.rpcPath)
                TextField("Username", text: $draft.username)
                SecureField("Password", text: $draft.password)
            }

            if let errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }

            if let testMessage {
                Text(testMessage)
                    .foregroundColor(isTesting ? .secondary : .green)
                    .font(.caption)
            }

            HStack {
                Button("Cancel", action: onCancel)
                Spacer()
                Button(isTesting ? "Testing..." : "Test Connection") {
                    Task { await testConnection() }
                }
                .disabled(isTesting)
                Button("Save") {
                    save()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 460)
        .interactiveDismissDisabled(true)
    }

    private func save() {
        errorMessage = nil
        guard let url = URL(string: draft.baseURL), url.scheme != nil else {
            errorMessage = "Please enter a valid URL including the scheme."
            return
        }
        guard !draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Service name cannot be empty."
            return
        }

        let config = ServiceConfig(
            id: service?.id ?? UUID(),
            name: draft.name,
            baseURL: url,
            rpcPath: draft.rpcPath.isEmpty ? "transmission/rpc" : draft.rpcPath,
            username: draft.username,
            password: draft.password
        )
        onSave(config)
    }

    private func testConnection() async {
        errorMessage = nil
        testMessage = nil
        guard let url = URL(string: draft.baseURL), url.scheme != nil else {
            errorMessage = "Please enter a valid URL including the scheme."
            return
        }

        isTesting = true
        defer { isTesting = false }

        let config = ServiceConfig(
            id: service?.id ?? UUID(),
            name: draft.name,
            baseURL: url,
            rpcPath: draft.rpcPath.isEmpty ? "transmission/rpc" : draft.rpcPath,
            username: draft.username,
            password: draft.password
        )

        let client = TransmissionRPCClient(config: config)
        do {
            let response: SessionGetResponseArguments = try await client.request(
                method: "session-get",
                arguments: SessionGetArguments()
            )
            if let version = response.version {
                testMessage = "Connected to Transmission \(version)."
            } else {
                testMessage = "Connected."
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
