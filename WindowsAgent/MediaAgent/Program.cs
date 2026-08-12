using System.Net.WebSockets;
using System.Text;
using System.Text.Json;

var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();
var mediaController = await MediaController.CreateAsync();
var jsonOptions = new JsonSerializerOptions(JsonSerializerDefaults.Web);

app.UseWebSockets(new WebSocketOptions
{
    KeepAliveInterval = TimeSpan.FromSeconds(30)
});

app.MapGet("/", () => Results.Ok(new
{
    service = "Media Remote Windows Agent",
    webSocket = "/ws"
}));

app.Map("/ws", async context =>
{
    if (!context.WebSockets.IsWebSocketRequest)
    {
        context.Response.StatusCode = StatusCodes.Status400BadRequest;
        return;
    }

    using var socket = await context.WebSockets.AcceptWebSocketAsync();
    var buffer = new byte[4096];

    while (socket.State == WebSocketState.Open && !context.RequestAborted.IsCancellationRequested)
    {
        var result = await socket.ReceiveAsync(buffer, context.RequestAborted);
        if (result.MessageType == WebSocketMessageType.Close)
        {
            await socket.CloseAsync(WebSocketCloseStatus.NormalClosure, "Closing", CancellationToken.None);
            break;
        }

        if (result.MessageType != WebSocketMessageType.Text)
        {
            continue;
        }

        var command = Encoding.UTF8.GetString(buffer, 0, result.Count).Trim().Trim('"').ToLowerInvariant();
        switch (command)
        {
            case "play":
                await mediaController.PlayAsync();
                break;
            case "pause":
                await mediaController.PauseAsync();
                break;
            case "next":
                await mediaController.NextAsync();
                break;
            case "previous":
                await mediaController.PreviousAsync();
                break;
            case "get_info":
                var media = await mediaController.GetCurrentMediaInfoAsync();
                var payload = JsonSerializer.Serialize(media, jsonOptions);
                await socket.SendAsync(
                    Encoding.UTF8.GetBytes(payload),
                    WebSocketMessageType.Text,
                    endOfMessage: true,
                    context.RequestAborted);
                break;
        }
    }
});

var listenUrl = Environment.GetEnvironmentVariable("MEDIA_REMOTE_URLS") ?? "http://0.0.0.0:5000";
Console.WriteLine($"Media Remote agent listening on {listenUrl}");
Console.WriteLine("On the iPhone, connect to this PC's LAN IP address and port 5000.");
await app.RunAsync(listenUrl);
