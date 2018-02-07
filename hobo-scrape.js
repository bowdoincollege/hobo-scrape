var casper = require('casper').create();
var fs = require('fs');

var sensor_id = '2665cb0a357c93fc10bb84162133c89d';	//tower
var sensor_id = 'af109c8068362219390a99cec629f0f6';	//stream

//casper.options.waitTimeout = 10000; // default 10 second timeout

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

casper.start('https://www.hobolink.com/p/' + sensor_id, function() {
   this.echo('Loading initial page...');
   this.waitForSelector('a[href="#tab3"]');

});

casper.thenClick('a[href="#tab3"]', function(){
	this.echo('Waiting for tab to load...');
	this.waitForSelector('.graphs > div font');
});

//casper.wait(5000);
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
		// Save out for debug
		fs.write(key + '.csv', charts[key].script, 'w');
		
		charts[key].data = parse_chart_data(charts[key].script);
	}
});

casper.run(function() {
	for (var key in charts) {		
		console.log('----------------');
		console.log(key + ' : ' + charts[key].measurement + ', ' + charts[key].units);

		var lines = charts[key].data;
		lines[0] = 'Date,' + charts[key].measurement + ':' + charts[key].units;
		fs.write(key + '.csv', lines.join('\n'), 'w');
	}

    this.exit();
});