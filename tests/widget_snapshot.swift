import Foundation

func check(_ condition: @autoclosure () -> Bool, _ message: String) {
    if !condition() { fatalError(message) }
}

let pngHeader = Data([137, 80, 78, 71, 13, 10, 26, 10]).base64EncodedString()
var raw: [String: Any] = ["schemaVersion": 1, "updatedAt": 1700000000.0,
    "needs": [80.0, 80.0, 90.0, 85.0], "decayRates": [0.0012, 0.00075, 0.0009, 0.000975],
    "restRate": 0.0, "growth": 0.2, "breed": "Puppy", "stage": "Tiny puppy", "artwork": pngHeader]
func decode(_ value: [String: Any]) -> DogSnapshot? {
    DogSnapshot.decode(try! JSONSerialization.data(withJSONObject: value))
}
let snapshot = decode(raw)!
for breed in ["Dachshund", "Miniature Collie", "Beagle", "Corgi", "Toy Poodle"] {
    var grown = raw
    grown["breed"] = breed
    grown["stage"] = "Adult"
    check(decode(grown) != nil, "New grown-up breeds remain valid widget snapshots: \(breed)")
}
let start = Date(timeIntervalSince1970: snapshot.updatedAt)
check(snapshot.values(at: start) == snapshot.needs, "Fresh care values must match the save")
check(snapshot.values(at: start.addingTimeInterval(-3600)) == snapshot.needs, "Clock rollback must not create care changes")
let twoHours = snapshot.values(at: start.addingTimeInterval(7200))
check(abs(twoHours[0] - 71.36) < 0.00001, "Offline hunger uses the game rate")
check(twoHours == snapshot.values(at: start.addingTimeInterval(86400 * 30)), "Offline changes stop after two hours")
let dates = snapshot.dates(from: start)
check(dates.count == 9 && dates.last == start.addingTimeInterval(7200), "A finite timeline includes the offline cap")
check(snapshot.dates(from: start.addingTimeInterval(86400)).count == 1, "No repeated background updates after the cap")
check(snapshot.dates(from: start.addingTimeInterval(-86400 * 365)).count == 1, "A clock rollback cannot generate thousands of timeline entries")
raw["restRate"] = 0.65
check(decode(raw)!.values(at: start.addingTimeInterval(20))[2] > 99, "Rest recovery is reflected")
raw["needs"] = [1.0, 1.0, 1.0, 1.0]
raw["restRate"] = 0.0
check(decode(raw)!.values(at: start.addingTimeInterval(7200)).allSatisfy { $0 >= 0 }, "Bars never become negative")
for key in ["schemaVersion", "needs", "artwork", "updatedAt"] {
    var broken = raw
    broken.removeValue(forKey: key)
    check(decode(broken) == nil, "Missing required field must fall back safely: \(key)")
}
for (key, value) in [("schemaVersion", 2 as Any), ("needs", [1, 2, 3] as Any),
                     ("growth", -1 as Any), ("artwork", "not a png" as Any), ("breed", "Unknown" as Any)] {
    var broken = raw
    broken[key] = value
    check(decode(broken) == nil, "Invalid field must fall back safely: \(key)")
}
if CommandLine.arguments.count > 1 {
    let data = try! Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1]))
    let fixture = try! JSONSerialization.jsonObject(with: data) as! [String: Any]
    let expected = fixture["expected"] as! [Double]
    let saved = decode(fixture["snapshot"] as! [String: Any])!
    let actual = saved.values(at: Date(timeIntervalSince1970: fixture["at"] as! Double))
    check(zip(expected, actual).allSatisfy { expected, actual in abs(expected - actual) < 0.00001 }, "Swift projection must match actual Godot offline care")
}
print("Widget snapshot tests passed")
