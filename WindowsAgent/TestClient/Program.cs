using System.Net.WebSockets;
using System.Text;

var address = args.FirstOrDefault() ?? "ws://localhost:5000/ws";
using var cancellation = new CancellationTokenSource();
using var socket = new ClientWebSocket();

Console.WriteLine($"Connecting to {address}...");
await socket.ConnectAsync(new Uri(address), cancellation.Token);
Console.WriteLine("Connected. Enter get_info, play, pause, next, previous, or quit.");

var receiver = Task.Run(async () =>
{
    var buffer = new byte[4096];
    while (socket.State == WebSocketState.Open)
    {
        var result = await socket.ReceiveAsync(buffer, cancellation.Token);
        if (result.MessageType == WebSocketMessageType.Close)
        {
            return;
        }

        Console.WriteLine($"Received: {Encoding.UTF8.GetString(buffer, 0, result.Count)}");
    }
}, cancellation.Token);

while (socket.State == WebSocketState.Open)
{
    Console.Write("> ");
    var command = Console.ReadLine()?.Trim().ToLowerInvariant();
    if (string.IsNullOrEmpty(command))
    {
        continue;
    }

    if (command is "quit" or "exit")
    {
        break;
    }

    await socket.SendAsync(
        Encoding.UTF8.GetBytes(command),
        WebSocketMessageType.Text,
        endOfMessage: true,
        cancellation.Token);
}

if (socket.State == WebSocketState.Open)
{
    await socket.CloseAsync(WebSocketCloseStatus.NormalClosure, "Closing", CancellationToken.None);
}

cancellation.Cancel();
try
{
    await receiver;
}
catch (OperationCanceledException)
{
}
