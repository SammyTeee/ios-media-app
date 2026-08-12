import SwiftUI

struct StandByView: View {
    @ObservedObject var mediaController: MediaController
    let dismiss: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()

            if let media = mediaController.currentMedia {
                VStack(spacing: 22) {
                    Spacer()

                    Group {
                        if let albumArtURL = media.albumArtURL {
                            AsyncImage(url: albumArtURL) { image in
                                image.resizable().scaledToFill()
                            } placeholder: {
                                Color.white.opacity(0.08)
                            }
                        } else {
                            ZStack {
                                Color.white.opacity(0.08)
                                Image(systemName: "music.note")
                                    .font(.system(size: 84, weight: .light))
                                    .foregroundStyle(.white.opacity(0.7))
                            }
                        }
                    }
                    .frame(width: 300, height: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 26))

                    VStack(spacing: 5) {
                        Text(media.title.isEmpty ? "Unknown title" : media.title)
                            .font(.largeTitle.bold())
                            .lineLimit(2)
                        Text(media.artist)
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .multilineTextAlignment(.center)

                    HStack(spacing: 38) {
                        ControlButton(icon: "backward.fill") { mediaController.sendCommand(.previous) }
                        ControlButton(icon: media.isPlaying ? "pause.fill" : "play.fill", prominent: true) {
                            mediaController.sendCommand(media.isPlaying ? .pause : .play)
                        }
                        ControlButton(icon: "forward.fill") { mediaController.sendCommand(.next) }
                    }

                    Spacer()
                }
                .padding(32)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            Button(action: dismiss) {
                Image(systemName: "xmark")
                    .font(.headline)
                    .frame(width: 42, height: 42)
                    .background(.thinMaterial, in: Circle())
            }
            .foregroundStyle(.white)
            .padding()
            .accessibilityLabel("Close now playing")
        }
    }
}
