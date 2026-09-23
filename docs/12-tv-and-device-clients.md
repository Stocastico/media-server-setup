# TV and device clients

For a "streaming service" look and feel, a third-party client usually beats
the built-in/official app: **Wholphin** on Android/Google TV, **Infuse** or
**Swiftfin** on Apple TV, and the official app on Samsung/LG.

| Device | Best pick | Alternative | Notes |
|---|---|---|---|
| Android TV / Google TV / Fire TV | Wholphin | Official Jellyfin for Android TV | Wholphin is built for remotes, lighter, and looks more like a commercial streaming app |
| Apple TV 4K | Infuse (paid tier for some formats) | Swiftfin, Moonfin | Best picture/audio handling of the bunch |
| Samsung TV (Tizen 6+, 2021+) | Official Jellyfin app (Samsung store) | Moonfin | Browser-based player: more likely to transcode instead of direct-play |
| LG TV (webOS) | Official Jellyfin app (LG Content Store) | Moonfin | Same caveat as Samsung |
| Android phone/tablet | Findroid | Official app | Supports downloads for offline viewing |
| iPhone/iPad | Swiftfin | Infuse, Moonfin | |
| PC / Mac | Jellyfin Desktop | Web browser | |
| Any TV, via Kodi | Kodi + the Jellyfin for Kodi add-on | — | Most flexible, least "streaming app" polish |

**Moonfin** runs on almost every platform (Android TV, Apple TV, Roku,
Tizen, webOS) if you'd rather have one identical UI everywhere than the
single best client per platform.

**Practical advice**: if your TV's built-in browser/app stutters or
transcodes constantly, a cheap streaming box (Google TV Streamer, Apple TV
4K, Nvidia Shield) running the apps above usually fixes it outright, and is
often cheaper than the time spent fighting the TV's own OS.

## Connecting a TV or phone, step by step

1. **Enable Quick Connect once** (lets TVs and other keyboard-less devices
   log in without typing a password on a remote): as admin, *Dashboard →
   General* → tick *Enable Quick Connect* → *Save*.
2. Install the app from the TV's or phone's store (see the table above).
3. **Add the server**: the app usually finds it automatically on the home
   network via LAN discovery. If not, type `http://192.168.1.10:8096`
   manually. From outside home (once Tailscale is set up, see
   [13-remote-access-tailscale.md](13-remote-access-tailscale.md)), use
   `http://mediaserver:8096` instead.
4. **Log in with Quick Connect**: choose *Quick Connect* on the TV — it
   shows a 6-character code. On your phone or PC, open Jellyfin logged in
   as that family member → avatar → *Settings → Quick Connect* → enter the
   code → *Authorize*.
5. **Set playback quality for the home network**: in the app's *Playback*
   (or *Video*) settings → *Max Streaming Bitrate* → the highest value (or
   *Auto*), so it direct-plays on the LAN instead of unnecessarily
   transcoding.
6. **Audio**: if the TV is connected to a soundbar or AV receiver that
   supports Dolby/DTS, enable audio passthrough (AC3/EAC3/DTS) in the app;
   otherwise leave it off so the TV's own speakers get a compatible stereo
   mix.
7. **Test**: play a movie with several audio tracks and check it starts in
   that user's preferred language, with subtitles following the *Smart*
   rule set in [08-jellyfin.md](08-jellyfin.md).

If a particular file always transcodes on one device, open the playback
info overlay in the app (or *Dashboard → Activity* on the server) to see
the stated reason — usually an audio codec the device can't decode (DTS,
TrueHD) or image-based subtitles it can't render natively.

Next: [13-remote-access-tailscale.md](13-remote-access-tailscale.md)
