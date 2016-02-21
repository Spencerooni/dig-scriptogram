#!/usr/bin/env node
/*
  Parses ELB log files to find slow responses for ELB int processing time, backend processing time or upstream processing time.
  
  Download ELB logs from S3 bucket:
  aws s3 sync s3://pub-ext-elb/AWSLogs/719728721003/elasticloadbalancing/eu-west-1/2015/08/28 .
  2015-08-28T08:08:11.042771Z publishing-external-elb-https 93.15.210.26:26023 11.240.54.67:80 0.000023 1.069548 0.00003 200 200 0 3372 "GET https://mot-testing.i-env.net:443/ HTTP/1.1" "Mozilla/5.0 (Linux; Android 4.4.2; V919 3G Air Core8 Build/KOT49H) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/44.0.2403.133 Safari/537.36" ECDHE-RSA-AES128-GCM-SHA256 TLSv1.2

  requires installation by: 

  $ npm install commander -g
  $ npm install line-by-line -g
  $ npm install -g

  PC 20/02/16 node.js version
*/

cli = require ('commander');
LineByLineReader = require('line-by-line');
util = require ('util');
debug = false;

//
//   Parse an ELB logfile line to identify which of the 3 responses times are slower than the threshold. 
//
function parseLine (line)
{
    var time1 = "-", time2 = "-", time3 = "-";
    var items = line.split(' ');
    var date = items[0], elb = items[1], clientip = items[2], referrer = items[3], request_processing_time = items[4], backend_processing_time = items[5], response_processing_time = items[6], elbstatus = items[7], backendstatus = items[8], rbytes = items[9], sbytes = items[10], verb = items[11], url = items[12];
    if (cli.e1 && (request_processing_time > cli.threshold)) { time1 = request_processing_time; }
    if (cli.e2 && (backend_processing_time > cli.threshold)) { time2 = backend_processing_time; }
    if (cli.e3 && (response_processing_time > cli.threshold)) { time3 = response_processing_time; }
    if ((time1 != "-") || (time2 != "-") || (time3 != "-"))
    {
        if (cli.verbose) { console.log(line); } 
        if (cli.short) { console.log("%s %s %s %s %s (%s)", date, time1, time2, time3, url, backendstatus); }
    }
}

//
//   Read an ELB logfile line-by-line for efficiency and parse for slow response times. 
//
function parseElblogfile (filename)
{
	var reader = new LineByLineReader(filename);
	console.log("=========%s=========", filename);

	reader.on('line', function (line) {
		parseLine(line);
	})

	reader.on('error', function (err) {
		console.log("failed to read line. " + err);
	})
}

cli
	.version('0.3')
	.option('-e1, --e1', 'Compare time of elb internal processing time (sec). Defaults if none specified.')
	.option('-e2, --e2', 'Compare time of elb backend processing time (sec). Defaults if none specified.')
	.option('-e3, --e3', 'Compare time of elb response processing time (sec). Defaults if none specified.')
	.option('-t, --threshold <threshold>', 'threshold in seconds of time threshold to compare against. Default is 1 sec. ', 1.0)
	.option('-s, --short', 'Display time and 3 responses times only in results. Default. ')
	.option('-v, --verbose', 'Display whole log statement in results.')
	.action(function() {
		if (debug) { console.log('#files = %s, files = %s, threshold = %s', cli.args.length, cli.args, cli.threshold); }
	})
	.parse(process.argv);

if (!cli.args.length) cli.help();
if (typeof cli.verbose === 'undefined') { cli.short = true; }
if (typeof cli.e1 === 'undefined' && typeof cli.e2 === 'undefined' && typeof cli.e3 === 'undefined') { cli.e1 = 1, cli.e2 = 1, cli.e3 = 1; }

for (f = 0; f < cli.args.length-1; f++)
{
	if (debug) { console.log(cli.args[f]); }
	parseElblogfile(cli.args[f]);
}
