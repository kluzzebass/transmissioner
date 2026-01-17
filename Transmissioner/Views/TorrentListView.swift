import SwiftUI

struct TorrentListView: View {
    @ObservedObject var viewModel: TorrentListViewModel
    let compact: Bool

    var body: some View {
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
                        onVerify: { Task { await viewModel.verify(ids: [torrent.id]) } },
                        onReannounce: { Task { await viewModel.reannounce(ids: [torrent.id]) } }
                    )
                    .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
                }
            }
            .listStyle(.inset)
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
