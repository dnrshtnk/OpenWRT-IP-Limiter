'use strict';

'require view';
'require form';
'require uci';
'require rpc';

var callHostHints = rpc.declare({
	object: 'luci-rpc',
	method: 'getHostHints',
	expect: { '': {} }
});

return view.extend({
	load: function() {
		return Promise.all([ callHostHints(), uci.load('iplimiter') ]);
	},

	render: function(data) {
		var hints = data[0] || {};
		var m = new form.Map('iplimiter', _('IP Limiter'),
			_('Choose one or more known devices for each rule.'));
		var s = m.section(form.GridSection, 'client', _('Device groups'));
		s.addremove = true;
		s.anonymous = true;
		s.add_caption = _('Add device group');

		var name = s.option(form.Value, 'name', _('Group name'));
		name.rmempty = false;
		name.placeholder = _('For example: Kids');
		name.cfgvalue = function(section_id) {
			return uci.get('iplimiter', section_id, 'name') || section_id;
		};

		var devices = s.option(form.MultiValue, 'macs', _('Devices'));
		devices.multiple = true;
		devices.rmempty = false;
		Object.keys(hints).sort().forEach(function(addr) {
			var hint = hints[addr] || {};
			var label = hint.name || hint.hostname || addr;
			devices.value(addr, label + ' (' + addr + ')');
		});
		// Keep existing single-device rules selectable after upgrading.
		uci.sections('iplimiter', 'client').forEach(function(section) {
			var addr = section.mac;
			if (addr && !devices.keylist.includes(addr))
				devices.value(addr, addr + ' (' + _('saved rule') + ')');
		});
		devices.cfgvalue = function(section_id) {
			var selected = uci.get('iplimiter', section_id, 'macs');
			if (selected && selected.length)
				return selected;
			var legacy = uci.get('iplimiter', section_id, 'mac');
			return legacy ? [ legacy ] : [];
		};
		devices.write = function(section_id, value) {
			uci.unset('iplimiter', section_id, 'mac');
			return uci.set('iplimiter', section_id, 'macs', value);
		};

		var mode = s.option(form.ListValue, 'mode', _('Action'));
		mode.value('limit', _('Limit speed'));
		mode.value('block', _('Block completely'));

		var rate = s.option(form.Value, 'rate', _('Speed limit (kbit/s)'));
		rate.datatype = 'and(uinteger,min(1))';
		rate.depends('mode', 'limit');
		rate.default = '1024';

		var enabled = s.option(form.Flag, 'enabled', _('Rule enabled'));
		enabled.default = '1';
		enabled.rmempty = false;

		var sched = s.option(form.ListValue, 'schedule', _('Schedule'));
		sched.value('always', _('Always'));
		sched.value('cron', _('Time window'));

		var start = s.option(form.Value, 'start', _('Start time (HH:MM)'));
		start.default = '22:00';
		start.depends('schedule', 'cron');
		var stop = s.option(form.Value, 'stop', _('End time (HH:MM)'));
		stop.default = '07:00';
		stop.depends('schedule', 'cron');
		var days = s.option(form.DynamicList, 'days', _('Days'));
		days.depends('schedule', 'cron');
		[ 'mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun' ].forEach(function(day) {
			days.value(day, _(day));
		});

		return m.render();
	}
});
