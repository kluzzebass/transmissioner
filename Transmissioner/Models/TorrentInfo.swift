import Foundation

struct TorrentInfo: Identifiable, Decodable, Equatable {
    let id: Int
    let name: String
    let status: Int
    let percentDone: Double
    let rateDownload: Int
    let rateUpload: Int
    let eta: Int
    let isFinished: Bool
    let totalSize: Int
    let error: Int?
    let errorString: String?
    let uploadRatio: Double

    static let defaultFields = [
        "id",
        "name",
        "status",
        "percentDone",
        "rateDownload",
        "rateUpload",
        "eta",
        "isFinished",
        "totalSize",
        "error",
        "errorString",
        "uploadRatio"
    ]

    var isStopped: Bool {
        status == TransmissionStatus.stopped.rawValue
    }

    var isActive: Bool {
        status == TransmissionStatus.downloading.rawValue || status == TransmissionStatus.seeding.rawValue
    }
}

enum TransmissionStatus: Int {
    case stopped = 0
    case checkWait = 1
    case checking = 2
    case downloadWait = 3
    case downloading = 4
    case seedWait = 5
    case seeding = 6
}
