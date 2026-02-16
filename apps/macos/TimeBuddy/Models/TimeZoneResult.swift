import Foundation

struct ParsedTime {
    let date: Date
    let endDate: Date?
    let sourceTimeZone: TimeZone
}

struct TimeZoneResult: Identifiable {
    let id = UUID()
    let timeZone: TimeZone
    let date: Date
    let endDate: Date?

    var displayName: String {
        timeZone.abbreviation(for: date) ?? timeZone.identifier
    }

    var cityName: String {
        timeZone.identifier
            .components(separatedBy: "/").last?
            .replacingOccurrences(of: "_", with: " ") ?? timeZone.identifier
    }

    var formattedTime: String {
        let startStr = Self.humanReadable(date: date, timeZone: timeZone)

        guard let endDate else {
            return startStr
        }

        let calendar = Calendar.current
        let sameDay = calendar.isDate(date, inSameDayAs: endDate)

        if sameDay {
            // Same day: "May 23rd, 2:00 PM – 5:00 PM"
            let endTimeStr = Self.timeOnly(date: endDate, timeZone: timeZone)
            return "\(startStr) – \(endTimeStr)"
        } else {
            // Different days: "May 22nd, 10:00 PM – May 23rd, 1:00 AM"
            let endStr = Self.humanReadable(date: endDate, timeZone: timeZone)
            return "\(startStr) – \(endStr)"
        }
    }

    private static func humanReadable(date: Date, timeZone: TimeZone) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone

        let day = calendar.component(.day, from: date)
        let suffix = ordinalSuffix(for: day)

        let monthFormatter = DateFormatter()
        monthFormatter.timeZone = timeZone
        monthFormatter.dateFormat = "MMMM"
        monthFormatter.locale = Locale(identifier: "en_US")
        let month = monthFormatter.string(from: date)

        let timeStr = timeOnly(date: date, timeZone: timeZone)

        return "\(month) \(day)\(suffix), \(timeStr)"
    }

    private static func timeOnly(date: Date, timeZone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = timeZone
        formatter.dateFormat = "h:mm a"
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: date)
    }

    private static func ordinalSuffix(for day: Int) -> String {
        switch day {
        case 11, 12, 13: return "th"
        default:
            switch day % 10 {
            case 1: return "st"
            case 2: return "nd"
            case 3: return "rd"
            default: return "th"
            }
        }
    }
}

struct AnthropicTimeResponse: Codable {
    let hour: Int
    let minute: Int
    let timezone: String
    let date: String?
    let end_hour: Int?
    let end_minute: Int?
}
