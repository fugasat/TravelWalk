import Foundation

class WalkingDistance: Codable {
    
    var distance: Double // meter
    var toDate: Date // ここで指定した日付の前日の23:59:59までは取得済
    
    init(distance: Double, toDate: Date) {
        self.distance = distance
        self.toDate = toDate
    }

    // MARK: Codable

    enum CodingKeys: String, CodingKey {
        case distance
        case toDate
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.distance, forKey: .distance)
        try container.encode(self.toDate, forKey: .toDate)
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.distance = try container.decode(Double.self, forKey: .distance)
        self.toDate = try container.decode(Date.self, forKey: .toDate)
    }
}
