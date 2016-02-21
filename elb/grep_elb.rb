#!/usr/local/bin/ruby
=begin

ParsesELB log files to find slow responses for ELB int processing time, backend processing time or upstream processing time.

Download ELB logs from S3 bucket:
aws s3 sync s3://pub-ext-elb/AWSLogs/719728721003/elasticloadbalancing/eu-west-1/2015/08/28 .
2015-08-28T08:08:11.042771Z publishing-external-elb-https 23.14.115.16:22023 19.250.23.69:80 0.000023 1.069548 0.00003 200 200 0 3372 "GET https://mot-testing.i-env.net:443/ HTTP/1.1" "Mozilla/5.0 (Linux; Android 4.4.2; V919 3G Air Core8 Build/KOT49H) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/44.0.2403.133 Safari/537.36" ECDHE-RSA-AES128-GCM-SHA256 TLSv1.2

PC 15/01/16 ruby version

=end
require 'optparse'
require 'ostruct'

$version = "0.3";
$opt_debug = 0;

# process command-line arguments
class CommandLineOpts
	def initialize (args)
		@args = args
		@opts = OpenStruct.new
		@opts.verbose = false
		@opts.debug = false
		@opts.threshold = 1.0
		@opts.timer = [false, false, false]

		self.parse
		@opts.timer = [true, true, true] if (@opts.timer[0] == false and @opts.timer[1] == false and @opts.timer[2] == false)
	end

	def files=(files)
		@files = files
	end

	def files
		@files
	end

	def opts
		@opts
	end

	def parse
		opt_parser = OptionParser.new do |opts|
			opts.banner = opts.program_name + " logfiles"
			opts.separator ""

			opts.on("-1", "--1", "Compare time of elb internal processing time (sec). Defaults if none specified.") { @opts.timer[0] = true }
			opts.on("-2", "--2", "Compare time of backend processing time (sec). Defaults if none specified.") { @opts.timer[1] = true }
			opts.on("-3", "--3", "Compare time of response processing time (sec). Defaults if none specified.") { @opts.timer[2] = true }
			opts.on("-t", "--threshold n", "n in seconds of time threshold to compare against. Default is 1 sec.") { |n| @opts.threshold = n.to_f }

			opts.on("-d", "--debug", "Display debug information.") { @opts.debug = true }
			opts.on("-v", "--verbose", "Display whole log statement in results.") { @opts.verbose = false }

			opts.separator "To easily download elb logs from S3 bucket use this with your bucket name:"
			opts.separator ""
			opts.separator "$ aws s3 sync s3://pub-ext-elb/AWSLogs/719728721003/elasticloadbalancing/eu-west-1/2015/08/28 ."

			opts.on_tail("-h", "--help", "Show this message") do 
				puts opts
				exit 
			end	

		end.parse!
	end
end

# parse an AWS ELB logfile to identify response times slower than the threshold
class Elblogfile

	def initialize (filename)
		@filename = filename;
	end

	# parse each logfile line to identify slower response times (1 = request, 2 = backend or 3 = response time) based on threshold
	def parse (timer1, timer2, timer3, threshold, verbose)
		IO.foreach(@filename) do |line| 
			time1, time2, time3 = "-", "-", "-"
			date, elb, clientip, referrer, request_processing_time, backend_processing_time, response_processing_time, elbstatus, backendstatus, rbytes, sbytes, verb, url, remaining = line.split(' ')
			time1 = request_processing_time if (timer1 and request_processing_time.to_f > threshold)
			time2 = backend_processing_time if (timer2 and backend_processing_time.to_f > threshold)
			time3 = response_processing_time if (timer2 and response_processing_time.to_f > threshold)
			unless (time1 == "-" and time2 == "-" and time3 == "-")
				puts line if verbose
				puts "#{date} #{time1} #{time2} #{time3} #{url} (#{backendstatus})" unless verbose;
			end
			
		end
	rescue IOError, Errno
		puts "unable to read file " + @filename
	rescue => e
		puts "unable to parse file " + @filename
		puts e.message
	end
end

# Process command line args
$cli = CommandLineOpts.new (ARGV)
$cli.files = ARGV
if $cli.opts.debug 
	puts "Processing files:"
	$cli.files.each { |f| puts f }
end

# Parse each supplied logfile for slow response times
$cli.files.each do |logfile|
	puts "=========" + logfile + "=========\n";
	f = Elblogfile.new(logfile)
	f.parse $cli.opts.timer[0], $cli.opts.timer[1], $cli.opts.timer[2], $cli.opts.threshold, $cli.opts.verbose
end
