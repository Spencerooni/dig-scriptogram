use v6;
#
# Parses ELB log files to find slow responses for ELB int processing time, backend processing time or upstream processing time.
# 
# Download ELB logs from S3 bucket:
# aws s3 sync s3://pub-ext-elb/AWSLogs/719728721003/elasticloadbalancing/eu-west-1/2015/08/28 .
# 2015-08-28T08:08:11.042771Z publishing-external-elb-https 93.15.210.26:26023 11.240.54.67:80 0.000023 1.069548 0.00003 200 200 0 3372 "GET https://mot-testing.i-env.net:443/ HTTP/1.1" "Mozilla/5.0 (Linux; Android 4.4.2; V919 3G Air Core8 Build/KOT49H) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/44.0.2403.133 Safari/537.36" ECDHE-RSA-AES128-GCM-SHA256 TLSv1.2
#
# PC 12/10/15 perl 6 version
#
my $version = <0.3>;

sub MAIN (
	Str $file,
	Bool :$verbose = False, 
	Int :$threshold = 1, 
	Bool :$e1 = False, 
	Bool :$e2 = False, 
	Bool :$e3 = False, 
	Bool :$debug = False, 
	Bool :$help = False, 
	*@files)
{
	my @t = $e1, $e2, $e3;
	my @time;
	@files.push: $file;
	USAGE if $help;
	@t = True, True, True if $e1 + $e2 + $e3 < 1;

	if ($debug)
	{
		say "Processing files:";
		for @files { say "$_"; }
	}

	for @files -> $filename
	{
		my $fh = open "$filename", :r or die "unable to open file $filename";
		say "=========$filename=========";
		# v slow in perl 6: for $fh.lines -> $line
		while (defined my $line = $fh.get)
		{
			my @time = "-", "-", "-";
			my ($date, $elb, $clientip, $referrer, $request_processing_time, $backend_processing_time, $response_processing_time, $elbstatus, $backendstatus, $rbytes, $sbytes, $verb, $url, @_) = $line.words;
			@time[0] = $request_processing_time if @t[0] and $request_processing_time > $threshold;
			@time[1] = $backend_processing_time if @t[1] and $backend_processing_time > $threshold;
			@time[2] = $response_processing_time if @t[2] and $response_processing_time > $threshold;
			unless '-' eq all (@time)
			{
				say "$line" if $verbose;
				say "$date @time[0] @time[1] @time[2] $url ($backendstatus)" unless $verbose;
			}
		}
		close $fh;
	}
}

sub USAGE (Str $message = "")
{
    print qq:to/EOF/;
$*PROGRAM-NAME: $message ($version)
$*PROGRAM-NAME logfiles
   	--e1             Compare time of elb internal processing time (sec). Defaults if none specified. 
   	--e2             Compare time of backend processing time (sec). Defaults if none specified. 
   	--e3             Compare time of response processing time (sec). Defaults if none specified. 
   	--threshold=n    n in seconds of time threshold to compare against. Default is 1 sec. 
	--verbose        Display whole log statement in results. Default is time and 3 responses times only in results.

	To easily download elb logs from S3 bucket use this with your bucket name:

	\$ aws s3 sync s3://pub-ext-elb/AWSLogs/719728721003/elasticloadbalancing/eu-west-1/2015/08/28 .
EOF
}