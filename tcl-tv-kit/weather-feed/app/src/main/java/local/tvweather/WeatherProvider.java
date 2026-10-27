package local.tvweather;

import android.content.ContentProvider;
import android.content.ContentValues;
import android.content.Context;
import android.content.SharedPreferences;
import android.database.Cursor;
import android.database.MatrixCursor;
import android.net.Uri;
import android.os.Binder;
import android.os.Bundle;

import org.json.JSONArray;
import org.json.JSONObject;

import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.util.Locale;
import java.util.concurrent.atomic.AtomicBoolean;

/**
 * One read-only row, content://local.tvweather/now: the temperature in degrees Celsius, today's high and low, the
 * conditions, the US air quality index and the place. Data: Open-Meteo (no key). The answer is cached; a query that
 * finds it older than STALE_MS starts one background fetch and returns the cache meanwhile, then notifies. No
 * service, no alarm, no boot receiver: the app only runs while the launcher asks.
 */
public class WeatherProvider extends ContentProvider {
    static final String[] COLS = {"temp", "feels", "high", "low", "condition", "symbol", "aqi", "aqi_label", "place", "updated", "aqi_source"};
    private static final long STALE_MS = 25 * 60 * 1000L;
    private static final long RETRY_MS = 2 * 60 * 1000L;
    private static final AtomicBoolean fetching = new AtomicBoolean();
    private static volatile long lastAttempt;

    @Override
    public boolean onCreate() {
        return true;
    }

    @Override
    public Cursor query(Uri uri, String[] projection, String selection, String[] args, String sort) {
        Context ctx = getContext();
        if (ctx == null) return null;
        SharedPreferences sp = ctx.getSharedPreferences("w", Context.MODE_PRIVATE);
        long updated = sp.getLong("updated", 0);
        long now = System.currentTimeMillis();
        boolean force = sp.getBoolean("force", false);
        if ((force || now - updated > STALE_MS) && now - lastAttempt > RETRY_MS) refresh(ctx.getApplicationContext());
        MatrixCursor c = new MatrixCursor(COLS);
        if (updated > 0) {
            c.addRow(new Object[]{sp.getInt("temp", 0), sp.getInt("feels", 0), sp.getInt("high", 0), sp.getInt("low", 0),
                    sp.getString("condition", ""), sp.getString("symbol", ""), sp.getInt("aqi", -1),
                    sp.getString("aqi_label", ""), sp.getString("place", ""), updated, sp.getString("aqi_source", "model")});
        }
        c.setNotificationUri(ctx.getContentResolver(), uri);
        return c;
    }

    /**
     * set_key: the owner's IQAir (AirVisual) API key, `content call --uri content://local.tvweather --method set_key --arg KEY`
     * (arg "clear" removes it). Only the ADB shell (uid 2000) or root may call it, so no other app can plant or replace a
     * key, and the key is never returned by query(): the launcher only ever sees the number.
     */
    @Override
    public Bundle call(String method, String arg, Bundle extras) {
        Bundle out = new Bundle();
        Context ctx = getContext();
        int uid = Binder.getCallingUid();
        String k = arg == null ? "" : arg.trim();
        boolean clear = "clear".equals(k);
        if (ctx == null || !"set_key".equals(method) || (uid != 2000 && uid != 0)
                || !(clear || k.matches("[0-9a-fA-F-]{36}"))) {
            out.putBoolean("ok", false);
            return out;
        }
        SharedPreferences.Editor e = ctx.getSharedPreferences("w", Context.MODE_PRIVATE).edit();
        if (clear) e.remove("iqair_key"); else e.putString("iqair_key", k);
        e.putBoolean("force", true);   // the next query fetches again; the old value stays until then
        e.apply();
        lastAttempt = 0;
        out.putBoolean("ok", true);
        return out;
    }

    private static void refresh(Context app) {
        if (!fetching.compareAndSet(false, true)) return;
        lastAttempt = System.currentTimeMillis();
        new Thread(() -> {
            try {
                fetch(app);
                app.getContentResolver().notifyChange(Uri.parse("content://local.tvweather/now"), null);
            } catch (Exception ignored) {
                // Offline or Open-Meteo down: keep the cached answer and try again after RETRY_MS.
            } finally {
                fetching.set(false);
            }
        }, "weather-fetch").start();
    }

