#grzeski Python version 12/03/2016
#command to run it -> time python grep_elb_a.py -t 3  'testdata/*.log'
# or time python grep_elb_a.py  -req -res -back -t 0.000057  'testdata/*.log'
from glob import glob
import argparse


def parse_logs():
    args = get_arg_parser().parse_args()
    t_section = []
    timers = args.req + args.back + args.res
    files = glob(args.path) 
    header = "=========%s========="

    for log_file in files:
        with open(log_file, 'r') as f:
            print header % log_file

            for line in f:
                line_contents = line.split()
                if timers < 1:
                    t_section = line_contents[4:7]
                else:
                    pack = zip([args.req, args.back, args.res], line_contents[4:7])
                    t_section.extend([p[1] for p in filter(lambda x: x[0], pack)])
                if filter(lambda x: float(x) >= args.t, t_section):
                    print (line[:27] + ' ' + ' '.join(t_section), line)[bool(args.v)]
                t_section = []


def get_arg_parser():
    parser = argparse.ArgumentParser(description='Process some logs.')
    parser.add_argument('path', type=str, help='path to log files')
    parser.add_argument('-t', required=True, type=float, help='threshold value')
    parser.add_argument('-req', action='store_true', help='evaluate req time (default)')
    parser.add_argument('-back', action='store_true', help='evaluate backend proc time (default)')
    parser.add_argument('-res', action='store_true', help='evaluate rep time (default)')
    parser.add_argument('-v', action='store_true', help='show full log lines instead of timestamp and 3 timings')
    
    return parser
    
parse_logs()
