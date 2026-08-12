using Windows.Media.Control;

public sealed class MediaController
{
    private readonly GlobalSystemMediaTransportControlsSessionManager _sessionManager;

    private MediaController(GlobalSystemMediaTransportControlsSessionManager sessionManager)
    {
        _sessionManager = sessionManager;
    }

    public static async Task<MediaController> CreateAsync()
    {
        var manager = await GlobalSystemMediaTransportControlsSessionManager.RequestAsync();
        return new MediaController(manager);
    }

    public async Task<bool> PlayAsync() =>
        await WithCurrentSession(session => session.TryPlayAsync().AsTask());

    public async Task<bool> PauseAsync() =>
        await WithCurrentSession(session => session.TryPauseAsync().AsTask());

    public async Task<bool> NextAsync() =>
        await WithCurrentSession(session => session.TrySkipNextAsync().AsTask());

    public async Task<bool> PreviousAsync() =>
        await WithCurrentSession(session => session.TrySkipPreviousAsync().AsTask());

    public async Task<MediaInfo?> GetCurrentMediaInfoAsync()
    {
        var session = _sessionManager.GetCurrentSession();
        if (session is null)
        {
            return null;
        }

        var properties = await session.TryGetMediaPropertiesAsync();
        var playback = session.GetPlaybackInfo();
        var timeline = session.GetTimelineProperties();

        return new MediaInfo(
            properties.Title ?? string.Empty,
            properties.Artist ?? string.Empty,
            properties.AlbumTitle ?? string.Empty,
            AlbumArtUrl: null,
            IsPlaying: playback.PlaybackStatus == GlobalSystemMediaTransportControlsSessionPlaybackStatus.Playing,
            Duration: Math.Max(0, timeline.EndTime.TotalSeconds),
            Position: Math.Max(0, timeline.Position.TotalSeconds));
    }

    private async Task<bool> WithCurrentSession(
        Func<GlobalSystemMediaTransportControlsSession, Task<bool>> action)
    {
        var session = _sessionManager.GetCurrentSession();
        return session is not null && await action(session);
    }
}
