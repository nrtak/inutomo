import SwiftUI
import WidgetKit
import UIKit

private let careNames = ["Hunger", "Happiness", "Energy", "Cleanliness"]
private let iconNames = ["CareFood", "CareHappy", "CareEnergy", "CareClean"]
private let careColors: [Color] = [Color(red: 0.98, green: 0.68, blue: 0.23),
    Color(red: 0.94, green: 0.49, blue: 0.59), Color(red: 0.64, green: 0.49, blue: 0.86),
    Color(red: 0.20, green: 0.69, blue: 0.76)]

struct DogEntry: TimelineEntry {
    let date: Date
    let snapshot: DogSnapshot?
    let artwork: UIImage?
    let preview: Bool
}

struct DogProvider: TimelineProvider {
    func placeholder(in context: Context) -> DogEntry {
        DogEntry(date: Date(), snapshot: nil, artwork: nil, preview: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (DogEntry) -> Void) {
        let saved = readSnapshot()
        completion(entry(at: Date(), saved: saved, preview: context.isPreview))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DogEntry>) -> Void) {
        let now = Date()
        guard let saved = readSnapshot() else {
            // Shared data may be temporarily locked after a device restart.
            // Retry instead of freezing an empty widget until the next app visit.
            completion(Timeline(entries: [entry(at: now, saved: nil, preview: false)],
                                policy: .after(now.addingTimeInterval(900))))
            return
        }
        let dates = saved.0.dates(from: now)
        completion(Timeline(entries: dates.map { entry(at: $0, saved: saved, preview: false) }, policy: .never))
    }

    private func entry(at date: Date, saved: (DogSnapshot, UIImage)?, preview: Bool) -> DogEntry {
        DogEntry(date: date, snapshot: saved?.0, artwork: saved?.1, preview: preview)
    }

    private func readSnapshot() -> (DogSnapshot, UIImage)? {
        guard let group = Bundle.main.object(forInfoDictionaryKey: "InushimaAppGroup") as? String,
              let folder = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: group) else { return nil }
        let path = folder.appendingPathComponent("dog-widget.json")
        guard let size = try? path.resourceValues(forKeys: [.fileSizeKey]).fileSize,
              size <= 4 * 1024 * 1024,
              let data = try? Data(contentsOf: path), let snapshot = DogSnapshot.decode(data),
              let png = Data(base64Encoded: snapshot.artwork), let image = UIImage(data: png),
              image.size.width <= 512, image.size.height <= 512 else { return nil }
        return (snapshot, image)
    }
}

private struct OriginalImage: View {
    let image: Image
    var body: some View {
        if #available(iOS 18.0, *) {
            image.resizable().widgetAccentedRenderingMode(.fullColor).scaledToFit()
        } else {
            image.resizable().scaledToFit()
        }
    }
}

private struct CareGrid: View {
    let values: [Double]?
    let medium: Bool

    var body: some View {
        GeometryReader { geometry in
            let gap: CGFloat = medium ? 12 : 8
            let row = (geometry.size.height - gap) / 2
            let icon = min(medium ? 34 : 24, max(12, row - 11))
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: gap) {
                ForEach(0..<4) { index in
                    VStack(spacing: 3) {
                        // An Image modifier preserves the colored art in Clear/Tinted mode.
                        OriginalImage(image: Image(iconNames[index]))
                            .frame(width: icon + 6, height: icon)
                        GeometryReader { bar in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.primary.opacity(0.16))
                                if let value = values?[index] {
                                    Capsule().fill(careColors[index])
                                        .frame(width: max(0, bar.size.width * value / 100))
                                }
                            }
                        }
                        .frame(height: medium ? 8 : 7)
                    }
                    .frame(height: row)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(values.map { "\(careNames[index]), \(Int($0[index].rounded())) percent" } ?? "\(careNames[index]), open Inushima to update")
                }
            }
        }
    }
}

private struct DogPortrait: View {
    let entry: DogEntry

    var body: some View {
        OriginalImage(image: Image(uiImage: entry.artwork ?? UIImage(named: "PreviewDog") ?? UIImage()))
            .scaleEffect(0.86 + 0.14 * (entry.snapshot?.growth ?? 1), anchor: .bottom)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .accessibilityLabel(entry.snapshot.map { "Your \($0.stage.lowercased()), \($0.breed)" } ?? "Open Inushima to show your dog")
    }
}

struct DogWidgetView: View {
    let entry: DogEntry
    @Environment(\.widgetFamily) private var family
    @Environment(\.colorScheme) private var colorScheme

    private var values: [Double]? {
        entry.snapshot?.values(at: entry.date) ?? (entry.preview ? [80, 85, 90, 80] : nil)
    }

    var body: some View {
        GeometryReader { geometry in
            if family == .systemSmall {
                VStack(spacing: 3) {
                    CareGrid(values: values, medium: false)
                        .frame(height: geometry.size.height * 0.44)
                    DogPortrait(entry: entry)
                }
            } else {
                HStack(spacing: 12) {
                    DogPortrait(entry: entry).frame(width: geometry.size.width * 0.45)
                    CareGrid(values: values, medium: true)
                        .padding(.vertical, max(0, (geometry.size.height - 118) / 2))
                }
            }
        }
        .padding(family == .systemSmall ? 10 : 12)
        .containerBackground(for: .widget) {
            // The system replaces this removable background with native glass
            // for Clear/Tinted Home Screens, retaining readable foreground art.
            LinearGradient(colors: colorScheme == .dark ? [Color(red: 0.08, green: 0.22, blue: 0.25), Color(red: 0.13, green: 0.30, blue: 0.31)] : [Color(red: 0.78, green: 0.94, blue: 0.93), Color(red: 1, green: 0.95, blue: 0.84)], startPoint: .top, endPoint: .bottom)
        }
        .accessibilityElement(children: .contain)
    }
}

@main
struct InushimaWidget: Widget {
    let kind = "InushimaDog"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DogProvider()) { entry in
            DogWidgetView(entry: entry)
        }
        .configurationDisplayName("Your dog")
        .description("Your island companion and four care needs, at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
    }
}
