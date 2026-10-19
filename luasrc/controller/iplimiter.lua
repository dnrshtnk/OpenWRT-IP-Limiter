module("luci.controller.iplimiter", package.seeall)

function index()
	entry({ "admin", "network", "iplimiter" }, view("iplimiter"), _("IP Limiter"), 90)
end
