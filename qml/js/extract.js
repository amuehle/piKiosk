function getDomain(url) {
    const regex = /^(?:https?:\/\/)?(www\.)?([^\/]+)/;
    const match = url.match(regex);
    return match ? match[0].replace(/^https?:\/\//, "") : null;
}
