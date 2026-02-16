import SwiftUI

struct ResultRow: View {
    let result: TimeZoneResult
    @Binding var editableText: String
    @State private var showCopied = false

    var body: some View {
        HStack(spacing: 8) {
            // Timezone label
            VStack(alignment: .leading, spacing: 1) {
                Text(result.cityName)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)
                Text(result.displayName)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .frame(width: 100, alignment: .leading)

            // Editable time text
            TextField("", text: $editableText)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 13, design: .monospaced))

            // Copy button
            Button(action: copyToClipboard) {
                Image(systemName: showCopied ? "checkmark" : "doc.on.doc")
                    .font(.system(size: 12))
                    .foregroundColor(showCopied ? .green : .secondary)
            }
            .buttonStyle(.plain)
            .help("Copy to clipboard")
        }
    }

    private func copyToClipboard() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(editableText, forType: .string)

        withAnimation {
            showCopied = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                showCopied = false
            }
        }
    }
}
