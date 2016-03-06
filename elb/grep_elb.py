    # modified version
from glob import glob
import argparse

parser = argparse.ArgumentParser(description='Process some logs.')
parser.add_argument('path', type=str, help='path to log files')
parser.add_argument('-t', required=True, type=float, help='threshold value')
parser.add_argument('-req', action='store_true', help='evaluate req time (default)')
parser.add_argument('-back', action='store_true', help='evaluate backend proc time (default)')
parser.add_argument('-res', action='store_true', help='evaluate rep time (default)')
parser.add_argument('-v', action='store_true', help='show full log lines instead of timestamp and 3 timings')

args = parser.parse_args()
t_section = []
timers = args.req + args.back + args.res
files = glob(args.path)

for log_file in files:
    with open(log_file, 'r') as f:
        print "=========" + log_file + "========="
        lines = f.readlines()
        for line in lines:
            if timers < 1:
                t_section = line.split()[4:7]
                e = any(i >= args.t for i in map(float, t_section))
                if e:
                    if args.v:
                        print line
                    else:
                        print line[:27] + ' ' + ' '.join(t_section)
            else:
                if args.req:
                    t_section.append(line.split()[4])
                if args.back:
                    t_section.append(line.split()[5])
                if args.res:
                    t_section.append(line.split()[6])
                e = any(i >= args.t for i in map(float, t_section))
                if e:
                    if args.v:
                        print line
                    else:
                        print line[:27] + ' '.join(t_section)
                t_section = []
