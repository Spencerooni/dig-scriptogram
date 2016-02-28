#!/usr/local/bin/lua
--
-- Parses ELB log files to find slow responses for ELB int processing time, backend processing time or upstream processing time.
-- 
-- Download ELB logs from S3 bucket:
-- aws s3 sync s3://pub-ext-elb/AWSLogs/719728721003/elasticloadbalancing/eu-west-1/2015/08/28 .
-- 2015-08-28T08:08:11.042771Z publishing-external-elb-https 00.000.000.000:80 11.111.111.111:80 0.000023 1.069548 0.00003 200 200 0 3372 "GET https://mot-testing.i-env.net:443/ HTTP/1.1" "Mozilla/5.0 (Linux; Android 4.4.2; V919 3G Air Core8 Build/KOT49H) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/44.0.2403.133 Safari/537.36" ECDHE-RSA-AES128-GCM-SHA256 TLSv1.2
--
-- PC 30/01/16 lua version
--

require "lapp/lapp"
version = "0.3"
--scriptname = args[0]
alltheargs = args
opt_debug = nil

--
-- Split a string
-- credit: http://lua-users.org/wiki/SplitJoin
--
function string:split (separator)
    local separator, fields = separator or ",", {}
    local pattern = string.format("([^%s]+)", separator)
    self:gsub(pattern, function(c) fields[#fields+1] = c end)
    return fields
end

function string:split2 (separator)
    local tokens = {}
    local pattern = string.format("([^%s]+)", separator)
    local i = 1
    for token in self:gmatch(pattern) do
       tokens[i] = token
       i = i + 1
    end
    return tokens
end

--
--   Read an ELB logfile line-by-line for efficiency and parse for slow response times. 
--
function parseElblogfile (fh, filename)
    --local fh = assert(io.open(filename, "r"), "unable to open file " .. filename)
    print ("=========" .. filename .. "=========")
    while true do
        local line = fh:read()
        if line == nil then break end
        parseLine(line)
    end
    fh:close()
end

--
--   Parse an ELB logfile line to identify which of the 3 responses times are slower than the threshold. 
--
function parseLine (line)
    local time1, time2, time3 = "-", "-", "-"
    local items = line:split2(' ')
    local date, elb, clientip, referrer, request_processing_time, backend_processing_time, response_processing_time, elbstatus, 
        backendstatus, rbytes, sbytes, verb, url = items[1], items[2], items[3], items[4], items[5], items[6], items[7], 
        items[8], items[9], items[10], items[11], items[12], items[13]
    if argv.e1 and tonumber(request_processing_time) > argv.threshold then time1 = request_processing_time end
    if argv.e2 and tonumber(backend_processing_time) > argv.threshold then time2 = backend_processing_time end
    if argv.e3 and tonumber(response_processing_time) > argv.threshold then time3 = response_processing_time end
    if (time1 ~= "-") or (time2 ~= "-") or (time3 ~= "-") then
        if argv.verbose then print(line) end
        if argv.short then print(date.." "..time1.." "..time2.." "..time3.." "..url.." ("..backendstatus..")") end
    end
end

argv = lapp [[
scriptname: alltheargs (version)
scriptname logfiles
    -u,--e1                     Compare time of elb internal processing time (sec). Defaults if none specified. 
    -e,--e2                     Compare time of backend processing time (sec). Defaults if none specified. 
    -d,--e3                     Compare time of response processing time (sec). Defaults if none specified. 
    -t,--threshold (default 1)  n in seconds of time threshold to compare against. Default is 1 sec. 
    -s,--short (default true)   Display time and 3 responses times only in results. Default. 
    -v,--verbose                Display whole log statement in results.
    <files...> (file-in)        Log files

    To easily download elb logs from S3 bucket use this with your bucket name:

    $ aws s3 sync s3://pub-ext-elb/AWSLogs/719728721003/elasticloadbalancing/eu-west-1/2015/08/28 .
]]

argv.short = not argv.verbose
argv.verbose = not argv.short
if argv.e1 == nil then argv.e1 = false end
if argv.e2 == nil then argv.e2 = false end
if argv.e3 == nil then argv.e3 = false end
if not argv.e1 and not argv.e2 and not argv.e3 then argv.e1, argv.e2, argv.e3 = true, true, true end

if opt_debug then
    print("Processing files:")
    for i = 1,#argv.files do
        print (argv.files[i])
    end
end

for i = 1,#argv.files do
    parseElblogfile(argv.files[i], argv.files_name[i])
end