    private static void fetch(Context app) throws Exception {
        String lat = app.getString(R.string.latitude), lon = app.getString(R.string.longitude);
        JSONObject w = new JSONObject(get("https://api.open-meteo.com/v1/forecast?latitude=" + lat + "&longitude=" + lon
                + "&current=temperature_2m,apparent_temperature,weather_code,is_day"
                + "&daily=temperature_2m_max,temperature_2m_min&timezone=auto&forecast_days=1"));
        JSONObject cur = w.getJSONObject("current");
        JSONObject day = w.getJSONObject("daily");
        int code = cur.getInt("weather_code");
        boolean isDay = cur.optInt("is_day", 1) == 1;
        int aqi = -1;
        try {
            JSONObject a = new JSONObject(get("https://air-quality-api.open-meteo.com/v1/air-quality?latitude=" + lat
                    + "&longitude=" + lon + "&current=us_aqi"));
            if (!a.getJSONObject("current").isNull("us_aqi")) aqi = (int) Math.round(a.getJSONObject("current").getDouble("us_aqi"));
        } catch (Exception ignored) {
            // Weather without air quality is still worth showing.
        }
        // Open-Meteo's index is a satellite-assimilated MODEL averaged over 24 hours, and it reads high in Dubai. If the
        // owner stored an IQAir key (set_key below, run by the owner), use IQAir's station-based reading instead.
        SharedPreferences prefs = app.getSharedPreferences("w", Context.MODE_PRIVATE);
        String source = "model";
        String key = prefs.getString("iqair_key", "");
        if (!key.isEmpty()) {
            try {
                JSONObject r = new JSONObject(get("https://api.airvisual.com/v2/nearest_city?lat=" + lat + "&lon=" + lon + "&key=" + key));
                if ("success".equals(r.optString("status"))) {
                    aqi = r.getJSONObject("data").getJSONObject("current").getJSONObject("pollution").getInt("aqius");
                    source = "iqair";
                }
            } catch (Exception ignored) {
                // Bad key, quota or offline: keep the model value rather than show nothing.
            }
        }
        SharedPreferences.Editor e = prefs.edit();
        e.putString("aqi_source", source);
        e.putInt("temp", (int) Math.round(cur.getDouble("temperature_2m")));
        e.putInt("feels", (int) Math.round(cur.getDouble("apparent_temperature")));
        e.putInt("high", (int) Math.round(first(day, "temperature_2m_max")));
        e.putInt("low", (int) Math.round(first(day, "temperature_2m_min")));
        e.putString("condition", condition(code, isDay));
        e.putString("symbol", symbol(code, isDay));
        e.putInt("aqi", aqi);
        e.putString("aqi_label", aqiLabel(aqi));
        e.putString("place", app.getString(R.string.place));
        e.putLong("updated", System.currentTimeMillis());
        e.putBoolean("force", false);
        e.apply();
    }

    private static double first(JSONObject o, String key) throws Exception {
        JSONArray a = o.getJSONArray(key);
        return a.getDouble(0);
    }

    private static String get(String url) throws Exception {
        HttpURLConnection c = (HttpURLConnection) new URL(url).openConnection();
        c.setConnectTimeout(8000);
        c.setReadTimeout(8000);
        c.setRequestProperty("User-Agent", "tv-weather-feed/1.0");
        try (InputStream in = c.getInputStream()) {
            java.io.ByteArrayOutputStream out = new java.io.ByteArrayOutputStream();
            byte[] buf = new byte[4096];
            int n;
            while ((n = in.read(buf)) > 0) out.write(buf, 0, n);
            return new String(out.toByteArray(), StandardCharsets.UTF_8);
        } finally {
            c.disconnect();
        }
    }

    /** WMO weather interpretation codes, as Open-Meteo returns them. */
    static String condition(int code, boolean isDay) {
        if (code == 0) return isDay ? "Sunny" : "Clear";
        if (code == 1) return isDay ? "Mostly sunny" : "Mostly clear";
        if (code == 2) return "Partly cloudy";
        if (code == 3) return "Overcast";
        if (code == 45 || code == 48) return "Fog";
        if (code >= 51 && code <= 57) return "Drizzle";
        if (code >= 61 && code <= 67) return "Rain";
        if (code >= 71 && code <= 77) return "Snow";
        if (code >= 80 && code <= 82) return "Showers";
        if (code == 85 || code == 86) return "Snow showers";
        if (code >= 95) return "Thunderstorm";
        return "";
    }

    /** Plain text symbols that have a monochrome form, so they take the text colour. */
    static String symbol(int code, boolean isDay) {
        if (code <= 1) return isDay ? "☀" : "☾";
        if (code <= 3 || code == 45 || code == 48) return "☁";
        if (code >= 71 && code <= 77 || code == 85 || code == 86) return "❄";
        if (code >= 95) return "ϟ";
        return "☂";
    }

    /** US EPA bands. */
    static String aqiLabel(int aqi) {
        if (aqi < 0) return "";
        if (aqi <= 50) return "Good";
        if (aqi <= 100) return "Moderate";
        if (aqi <= 150) return "Unhealthy for sensitive groups";
        if (aqi <= 200) return "Unhealthy";
        if (aqi <= 300) return "Very unhealthy";
        return "Hazardous";
    }

    @Override public String getType(Uri uri) { return "vnd.android.cursor.item/vnd.local.tvweather.now"; }
    @Override public Uri insert(Uri uri, ContentValues values) { return null; }
    @Override public int delete(Uri uri, String selection, String[] args) { return 0; }
    @Override public int update(Uri uri, ContentValues values, String selection, String[] args) { return 0; }
}
