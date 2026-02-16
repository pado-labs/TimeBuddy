import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = TimeConverterViewModel()

    var body: some View {
        VStack(spacing: 12) {
            // Input area
            HStack(spacing: 8) {
                TextField("e.g. 오후 3시, 3pm to 5pm, 下午3点", text: $viewModel.inputText)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        Task { await viewModel.convert() }
                    }

                // Input timezone picker
                Menu {
                    ForEach(viewModel.timeZoneIdentifiers, id: \.self) { identifier in
                        Button(action: {
                            viewModel.defaultInputTimezone = identifier
                        }) {
                            HStack {
                                Text(TimeZone(identifier: identifier)?.abbreviation() ?? identifier)
                                if identifier == viewModel.defaultInputTimezone {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    Text(TimeZone(identifier: viewModel.defaultInputTimezone)?.abbreviation() ?? "KST")
                        .font(.system(size: 11, weight: .medium))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.accentColor.opacity(0.15))
                        .cornerRadius(4)
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
                .help("Input timezone")

                // Convert button
                Button(action: {
                    Task { await viewModel.convert() }
                }) {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 18))
                }
                .buttonStyle(.plain)
                .disabled(viewModel.inputText.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isLoading)
            }

            // Loading indicator
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(0.8)
            }

            // Error message
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Results
            if !viewModel.results.isEmpty {
                Divider()

                VStack(spacing: 6) {
                    ForEach(viewModel.results) { result in
                        ResultRow(
                            result: result,
                            editableText: Binding(
                                get: { viewModel.editableResults[result.id] ?? result.formattedTime },
                                set: { viewModel.editableResults[result.id] = $0 }
                            )
                        )
                    }
                }
            }

            Divider()

            // Bottom bar
            HStack {
                Button(action: {
                    viewModel.showSettings.toggle()
                }) {
                    Image(systemName: "gear")
                        .font(.system(size: 13))
                }
                .buttonStyle(.plain)
                .help("Settings")

                Spacer()

                Text("TimeBuddy")
                    .font(.caption2)
                    .foregroundColor(Color(nsColor: .tertiaryLabelColor))

                Spacer()

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.plain)
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .frame(width: 380)
        .sheet(isPresented: $viewModel.showSettings) {
            SettingsView(viewModel: viewModel)
        }
    }
}
