'use strict';

'require view';
'require form';
'require uci';
'require rpc';

var callHostHints = rpc.declare({ object: 'luci-rpc', method: 'getHostHints', expect: { '': {} } });

return view.extend({
	load: function() { return Promise.all([ callHostHints(), uci.load('iplimiter') ]); },
	render: function(data) {
		var hints = data[0] || {}, m = new form.Map('iplimiter', _('IP Limiter'), _('Choose a connected device by name and MAC. Configure a speed limit or complete block, then optionally schedule it.'));
		var s = m.section(form.GridSection, 'client', _('Device rules'));
		s.addremove = true; s.anonymous = true;
		var mac = s.option(form.ListValue, 'mac', _('Device (MAC)'));
		mac.rmempty = false;
		mac.load = function(section_id) {
			Object.keys(hints).sort().forEach(function(addr) {
				var h = hints[addr], name = h.name || h.hostname || addr;
				mac.value(addr, name + ' (' + addr + ')');
			});
			return uci.get('iplimiter', section_id, 'mac');
		};
		var mode = s.option(form.ListValue, 'mode', _('Action'));
		mode.value('limit', _('Limit speed')); mode.value('block', _('Block completely'));
		var rate = s.option(form.Value, 'rate', _('Speed limit (kbit/s)'));
		rate.datatype = 'and(uinteger,min(1))'; rate.depends('mode', 'limit'); rate.default = '1024';
		var enabled = s.option(form.Flag, 'enabled', _('Rule enabled')); enabled.default = '1'; enabled.rmempty = false;
		var sched = s.option(form.ListValue, 'schedule', _('Schedule'));
		sched.value('always', _('Always')); sched.value('cron', _('Time window'));
		var start = s.option(form.Value, 'start', _('Start time (HH:MM)')); start.default = '22:00'; start.depends('schedule', 'cron');
		var stop = s.option(form.Value, 'stop', _('End time (HH:MM)')); stop.default = '07:00'; stop.depends('schedule', 'cron');
		var days = s.option(form.DynamicList, 'days', _('Days')); days.depends('schedule', 'cron');
		['mon','tue','wed','thu','fri','sat','sun'].forEach(function(d) { days.value(d, _(d)); });
		return m.render();
	}
});
