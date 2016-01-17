die "specify filename" unless $ARGV[0];
while (<>)
{
    print "$_";
}