# LuCI IP Limiter — OpenWrt 25.12.6

LuCI package for OpenWrt 25.12.6 x86/64. The UI lists devices learned by OpenWrt host hints by hostname and MAC, stores rules in UCI, and supports blocking a client immediately or on a weekly schedule.

## Build APK with GitHub Actions

1. Create a GitHub repository and upload this project, including `.github/workflows/build-openwrt.yml`.
2. Push to `main` or `master`, or open **Actions → Build OpenWrt package → Run workflow**.
3. Open the completed workflow run and download artifact `luci-app-iplimiter-openwrt-25.12.6-x86-64`.
4. Transfer the APK to the router, then install it as root:

   ```sh
   apk add --allow-untrusted /tmp/luci-app-iplimiter-*.apk
   ```

The workflow downloads the official OpenWrt 25.12.6 x86/64 SDK and verifies its SHA256 before building. This APK only matches OpenWrt 25.12.6, target x86/64.

## Current limits

The UI stores a requested speed in kbit/s but **speed enforcement is not implemented yet**. Do not rely on saved speed values. Blocking and weekly schedules are implemented. Schedules use router local time; the after-midnight segment of an overnight window belongs to its selected start day.

Hostnames are sourced from LuCI host hints. A client without a hostname is shown by MAC if OpenWrt reports a hint for it; disconnected devices may not be present in the list.
