import SwiftUI

struct TorrentListView: View {
    @ObservedObject var viewModel: TorrentListViewModel
    let compact: Bool
    @State private var pendingDelete: TorrentInfo?

    var body: some View {
        ZStack {
            VStack(spacing: 8) {
                if let lastError = viewModel.lastError {
                    Text(lastError)
                        .foregroundColor(.red)
                        .font(.caption)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                List {
                    ForEach(viewModel.torrents) { torrent in
                        TorrentRowView(
                            torrent: torrent,
                            onToggle: { Task { await toggle(torrent) } },
                            onRemove: { Task { await remove(torrent) } },
                            onRemoveWithData: { pendingDelete = torrent },
                            onVerify: { Task { await viewModel.verify(ids: [torrent.id]) } },
                            onReannounce: { Task { await viewModel.reannounce(ids: [torrent.id]) } }
                        )
                        .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
                    }
                }
                .listStyle(.inset)
            }

            if let torrent = pendingDelete {
                Color.black.opacity(0.25)
                    .ignoresSafeArea()
                    .onTapGesture {
                        pendingDelete = nil
                    }

                VStack(spacing: 12) {
                    Text("Remove & Delete Data")
                        .font(.headline)
                    Text("This will remove “\(torrent.name)” and delete its local data.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    HStack {
                        Button("Cancel") {
                            pendingDelete = nil
                        }
                        Spacer()
                        Button("Delete") {
                            pendingDelete = nil
                            Task { await viewModel.remove(ids: [torrent.id], deleteData: true) }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
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
}
