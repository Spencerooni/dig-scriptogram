die "specify filename" unless $ARGV[0];
open FILE, "$ARGV[0]" or die "unable to read file $ARGV[0]";
while (<FILE>)
{
    print "$_";
}
close FILE;