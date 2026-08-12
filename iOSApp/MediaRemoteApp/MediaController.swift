import Foundation

@MainActor
final class MediaController: ObservableObject {
    @Published private(set) var currentMedia: MediaInfo?
    @Published private(set) var connectionState: ConnectionState = .disconnected
    @Published private(set) var lastError: String?

    private var socket: URLSessionWebSocketTask?
    private var refreshTimer: Timer?

    func connect(to address: String) {
        disconnect()

        guard let url = Self.webSocketURL(from: address) else {
            lastError = "Enter a PC address such as 192.168.1.20:5000."
            return
        }

        lastError = nil
        connectionState = .connecting
        let task = URLSession.shared.webSocketTask(with: url)
        socket = task
        task.resume()
        connectionState = .connected
        receiveNextMessage(from: task)
        requestMediaInfo()

        refreshTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.requestMediaInfo()
            }
        }
    }

    func disconnect() {
        refreshTimer?.invalidate()
        refreshTimer = nil
        socket?.cancel(with: .goingAway, reason: nil)
        socket = nil
        connectionState = .disconnected
    }

    func sendCommand(_ command: MediaCommand) {
        send(command.rawValue)
    }

    private func requestMediaInfo() {
        send("get_info")
    }

    private func send(_ text: String) {
        guard let socket else { return }
        socket.send(.string(text)) { [weak self] error in
            guard let error else { return }
            Task { @MainActor [weak self] in
                self?.fail(with: error)
            }
        }
    }

    private func receiveNextMessage(from task: URLSessionWebSocketTask) {
        task.receive { [weak self] result in
            Task { @MainActor [weak self] in
                guard let self, self.socket === task else { return }

                switch result {
                case .success(let message):
                    self.handle(message)
                    self.receiveNextMessage(from: task)
                case .failure(let error):
                    self.fail(with: error)
                }
            }
        }
    }

    private func handle(_ message: URLSessionWebSocketTask.Message) {
        let data: Data
        switch message {
        case .data(let value): data = value
        case .string(let value): data = Data(value.utf8)
        @unknown default: return
        }

        do {
            currentMedia = try JSONDecoder().decode(MediaInfo.self, from: data)
            connectionState = .connected
            lastError = nil
        } catch {
            lastError = "The PC returned media data this version cannot read."
        }
    }

    private func fail(with error: Error) {
        refreshTimer?.invalidate()
        refreshTimer = nil
        socket = nil
        connectionState = .disconnected
        lastError = error.localizedDescription
    }

    private static func webSocketURL(from input: String) -> URL? {
        var address = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !address.isEmpty else { return nil }

        if !address.contains("://") {
            address = "ws://" + address
        }

        guard var components = URLComponents(string: address),
              components.scheme == "ws" || components.scheme == "wss",
              components.host != nil else {
            return nil
        }

        if components.port == nil {
            components.port = 5000
        }
        if components.path.isEmpty || components.path == "/" {
            components.path = "/ws"
        }
        return components.url
    }
}
