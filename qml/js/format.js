function formatTime(seconds) {
    var days = Math.floor(seconds / 86400);
    seconds %= 86400;
    var hours = Math.floor(seconds / 3600);
    seconds %= 3600;
    var minutes = Math.floor(seconds / 60);
    seconds %= 60;

    var parts = [];
    if (days > 0)
        parts.push(days + "d");
    if (hours > 0)
        parts.push(hours + "h");
    if (minutes > 0)
        parts.push(minutes + "m");
    
    // Always include seconds
    parts.push(seconds + "s");

    return parts.join(" ");
}
