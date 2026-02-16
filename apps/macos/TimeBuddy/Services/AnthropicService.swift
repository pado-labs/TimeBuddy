import Foundation

final class AnthropicService {
    private let endpoint = "https://api.anthropic.com/v1/messages"
    private let model = "claude-haiku-4-5"

    func parseTime(input: String, apiKey: String, defaultTimezone: String = "Asia/Seoul") async throws -> ParsedTime {
        guard !apiKey.isEmpty else {
            throw AnthropicError.missingAPIKey
        }

        let systemPrompt = """
        You are a time parser. Given a natural language time input in any language, extract the time information and respond with ONLY a JSON object (no markdown, no explanation):
        {"hour": <0-23>, "minute": <0-59>, "timezone": "<IANA timezone identifier>", "date": "<YYYY-MM-DD or null>", "end_hour": <0-23 or null>, "end_minute": <0-59 or null>}

        Rules:
        - Use 24-hour format for hour
        - timezone must be a valid IANA timezone (e.g. "Asia/Seoul", "America/New_York", "Europe/London")
        - If no date is specified, set date to null
        - If no timezone is specified, try to infer from context. If unable, default to "\(defaultTimezone)"
        - If the input contains a time RANGE (e.g. "2시에서 5시", "from 2pm to 5pm", "2-5pm"), set end_hour and end_minute. Otherwise set them to null.
        - "한국 오후 3시" → {"hour": 15, "minute": 0, "timezone": "Asia/Seoul", "date": null, "end_hour": null, "end_minute": null}
        - "한국 오후 2시에서 5시" → {"hour": 14, "minute": 0, "timezone": "Asia/Seoul", "date": null, "end_hour": 17, "end_minute": 0}
        - "3pm EST tomorrow" → {"hour": 15, "minute": 0, "timezone": "America/New_York", "date": "<tomorrow's date>", "end_hour": null, "end_minute": null}
        - "北京时间下午3点到5点" → {"hour": 15, "minute": 0, "timezone": "Asia/Shanghai", "date": null, "end_hour": 17, "end_minute": 0}

        Today's date is \(todayString()).
        """

        let body: [String: Any] = [
            "model": model,
            "max_tokens": 150,
            "system": systemPrompt,
            "messages": [
                ["role": "user", "content": input]
            ]
        ]

        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AnthropicError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AnthropicError.apiError(statusCode: httpResponse.statusCode, message: errorBody)
        }

        return try parseResponse(data: data)
    }

    private func parseResponse(data: Data) throws -> ParsedTime {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let firstBlock = content.first,
              let text = firstBlock["text"] as? String else {
            throw AnthropicError.invalidResponse
        }

        // Extract JSON from the response text (handle potential markdown wrapping)
        let jsonString = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let jsonData = jsonString.data(using: .utf8) else {
            throw AnthropicError.parsingFailed
        }

        let timeResponse = try JSONDecoder().decode(AnthropicTimeResponse.self, from: jsonData)

        guard let timeZone = TimeZone(identifier: timeResponse.timezone) else {
            throw AnthropicError.invalidTimezone(timeResponse.timezone)
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone

        var components = DateComponents()
        components.hour = timeResponse.hour
        components.minute = timeResponse.minute
        components.timeZone = timeZone

        if let dateStr = timeResponse.date {
            let parts = dateStr.split(separator: "-").compactMap { Int($0) }
            if parts.count == 3 {
                components.year = parts[0]
                components.month = parts[1]
                components.day = parts[2]
            }
        }

        // If no date was provided, use today in the source timezone
        if components.year == nil {
            let now = Date()
            let todayComponents = calendar.dateComponents([.year, .month, .day], from: now)
            components.year = todayComponents.year
            components.month = todayComponents.month
            components.day = todayComponents.day
        }

        guard let date = calendar.date(from: components) else {
            throw AnthropicError.parsingFailed
        }

        // Parse optional end time for ranges
        var endDate: Date?
        if let endHour = timeResponse.end_hour, let endMinute = timeResponse.end_minute {
            var endComponents = components
            endComponents.hour = endHour
            endComponents.minute = endMinute
            endDate = calendar.date(from: endComponents)
        }

        return ParsedTime(date: date, endDate: endDate, sourceTimeZone: timeZone)
    }

    private func todayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        return formatter.string(from: Date())
    }
}

enum AnthropicError: LocalizedError {
    case missingAPIKey
    case invalidResponse
    case parsingFailed
    case invalidTimezone(String)
    case apiError(statusCode: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "API key is not set. Please add your Anthropic API key in Settings."
        case .invalidResponse:
            return "Invalid response from API."
        case .parsingFailed:
            return "Failed to parse time from response."
        case .invalidTimezone(let tz):
            return "Invalid timezone: \(tz)"
        case .apiError(let code, let message):
            return "API error (\(code)): \(message)"
        }
    }
}
