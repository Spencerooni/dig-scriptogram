## grep_elb.pl (Perl5)

grep_elb.pl find slow responses times from AWS ELB logs. 

First of all get some ELB access logs, for example from Publishing ELB and Warden ELB from their S3 buckets for 28th August:

```
$ mkdir pub-elb
$ aws s3 sync s3://pub-ext-elb/AWSLogs/719728721003/elasticloadbalancing/eu-west-1/2015/08/28 pub-elb
$ mkdir warden-elb
$ aws s3 sync s3://warden-az1/AWSLogs/719728721003/elasticloadbalancing/eu-west-1/2015/08/28 warden-elb
```

Then run grep_elb.pl on all the log files you've downloaded to show processing time above 5 secs:

```
$ perl grep_elb.pl -t 5 *.log | tee warden-28th
```

This will output something like below. It will only print the value of the 3 processing time values if it is greater than the threshold. 

```
========719728721003_elasticloadbalancing_eu-west-1_publishing-external-elb-https_20150828T0005Z_XX.XXX.XXX.XXX_4i6lq586.log=========
2015-08-27T23:57:16.890169Z - 54.633297 -
2015-08-27T23:58:09.425847Z - 2.188004 -
2015-08-27T23:57:17.066736Z - 54.609933 -
2015-08-27T23:58:00.416854Z - 11.293701 -
2015-08-27T23:57:16.857100Z - 54.880973 -
2015-08-27T23:58:09.539551Z - 2.255389 -
2015-08-27T23:57:52.561908Z - 19.233133 -
2015-08-27T23:57:56.632728Z - 15.213939 -
```

If you just want to isolate slow tie processing within the ELB internals pass the -1 flag. If you just want to isolate backend delays pass -2. 

If you want to step through the results chronologically (since AWS emits many access logs files) and remove the headers sort it:

```
$ cat warden-28th | grep -v ========= | sort -n > warden-28th-sorted
```

You can pass the following options to grep_elb.pl: 

```
 -1              Compare time of elb internal processing time (sec). Defaults if none specified. 
 -2              Compare time of backend processing time (sec). Defaults if none specified. 
 -3              Compare time of response processing time (sec). Defaults if none specified. 
 -threshold n    n in seconds of time threshold to compare against. Default is 1 sec. 
 -short          Display time and 3 responses times only in results. Default. 
 -verbose        Display whole log statement in results.
```

## The Perl 6 version

The Perl6 version grep_elb.p6 is identical in functionality though the arguments are different because of the way Perl6 processes command-line arguments. 

```
WARNING: The Perl6 version is *much* slower to run than the Perl5 or Ruby versions. 
```

You can run grep_elb.p6 on all the log files you've downloaded to show processing time above 5 secs with:

```
$ perl6 grep_elb.p6 --threshold=5 *.log | tee warden-28th
```

You can pass the following options to grep_elb.p6: 

```
--e1             Compare time of elb internal processing time (sec). Defaults if none specified.
--e2             Compare time of backend processing time (sec). Defaults if none specified.
--e3             Compare time of response processing time (sec). Defaults if none specified.
--threshold=n    n in seconds of time threshold to compare against. Default is 1 sec.
--verbose        Display whole log statement in results. Default is time and 3 responses times only in results.
```

## The Ruby version

The Ruby version grep_elb.rb is identical in functionality also but again different in the way you call it because of the way Ruby processes command-line arguments. 

You can run grep_elb.rb on all the log files you've downloaded to show processing time above 5 secs with:

```
$ ruby grep_elb.rb --threshold=5 *.log | tee warden-28th
```

You can pass the following options to grep_elb.rb: 

```
-1, --1                          Compare time of elb internal processing time (sec). Defaults if none specified.
-2, --2                          Compare time of backend processing time (sec). Defaults if none specified.
-3, --3                          Compare time of response processing time (sec). Defaults if none specified.
-t, --threshold n                n in seconds of time threshold to compare against. Default is 1 sec.
-d, --debug                      Display debug information.
-v, --verbose                    Display whole log statement in results.
```

## The Lua version

The Lua version grep_elb.lua is also identical in functionality but different because of the way the Lua module lapp processes the command-line arguments. There is no built-in lua command argument processing so I've used the lapp module which is included in the repo. It will only allow single letter arguments and won't permit numbers. 

You can run grep_elb.lua on your log files with:

```
$ lua grep_elb.lua --threshold=5 *.log | tee warden-28th
```

You can pass the following options to grep_elb.lua: 

```
-u, --e1                         Compare time of elb internal processing time (sec). Defaults if none specified.
-e, --e2                         Compare time of backend processing time (sec). Defaults if none specified.
-d, --e3                         Compare time of response processing time (sec). Defaults if none specified.
-t, --threshold n                n in seconds of time threshold to compare against. Default is 1 sec.
-d, --debug                      Display debug information.
-v, --verbose                    Display whole log statement in results.
```

## The Node.js version

The Node.js version grepelb is also identical in functionality but different because of the way the Node.js package processes the command-line arguments. It also requires a number of modules to be deployed before it can be run. 

To deploy the dependent module and the Node.js package run: 

```
$ npm commander -g
$ npm install line-by-line -g
$ npm install -g
```

You can run grepelb on your log files with:

```
$ grepelb -t 5 *.log | tee warden-28th
```

You can pass the following options to grepelb: 

```
-e1, --e1                         Compare time of elb internal processing time (sec). Defaults if none specified.
-e2, --e2                         Compare time of backend processing time (sec). Defaults if none specified.
-e3, --e3                         Compare time of response processing time (sec). Defaults if none specified.
-t, --threshold n                n in seconds of time threshold to compare against. Default is 1 sec.
-s, --short                      Display time and 3 response times only in results. Default.
-v, --verbose                    Display whole log statement in results.
```