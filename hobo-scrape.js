var casper = require('casper').create();
var fs = require('fs');

var export_dir = '';
var hobo_base_url = 'https://www.hobolink.com/p/';
var sensor_id = null;

//casper.options.waitTimeout = 5000;	// default is 5000 (5 seconds)

function parse_chart_data(raw_chart_data) {
	var match_groups = raw_chart_data.match(/var\W+(\w+)\W+(Date,.*)'/);
	var lines = [];
	if (match_groups !== null) {
		raw_lines = match_groups[2].split('\\n');
		for (var i = 0; i < raw_lines.length; i++) {
			if (!raw_lines[i].match(/NaN/)) {
				lines.push(raw_lines[i]);
			}
		}
	}

	return lines;
}

function fixup_headers(header_line, header_suffux) {
	var headers = header_line.split(',');
	for (var f = 1; f < headers.length; f++) {
		headers[f] = headers[f] + ':' + header_suffux;
	}

	return headers.join(',');
}

casper.start();

casper.then(function() {
	var sensor_name = casper.cli.args[0];
	if (casper.cli.args.length < 2) {
		this.echo('Syntax: hobo-scrape.js <output-directory> <station-id>');
		this.exit(1);
		this.bypass(1);
	}	

	export_dir = casper.cli.args[0];
	sensor_id = casper.cli.args[1];
});

casper.then(function() {
	this.echo('Open page [' + hobo_base_url + sensor_id + '].');
	this.open(hobo_base_url + sensor_id);
});

casper.waitForSelector('a[href="#tab3"]');

casper.thenClick('a[href="#tab3"]', function() {
	this.echo('Wait for charts to load...');
});

casper.waitForSelector('.graphs > div font');

casper.waitFor(function() {	
	var charts = casper.getElementsInfo('.graphs > div');
	//console.log('There are ' + charts.length + ' charts');

	var scripts = casper.getElementsInfo('.graphs > div > script');
	//console.log('There are ' + scripts.length + ' scripts');

	var datasets = 0;
	for (var i = 0; i < scripts.length; i++) {
		// Cheap solution, just look at script size to guess how many rows
		if (scripts[i].text.length > 500) {
			datasets++;
		}
		// Expensive solution, parse the script and get the actual number of rows.
		// chart_data = parse_chart_data(scripts[i].text);
		// if (chart_data.length > 2) {
		// 	datasets.push(chart_data);
		// }
	}
	//console.log('There are ' + datasets + ' data sets');

	return datasets >= charts.length;
});

var charts = {};
casper.then(function() {
	this.echo('Parse chart data...');
	charts = casper.evaluate(function(cssSelector) {
		var obj = {};
		__utils__.findAll(cssSelector).forEach(function(el){
			var header = el.querySelector('.legend-header').textContent.split(':');
			obj[el.querySelector('font').textContent.trim()] = {
				"measurement": header[0].trim(),
				"units": header[1].trim(),
				"script": el.querySelector('script').textContent.trim()
			};
		});
		return obj;
	}, '.graphs > div');

});

// Parse chart data from script variable assignment
casper.then(function() {
	for (var key in charts) {
		this.echo('Found sensor [' + key + '].');
		// Write out raw script data (debugging)
		//fs.write(key + '.script', charts[key].script, 'w');

		charts[key].data = parse_chart_data(charts[key].script);
	}
});

casper.run(function() {
	for (var key in charts) {
		//console.log(key + ' : ' + charts[key].measurement + ', ' + charts[key].units);
		var lines = charts[key].data;

		var header_suffux = charts[key].measurement + ':' + charts[key].units;
		lines[0] = fixup_headers(lines[0], header_suffux);

		if (!fs.isDirectory(export_dir)) {
			fs.makeDirectory(export_dir);
		}

		var fn = export_dir + '/' + key + '.csv';
		fs.write(fn, lines.join('\n'), 'w');
		this.echo('Saved [' + fn + '].');
	}

    this.exit();
});
