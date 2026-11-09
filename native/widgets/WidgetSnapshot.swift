import Foundation

struct DogSnapshot: Decodable {
    let schemaVersion: Int
    let updatedAt: Double
    let needs: [Double]
    let decayRates: [Double]
    let restRate: Double
    let breed: String
    let stage: String
    let growth: Double
    let artwork: String

    var isValid: Bool {
        schemaVersion == 1 && updatedAt.isFinite && updatedAt > 0 &&
        needs.count == 4 && needs.allSatisfy { $0.isFinite && (0...100).contains($0) } &&
        decayRates.count == 4 && decayRates.allSatisfy { $0.isFinite && (0...1).contains($0) } &&
        restRate.isFinite && (0...1).contains(restRate) &&
        growth.isFinite && (0...1).contains(growth) &&
        ["Puppy", "Shiba Inu", "Golden Retriever", "Dachshund", "Miniature Collie", "Beagle", "Corgi", "Toy Poodle"].contains(breed) &&
        !stage.isEmpty && stage.count <= 40 && artwork.utf8.count <= 2 * 1024 * 1024
    }

    static func decode(_ data: Data) -> DogSnapshot? {
        guard data.count <= 4 * 1024 * 1024,
              let value = try? JSONDecoder().decode(Self.self, from: data), value.isValid,
              let png = Data(base64Encoded: value.artwork),
              png.starts(with: [137, 80, 78, 71, 13, 10, 26, 10]) else { return nil }
        return value
    }

    func values(at date: Date) -> [Double] {
        // Same offline horizon and order of operations as Game.advance(..., false).
        let elapsed = min(7200, max(0, date.timeIntervalSince1970 - updatedAt))
        var values = zip(needs, decayRates).map { need, rate in max(0, min(100, need - elapsed * rate)) }
        values[2] = min(100, values[2] + elapsed * restRate)
        return values
    }

    func dates(from now: Date) -> [Date] {
        // A changed phone clock must not create an unbounded future timeline.
        guard now.timeIntervalSince1970 >= updatedAt else { return [now] }
        let end = Date(timeIntervalSince1970: updatedAt + 7200)
        var dates = [now]
        var next = now.addingTimeInterval(900)
        while next < end {
            dates.append(next)
            next = next.addingTimeInterval(900)
        }
        if end > now { dates.append(end) }
        return dates
    }
}
