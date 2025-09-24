import SwiftUI

struct MeowTalkView: View {
    @EnvironmentObject private var theme: ThemeManager
    @Environment(\.colorScheme) private var colorScheme

    @State private var message: String = ""
    @State private var messages: [String] = [
        "Welcome to MeowTalk!",
        "Say hi to your fellow cats 🐾"
    ]

    var body: some View {
        let palette = theme.palette(for: colorScheme)

        VStack(spacing: 0) {
            List {
                ForEach(messages.indices, id: \.self) { idx in
                    HStack(alignment: .top, spacing: 12) {
                        Circle()
                            .fill(palette.primary)
                            .frame(width: 32, height: 32)
                            .overlay(Text("🐱").font(.system(size: 18)))
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Cat #\(idx + 1)")
                                .font(.subheadline).bold()
                                .foregroundStyle(palette.textPrimary)
                            Text(messages[idx])
                                .font(.body)
                                .foregroundStyle(palette.textSecondary)
                        }
                    }
                    .listRowBackground(palette.card)
                }
            }
            .scrollContentBackground(.hidden)
            .background(palette.background)

            Divider()

            HStack(spacing: 8) {
                TextField("Type a message", text: $message)
                    .textFieldStyle(.roundedBorder)
                Button {
                    let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    messages.append(trimmed)
                    message = ""
                } label: {
                    Image(systemName: "paperplane.fill")
                        .foregroundStyle(.white)
                        .padding(8)
                        .background(palette.primary)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(12)
            .background(palette.background)
        }
        .navigationTitle("MeowTalk")
        .background(palette.background.ignoresSafeArea())
    }
}

#Preview {
    NavigationStack {
        MeowTalkView()
            .environmentObject(ThemeManager())
    }
}
