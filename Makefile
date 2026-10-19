include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-iplimiter
PKG_VERSION:=1.0
PKG_RELEASE:=7
PKG_LICENSE:=GPL-2.0-only
PKG_MAINTAINER:=OpenWrt IP Limiter

include $(INCLUDE_DIR)/package.mk

# This package only installs scripts and LuCI assets; it has no source tree
# with a Makefile for the OpenWrt default compile step.
define Build/Compile
endef

define Package/luci-app-iplimiter
  SECTION:=luci
  CATEGORY:=LuCI
  SUBMENU:=3. Applications
  TITLE:=Per-device IP limiter and blocker
  DEPENDS:=+luci-base +nftables
  PKGARCH:=all
endef

define Package/luci-app-iplimiter/description
LuCI interface to select known devices by hostname and MAC, configure group bandwidth limits, block rules, and schedules.
endef

define Package/luci-app-iplimiter/install
	$(INSTALL_DIR) $(1)/www/luci-static/resources/view
	$(INSTALL_DATA) ./htdocs/luci-static/resources/view/iplimiter.js $(1)/www/luci-static/resources/view/iplimiter.js
	$(INSTALL_DIR) $(1)/etc/config $(1)/etc/init.d
	$(INSTALL_CONF) ./root/etc/config/iplimiter $(1)/etc/config/iplimiter
	$(INSTALL_BIN) ./root/etc/init.d/iplimiter $(1)/etc/init.d/iplimiter
	$(INSTALL_BIN) ./root/etc/init.d/iplimiter-cron $(1)/etc/init.d/iplimiter-cron
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) ./root/usr/sbin/iplimiter $(1)/usr/sbin/iplimiter
	$(INSTALL_DIR) $(1)/usr/share/luci/menu.d $(1)/usr/share/rpcd/acl.d
	$(INSTALL_DATA) ./root/usr/share/luci/menu.d/luci-app-iplimiter.json $(1)/usr/share/luci/menu.d/luci-app-iplimiter.json
	$(INSTALL_DATA) ./root/usr/share/rpcd/acl.d/luci-app-iplimiter.json $(1)/usr/share/rpcd/acl.d/luci-app-iplimiter.json
endef

$(eval $(call BuildPackage,luci-app-iplimiter))
