#!/bin/sh
set -eu

PACKAGE='luci-app-iplimiter'
APK_URL='https://github.com/dnrshtnk/OpenWRT-IP-Limiter/releases/download/1.0/luci-app-iplimiter-1.0-r13_aarch64_cortex-a53.apk'
APK_NAME=${APK_URL##*/}
EXPECTED_ARCH='aarch64_cortex-a53'
APK_FILE="/tmp/$APK_NAME"

log() {
	printf '%s\n' "iplimiter: $*"
}

fail() {
	printf '%s\n' "iplimiter: ошибка: $*" >&2
	exit 1
}

cleanup() {
	rm -f "$APK_FILE"
}
trap cleanup EXIT HUP INT TERM

[ "$(id -u)" = 0 ] || fail 'запустите установщик от root.'
command -v apk >/dev/null 2>&1 || fail 'не найден apk; нужен OpenWrt 25.12 или совместимая система.'
[ -r /etc/openwrt_release ] || fail 'не найден /etc/openwrt_release.'

router_arch=$(sed -n "s/^DISTRIB_ARCH='\([^']*\)'$/\1/p" /etc/openwrt_release | head -n 1)
[ "$router_arch" = "$EXPECTED_ARCH" ] || fail "APK предназначен для $EXPECTED_ARCH, архитектура роутера: ${router_arch:-не определена}."

case "$APK_NAME" in
	"$PACKAGE-"*_"$EXPECTED_ARCH".apk) ;;
	*) fail "неожиданное имя APK: $APK_NAME" ;;
esac
target_version=${APK_NAME#"$PACKAGE-"}
target_version=${target_version%_"$EXPECTED_ARCH".apk}
[ -n "$target_version" ] || fail 'не удалось определить версию APK.'

if command -v curl >/dev/null 2>&1; then
	log "скачиваю $APK_NAME..."
	curl --fail --location --silent --show-error --connect-timeout 10 --max-time 180 --output "$APK_FILE" "$APK_URL" || fail 'не удалось скачать APK.'
elif command -v wget >/dev/null 2>&1; then
	log "скачиваю $APK_NAME..."
	wget -O "$APK_FILE" "$APK_URL" || fail 'не удалось скачать APK.'
else
	fail 'не найден curl или wget.'
fi
[ -s "$APK_FILE" ] || fail 'скачанный APK пуст.'

installed_version=$(apk list --installed --manifest "$PACKAGE" 2>/dev/null | awk -v package="$PACKAGE" '$1 == package { print $2; exit }')
if [ -n "$installed_version" ]; then
	comparison=$(apk version -t "$target_version" "$installed_version") || fail 'apk не смог сравнить версии.'
	case "$comparison" in
		'=') log "уже установлена версия $installed_version; обновление не требуется."; exit 0 ;;
		'>') log "обновляю $PACKAGE: $installed_version -> $target_version" ;;
		'<') log "установлена более новая версия $installed_version; APK $target_version пропущен."; exit 0 ;;
		*) fail "неизвестный результат сравнения версий: $comparison" ;;
	esac
else
	log "пакет не установлен; устанавливаю версию $target_version."
fi

apk add --repositories-file /dev/null --allow-untrusted --upgrade "$APK_FILE" || fail 'установка APK завершилась ошибкой.'
installed_version=$(apk list --installed --manifest "$PACKAGE" 2>/dev/null | awk -v package="$PACKAGE" '$1 == package { print $2; exit }')
[ "$installed_version" = "$target_version" ] || fail "проверка после установки не пройдена (ожидалась $target_version, получена ${installed_version:-неизвестно})."
log "установлена версия $installed_version."
