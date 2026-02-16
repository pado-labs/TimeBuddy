import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: TimeConverterViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var showTimeZonePicker = false

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("Settings")
                    .font(.headline)
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }

            // API Key
            VStack(alignment: .leading, spacing: 4) {
                Text("Anthropic API Key")
                    .font(.subheadline)
                    .fontWeight(.medium)
                SecureField("sk-ant-...", text: $viewModel.apiKey)
                    .textFieldStyle(.roundedBorder)
            }

            Divider()

            // Pinned Timezones
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Pinned Time Zones")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    Button(action: { showTimeZonePicker = true }) {
                        Image(systemName: "plus")
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.plain)
                }

                List {
                    ForEach(viewModel.timeZoneIdentifiers, id: \.self) { identifier in
                        HStack(spacing: 8) {
                            VStack(alignment: .leading, spacing: 1) {
                                Text(TimeConverterViewModel.cityName(from: identifier))
                                    .font(.system(size: 13))
                                Text(identifier)
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text(TimeConverterViewModel.currentTimeString(for: identifier))
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                    }
                    .onDelete(perform: viewModel.removeTimeZone)
                    .onMove(perform: viewModel.moveTimeZone)
                }
                .listStyle(.bordered)
                .frame(height: 200)
            }
        }
        .padding(20)
        .frame(width: 380)
        .sheet(isPresented: $showTimeZonePicker) {
            TimeZonePickerView(viewModel: viewModel)
        }
    }
}

struct TimeZonePickerView: View {
    @ObservedObject var viewModel: TimeConverterViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private var filteredTimeZones: [String] {
        let all = TimeZone.knownTimeZoneIdentifiers
        guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else {
            // Show pinned first, then popular ones
            let popular = [
                "Asia/Seoul", "America/Los_Angeles", "America/New_York",
                "Europe/London", "Europe/Paris", "Asia/Tokyo",
                "Asia/Shanghai", "Asia/Dubai", "Asia/Singapore",
                "America/Toronto", "America/Chicago", "Europe/Berlin",
                "Australia/Sydney", "Asia/Kolkata", "America/Denver",
            ]
            let pinned = viewModel.timeZoneIdentifiers
            let rest = popular.filter { !pinned.contains($0) }
            return pinned + rest
        }
        return all.filter { TimeConverterViewModel.matchesSearch($0, query: searchText) }
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Time Zones")
                    .font(.headline)
                Spacer()
                Button("Done") { dismiss() }
            }

            TextField("Search city, country, or abbreviation...", text: $searchText)
                .textFieldStyle(.roundedBorder)

            List(filteredTimeZones, id: \.self) { identifier in
                Button(action: { viewModel.togglePin(identifier) }) {
                    HStack(spacing: 8) {
                        Image(systemName: viewModel.isPinned(identifier) ? "pin.fill" : "pin")
                            .font(.system(size: 11))
                            .foregroundColor(viewModel.isPinned(identifier) ? .accentColor : .secondary)
                            .frame(width: 16)

                        VStack(alignment: .leading, spacing: 1) {
                            Text(TimeConverterViewModel.cityName(from: identifier))
                                .font(.system(size: 13))
                            Text(identifier)
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Text(TimeConverterViewModel.currentTimeString(for: identifier))
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(.plain)
            }
            .listStyle(.bordered)
            .frame(height: 320)
        }
        .padding(16)
        .frame(width: 380)
    }
}
