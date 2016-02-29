#!/usr/bin/perl
#
# Parses ELB log files to find slow responses for ELB int processing time, backend processing time or upstream processing time.
# 
# Download ELB logs from S3 bucket:
# aws s3 sync s3://pub-ext-elb/AWSLogs/000000000000/elasticloadbalancing/eu-west-1/2015/08/28 .
# 2015-08-28T08:08:11.042771Z publishing-external-elb-https 00.000.000.000:80 11.111.111.111:80 0.000023 1.069548 0.00003 200 200 0 3372 "GET https://mot-testing.i-env.net:443/ HTTP/1.1" "Mozilla/5.0 (Linux; Android 4.4.2; V919 3G Air Core8 Build/KOT49H) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/44.0.2403.133 Safari/537.36" ECDHE-RSA-AES128-GCM-SHA256 TLSv1.2
#
# PC 29/08/15
#
use Getopt::Long;

$version = q(0.2);
$opt_debug = 0;

sub usage
{
    my $usage = <<EOF;
$0: @_ ($version)
$0 logfiles
   	-1				Compare time of elb internal processing time (sec). Defaults if none specified. 
   	-2 				Compare time of backend processing time (sec). Defaults if none specified. 
   	-3 				Compare time of response processing time (sec). Defaults if none specified. 
   	-threshold n    n in seconds of time threshold to compare against. Default is 1 sec. 
	-short 			Display time and 3 responses times only in results. Default. 
	-verbose 		Display whole log statement in results.

	To easily download elb logs from S3 bucket use this with your bucket name:

	$ aws s3 sync s3://pub-ext-elb/AWSLogs/000000000000/elasticloadbalancing/eu-west-1/2015/08/28 .
EOF
}

{
	&GetOptions(
		'short', 
		'verbose',	
		'threshold=s',
		'1',
		'2',
		'3',
	    'debug', 
	    'help') or &usage;

	$opt_help and &usage;
	$opt_short = true unless $opt_verbose;
	$opt_threshold = 1.0 unless $opt_threshold;
	($opt_1, $opt_2, $opt_3) = (1,1,1) if $opt_1 + $opt_2 + $opt_3 < 1;
	my @files = @ARGV;
	usage "no logfile specified" unless $ARGV[0];

	if ($opt_debug)
	{
		print "Processing files:\n";
		foreach my $f (@ARGV) { print "$f\n"; }
	}

	while (my $filename = shift @files)
	{
		open FILE, "$filename" or die "unable to open file $filename";
		print "=========$filename=========\n";
		while (my $line = <FILE>)
		{
			chomp $line;
			my ($time1, $time2, $time3) = ("-", "-", "-");
			($date, $elb, $clientip, $referrer, $request_processing_time, $backend_processing_time, $response_processing_time, $elbstatus, $backendstatus, $rbytes, $sbytes, $verb, $url, @_) = split ' ', $line;
			$time1 = $request_processing_time if ($opt_1 and $request_processing_time > $opt_threshold);
			$time2 = $backend_processing_time if ($opt_2 and $backend_processing_time > $opt_threshold);
			$time3 = $response_processing_time if ($opt_3 and $response_processing_time > $opt_threshold);
			unless ($time1 == "-" and $time2 == "-" and $time3 == "-")
			{
				print "$line\n" if $opt_verbose;
				print "$date $time1 $time2 $time3 $url ($backendstatus)\n" if $opt_short;
			}
		}
		close FILE;
	}
}