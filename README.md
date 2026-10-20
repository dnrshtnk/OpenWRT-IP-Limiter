# LuCI IP Limiter — OpenWrt 25.12.6

LuCI package for OpenWrt 25.12.6 x86/64 and 25.12.5 MediaTek Filogic. The UI lists devices learned by OpenWrt host hints by hostname and MAC, lets you select several devices in one named group, applies a shared kbit/s cap to the group in both directions, and supports blocking a group immediately or on a weekly schedule.

The LuCI interface includes Russian translations and follows the language selected in LuCI.

## Build APKs with GitHub Actions

1. Create a GitHub repository and upload this project, including `.github/workflows/build-openwrt.yml`.
2. Push to `main` or `master`, or open **Actions → Build OpenWrt package → Run workflow**.
3. Open the completed workflow run and download the artifact for your router:
   - `luci-app-iplimiter-openwrt-25.12.6-x86-64`
   - `luci-app-iplimiter-openwrt-25.12.5-aarch64_cortex-a53` (Xiaomi Mi Router AX3000T)
4. Transfer the APK to the router, then install it as root:

   ```sh
   apk add --allow-untrusted /tmp/luci-app-iplimiter-*.apk
   ```

The workflow downloads and verifies the matching OpenWrt SDK before building each APK. Install the x86/64 APK on the 25.12.6 x86/64 router and the MediaTek Filogic APK on the 25.12.5 router.

## Current limits

Speed caps use nftables byte-rate limits with one shared token bucket per group and direction. Excess packets are dropped, so this is policing rather than a queue-based shaper; TCP flows back off while UDP traffic may lose packets above the cap. IPv4 and IPv6 addresses in a group share the same bucket. This method coexists with SQM and does not need `tc` or extra kernel modules. If firewall software or hardware flow offloading is enabled, it may bypass these rules; disable flow offloading for reliable enforcement. Blocking and weekly schedules are also supported. Schedules use router local time; the after-midnight segment of an overnight window belongs to its selected start day.

Hostnames are sourced from LuCI host hints. A client without a hostname is shown by MAC if OpenWrt reports a hint for it; disconnected devices may not be present in the list. For scheduled groups, leaving the day list empty means every day. Run `/usr/sbin/iplimiter clock` to inspect the router's local date, time, timezone, and weekday; policy-change log entries include the same clock information.
