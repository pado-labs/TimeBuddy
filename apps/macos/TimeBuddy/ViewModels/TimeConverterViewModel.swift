import Foundation
import SwiftUI

@MainActor
final class TimeConverterViewModel: ObservableObject {
    @Published var inputText = ""
    @Published var results: [TimeZoneResult] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showSettings = false

    // Editable time strings for each result row
    @Published var editableResults: [UUID: String] = [:]

    @AppStorage("apiKey") var apiKey = ""
    @AppStorage("defaultInputTimezone") var defaultInputTimezone = "Asia/Seoul"
    @AppStorage("pinnedTimeZones") private var pinnedTimeZonesData: Data = {
        let defaults = [
            "Asia/Seoul",
            "America/Los_Angeles",
            "America/New_York",
            "Europe/London",
            "Europe/Paris",
            "Asia/Dubai",
            "America/Toronto",
        ]
        return (try? JSONEncoder().encode(defaults)) ?? Data()
    }()

    private let anthropicService = AnthropicService()

    // Launch at login
    @AppStorage("launchAtLogin") var launchAtLogin: Bool = false {
        didSet { applyLaunchAtLogin(launchAtLogin) }
    }

    private static var launchAgentURL: URL {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home.appendingPathComponent("Library/LaunchAgents/com.padolabs.TimeBuddy.plist")
    }

    private func applyLaunchAtLogin(_ enabled: Bool) {
        let url = Self.launchAgentURL
        if enabled {
            let dict: [String: Any] = [
                "Label": "com.padolabs.TimeBuddy",
                "RunAtLoad": true,
                "KeepAlive": false,
                "LimitLoadToSessionType": "Aqua",
                "ProgramArguments": ["/usr/bin/open", "-a", Bundle.main.bundlePath],
            ]
            do {
                let data = try PropertyListSerialization.data(fromPropertyList: dict, format: .xml, options: 0)
                try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
                try data.write(to: url, options: .atomic)
            } catch {
                print("Failed to write LaunchAgent: \(error)")
            }
        } else {
            try? FileManager.default.removeItem(at: url)
        }
    }

    var timeZoneIdentifiers: [String] {
        get {
            (try? JSONDecoder().decode([String].self, from: pinnedTimeZonesData)) ?? []
        }
        set {
            pinnedTimeZonesData = (try? JSONEncoder().encode(newValue)) ?? Data()
            objectWillChange.send()
        }
    }

    // Aliases for common city/country names to IANA identifiers
    static let searchAliases: [String: [String]] = [
        "America/Los_Angeles": ["california", "ca", "pacific", "pt", "pst", "pdt", "san francisco", "sf", "seattle", "silicon valley"],
        "America/New_York": ["east coast", "et", "est", "edt", "boston", "miami", "washington dc"],
        "America/Chicago": ["central", "ct", "cst", "cdt", "dallas", "houston"],
        "America/Denver": ["mountain", "mt", "mst", "mdt", "colorado"],
        "America/Toronto": ["canada", "ontario", "montreal"],
        "America/Vancouver": ["bc", "british columbia"],
        "Asia/Seoul": ["korea", "kr", "kst", "한국", "서울"],
        "Asia/Tokyo": ["japan", "jp", "jst", "일본", "도쿄"],
        "Asia/Shanghai": ["china", "cn", "cst", "beijing", "중국", "베이징", "北京"],
        "Asia/Dubai": ["uae", "emirates", "두바이"],
        "Asia/Singapore": ["sg", "싱가포르"],
        "Asia/Kolkata": ["india", "mumbai", "delhi", "ist", "인도"],
        "Europe/London": ["uk", "england", "britain", "bst", "gmt", "런던", "영국"],
        "Europe/Paris": ["france", "cet", "cest", "프랑스", "파리"],
        "Europe/Berlin": ["germany", "deutschland", "독일", "베를린"],
        "Australia/Sydney": ["australia", "au", "aest", "호주", "시드니"],
    ]

    static func matchesSearch(_ identifier: String, query: String) -> Bool {
        let lower = query.lowercased()
        let cityName = (identifier.components(separatedBy: "/").last?
            .replacingOccurrences(of: "_", with: " "))?.lowercased() ?? ""

        if identifier.lowercased().contains(lower) || cityName.contains(lower) {
            return true
        }
        if let aliases = searchAliases[identifier] {
            return aliases.contains { $0.contains(lower) }
        }
        // Check abbreviation
        if let tz = TimeZone(identifier: identifier),
           let abbr = tz.abbreviation()?.lowercased(), abbr.contains(lower) {
            return true
        }
        return false
    }

    static func currentTimeString(for identifier: String) -> String {
        guard let tz = TimeZone(identifier: identifier) else { return "" }
        let formatter = DateFormatter()
        formatter.timeZone = tz
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: Date())
    }

    static func cityName(from identifier: String) -> String {
        identifier
            .components(separatedBy: "/").last?
            .replacingOccurrences(of: "_", with: " ") ?? identifier
    }

    func convert() async {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isLoading = true
        errorMessage = nil
        results = []
        editableResults = [:]

        do {
            let parsed = try await anthropicService.parseTime(input: trimmed, apiKey: apiKey, defaultTimezone: defaultInputTimezone)

            let newResults = timeZoneIdentifiers.compactMap { identifier -> TimeZoneResult? in
                guard let tz = TimeZone(identifier: identifier) else { return nil }
                return TimeZoneResult(timeZone: tz, date: parsed.date, endDate: parsed.endDate)
            }

            results = newResults
            for result in newResults {
                editableResults[result.id] = result.formattedTime
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func addTimeZone(_ identifier: String) {
        guard !timeZoneIdentifiers.contains(identifier) else { return }
        timeZoneIdentifiers.append(identifier)
    }

    func removeTimeZone(_ identifier: String) {
        timeZoneIdentifiers.removeAll { $0 == identifier }
    }

    func removeTimeZone(at offsets: IndexSet) {
        var ids = timeZoneIdentifiers
        ids.remove(atOffsets: offsets)
        timeZoneIdentifiers = ids
    }

    func moveTimeZone(from source: IndexSet, to destination: Int) {
        var ids = timeZoneIdentifiers
        ids.move(fromOffsets: source, toOffset: destination)
        timeZoneIdentifiers = ids
    }

    func isPinned(_ identifier: String) -> Bool {
        timeZoneIdentifiers.contains(identifier)
    }

    func togglePin(_ identifier: String) {
        if isPinned(identifier) {
            removeTimeZone(identifier)
        } else {
            addTimeZone(identifier)
        }
    }
}
