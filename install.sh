#!/bin/sh
set -eu

PACKAGE='luci-app-iplimiter'
RELEASE_URL='https://github.com/dnrshtnk/OpenWRT-IP-Limiter/releases/latest/download'

log() {
	printf '%s\n' "iplimiter: $*"
}

fail() {
	printf '%s\n' "iplimiter: ошибка: $*" >&2
	exit 1
}

cleanup() {
	[ -n "${APK_FILE:-}" ] && rm -f "$APK_FILE"
}
trap cleanup EXIT HUP INT TERM

[ "$(id -u)" = 0 ] || fail 'запустите установщик от root.'
command -v apk >/dev/null 2>&1 || fail 'не найден apk; нужен OpenWrt 25.12 или совместимая система.'
[ -r /etc/openwrt_release ] || fail 'не найден /etc/openwrt_release.'

router_arch=$(sed -n "s/^DISTRIB_ARCH='\([^']*\)'$/\1/p" /etc/openwrt_release | head -n 1)
case "$router_arch" in
	aarch64_cortex-a53) APK_NAME='luci-app-iplimiter-aarch64_cortex-a53.apk' ;;
	x86_64) APK_NAME='luci-app-iplimiter-x86-64.apk' ;;
	*) fail "неподдерживаемая архитектура роутера: ${router_arch:-не определена}." ;;
esac
APK_URL="$RELEASE_URL/$APK_NAME"
APK_FILE="/tmp/$APK_NAME"

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

# The release asset has a stable name; read the actual package identity and
# version from the downloaded APK v3 metadata instead of its filename.
metadata=$(apk adbdump "$APK_FILE") || fail 'не удалось прочитать метаданные APK.'
package_name=$(printf '%s\n' "$metadata" | awk '$1 == "name:" { print $2; exit }')
target_version=$(printf '%s\n' "$metadata" | awk '$1 == "version:" { print $2; exit }')
[ "$package_name" = "$PACKAGE" ] || fail "в APK найден неожиданный пакет: ${package_name:-не определён}."
[ -n "$target_version" ] || fail 'не удалось определить версию APK.'

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
