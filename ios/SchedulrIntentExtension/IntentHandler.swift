import Foundation
import Intents

final class IntentHandler: INExtension, SelectTimetableIntentHandling {
    private let appGroup = "group.app.schedulr.shared"
    private let catalogKey = "schedulr.widget.snapshot.v2"

    override func handler(for intent: INIntent) -> Any {
        self
    }

    func provideTimetableOptionsCollection(for intent: SelectTimetableIntent, with completion: @escaping (INObjectCollection<Timetable>?, Error?) -> Void) {
        let objects = loadTimetables()
        completion(INObjectCollection(items: objects), nil)
    }

    func defaultTimetable(for intent: SelectTimetableIntent) -> Timetable? {
        let defaults = UserDefaults(suiteName: appGroup)
        let defaultId = defaults.flatMap { readCatalog(from: $0)?["defaultTimetableId"] as? String }
        return loadTimetables().first { $0.identifier == defaultId } ?? loadTimetables().first
    }

    private func loadTimetables() -> [Timetable] {
        guard let defaults = UserDefaults(suiteName: appGroup),
              let catalog = readCatalog(from: defaults),
              let values = catalog["timetables"] as? [[String: Any]] else {
            return []
        }
        return values.compactMap { raw in
            guard let identifier = raw["timetableId"] as? String,
                  !identifier.isEmpty,
                  let display = raw["timetableName"] as? String,
                  !display.isEmpty else { return nil }
            return Timetable(identifier: identifier, display: display)
        }
    }

    private func readCatalog(from defaults: UserDefaults) -> [String: Any]? {
        guard let stored = defaults.object(forKey: catalogKey) else { return nil }
        let data: Data?
        if let value = stored as? Data {
            data = value
        } else if let value = stored as? String {
            data = value.data(using: .utf8)
        } else if JSONSerialization.isValidJSONObject(stored) {
            data = try? JSONSerialization.data(withJSONObject: stored)
        } else {
            data = nil
        }
        guard let data,
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return object
    }
}
