.pragma library

function searchUrl(query, language) {
    return "https://geocoding-api.open-meteo.com/v1/search?count=5&format=json&language="
        + language + "&name=" + encodeURIComponent(query.trim());
}
function validCoordinates(latitude, longitude) {
    return latitude !== null && latitude !== undefined && latitude !== ""
        && longitude !== null && longitude !== undefined && longitude !== ""
        && Number.isFinite(Number(latitude)) && Math.abs(Number(latitude)) <= 90
        && Number.isFinite(Number(longitude)) && Math.abs(Number(longitude)) <= 180;
}
function locations(data) {
    if (!Array.isArray(data?.results)) return [];
    return data.results.filter(p => p.name && validCoordinates(p.latitude, p.longitude)).map(p => ({
        label: [p.name, p.admin1, p.country].filter((v, i, a) => v && a.indexOf(v) === i).join(", "),
        latitude: p.latitude, longitude: p.longitude
    }));
}
function forecastUrl(latitude, longitude) {
    if (!validCoordinates(latitude, longitude)) throw new Error("coordinates");
    return "https://api.open-meteo.com/v1/forecast?latitude=" + Number(latitude)
        + "&longitude=" + Number(longitude) + "&current=temperature_2m,weather_code,is_day&forecast_days=1";
}
function current(data) {
    const c = data?.current;
    if (!c || typeof c.temperature_2m !== "number" || !Number.isFinite(c.temperature_2m)
        || typeof c.weather_code !== "number" || !Number.isInteger(c.weather_code)) throw new Error("weather");
    return {temp: Math.round(c.temperature_2m) + "°", code: c.weather_code, day: c.is_day !== 0};
}
function description(code) {
    if (code === 0) return "WEATHER CLEAR";
    if (code <= 3) return "WEATHER CLOUDY";
    if (code === 45 || code === 48) return "WEATHER FOG";
    if ((code >= 71 && code <= 77) || code === 85 || code === 86) return "WEATHER SNOW";
    if (code >= 95) return "WEATHER STORM";
    return "WEATHER RAIN";
}
function icon(code, day) {
    if (code === 0) return day ? "sunny" : "clear_night";
    if (code === 1 || code === 2) return day ? "partly_cloudy_day" : "partly_cloudy_night";
    const key = description(code);
    return ({"WEATHER CLOUDY":"cloud", "WEATHER FOG":"foggy",
        "WEATHER SNOW":"weather_snowy", "WEATHER STORM":"thunderstorm", "WEATHER RAIN":"rainy"})[key] || "cloud";
}
