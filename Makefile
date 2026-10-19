include $(TOPDIR)/rules.mk

LUCI_TITLE:=LuCI IP Limiter
LUCI_DEPENDS:=+luci-base +nftables
LUCI_PKGARCH:=all
PKG_LICENSE:=GPL-2.0-only
PKG_MAINTAINER:=Local build

include ../../luci.mk

# call BuildPackage - OpenWrt buildroot signature
