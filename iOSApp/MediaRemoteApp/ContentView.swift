import Foundation
import SwiftUI

struct ContentView: View {
    @StateObject private var mediaController = MediaController()
    @AppStorage("serverAddress") private var serverAddress = ""
    @State private var showingStandBy = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    connectionCard

                    if let media = mediaController.currentMedia {
                        MediaInfoView(media: media)

                        HStack(spacing: 34) {
                            ControlButton(icon: "backward.fill") {
                                mediaController.sendCommand(.previous)
                            }
                            ControlButton(
                                icon: media.isPlaying ? "pause.fill" : "play.fill",
                                prominent: true
                            ) {
                                mediaController.sendCommand(media.isPlaying ? .pause : .play)
                            }
                            ControlButton(icon: "forward.fill") {
                                mediaController.sendCommand(.next)
                            }
                        }

                        if media.duration > 0 {
                            VStack(spacing: 6) {
                                ProgressView(value: min(media.position, media.duration), total: media.duration)
                                HStack {
                                    Text(media.position.formattedDuration)
                                    Spacer()
                                    Text(media.duration.formattedDuration)
                                }
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                            }
                        }
                    } else {
                        ContentUnavailableView(
                            "No media yet",
                            systemImage: "music.note",
                            description: Text("Connect to the Windows agent, then start playing something on the PC.")
                        )
                        .frame(minHeight: 260)
                    }
                }
                .padding()
            }
            .navigationTitle("Media Remote")
            .toolbar {
                if mediaController.currentMedia != nil {
                    Button {
                        showingStandBy = true
                    } label: {
                        Label("Now Playing", systemImage: "rectangle.expand.vertical")
                    }
                }
            }
            .fullScreenCover(isPresented: $showingStandBy) {
                StandByView(mediaController: mediaController) {
                    showingStandBy = false
                }
            }
        }
        .onAppear {
            guard !serverAddress.isEmpty else { return }
            mediaController.connect(to: serverAddress)
        }
    }

    private var connectionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(mediaController.connectionState.title, systemImage: mediaController.connectionState.icon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(mediaController.connectionState.tint)
                Spacer()
                if mediaController.connectionState == .connected {
                    Button("Disconnect") { mediaController.disconnect() }
                        .font(.subheadline)
                }
            }

            HStack(spacing: 10) {
                TextField("PC address, e.g. 192.168.1.20:5000", text: $serverAddress)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { mediaController.connect(to: serverAddress) }

                Button("Connect") {
                    mediaController.connect(to: serverAddress)
                }
                .buttonStyle(.borderedProminent)
                .disabled(serverAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            if let message = mediaController.lastError {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.red)
            } else {
                Text("Your iPhone and PC need to be on the same network.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18))
    }
}

private struct MediaInfoView: View {
    let media: MediaInfo

    var body: some View {
        VStack(spacing: 14) {
            Group {
                if let albumArtURL = media.albumArtURL {
                    AsyncImage(url: albumArtURL) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        artworkPlaceholder
                    }
                } else {
                    artworkPlaceholder
                }
            }
            .frame(width: 260, height: 260)
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .shadow(radius: 18, y: 8)

            VStack(spacing: 4) {
                Text(media.title.isEmpty ? "Unknown title" : media.title)
                    .font(.title2.bold())
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                Text(media.artist.isEmpty ? media.album : media.artist)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var artworkPlaceholder: some View {
        ZStack {
            LinearGradient(colors: [.indigo, .purple.opacity(0.65)], startPoint: .topLeading, endPoint: .bottomTrailing)
            Image(systemName: "music.note")
                .font(.system(size: 76, weight: .light))
                .foregroundStyle(.white.opacity(0.85))
        }
    }
}

struct ControlButton: View {
    let icon: String
    var prominent = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: prominent ? 27 : 22, weight: .semibold))
                .frame(width: prominent ? 68 : 54, height: prominent ? 68 : 54)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.circle)
        .tint(prominent ? .accentColor : .secondary.opacity(0.35))
        .accessibilityLabel(icon.accessibilityControlName)
    }
}

private extension String {
    var accessibilityControlName: String {
        if contains("backward") { return "Previous" }
        if contains("forward") { return "Next" }
        if contains("pause") { return "Pause" }
        return "Play"
    }
}

private extension TimeInterval {
    var formattedDuration: String {
        let seconds = max(0, Int(self.rounded()))
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}
