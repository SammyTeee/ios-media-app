public sealed record MediaInfo(
    string Title,
    string Artist,
    string Album,
    string? AlbumArtUrl,
    bool IsPlaying,
    double Duration,
    double Position);
