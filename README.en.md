# LuCI IP Limiter — OpenWrt 25.12

[Русский](README.md#русский) | [English](#english)

## English

LuCI application for OpenWrt 25.12. It lists devices known to the router by hostname and MAC address, lets you group devices, set a shared speed limit in kbit/s for download and upload, block a group, and schedule rules. The app interface includes Russian translations and follows the language selected in LuCI.

### Supported devices

- OpenWrt 25.12.6, x86/64.
- OpenWrt 25.12.5, MediaTek Filogic, `aarch64_cortex-a53` architecture, including the Xiaomi Mi Router AX3000T.

### Build APKs

GitHub Actions builds APKs for both architectures when changes are pushed to `main` or `master`. You can also start a build manually from **Actions → Build OpenWrt packages → Run workflow**. Download the artifact for your router from the completed run:

- `luci-app-iplimiter-openwrt-25.12.6-x86-64`
- `luci-app-iplimiter-openwrt-25.12.5-aarch64_cortex-a53`

### Install directly on the router

If the router has internet access and `curl` (or `wget`) installed, push `install.sh` to GitHub and run:

```sh
curl -fsSL https://raw.githubusercontent.com/dnrshtnk/OpenWRT-IP-Limiter/refs/heads/main/install.sh | sh
```

The installer checks the router architecture, downloads the APK to a temporary directory, compares versions, and skips installation if the same or a newer version is already installed. Use the `curl | sh` pipeline with OpenWrt's `sh`; Bash process substitution such as `<(curl ...)` may not be supported by the router shell. The router needs access to GitHub.

### Limitations

Speed limits use nftables packet policing, which drops packets above the configured rate rather than shaping a queue. TCP usually backs off; UDP packets above the limit are lost. Devices in a group share a limit separately in each direction, and IPv4 and IPv6 addresses are covered. Hardware or software flow offloading may bypass these rules, so disable it for reliable enforcement.

Schedules use the router's local time. Leaving the day list empty means every day. The after-midnight part of an overnight window belongs to the day on which the window started. Run `/usr/sbin/iplimiter clock` to inspect the router clock.

Device names come from LuCI host hints. Disconnected devices or clients without saved host information may not appear in the list.
