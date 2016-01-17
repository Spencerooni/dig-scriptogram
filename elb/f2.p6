use v6;

sub MAIN ($file)
{
	my $fh = open $file, :r or die "unable to open file $file";
	while (defined my $line = $fh.get)
	{
		say $line;
	}
	close $fh;
}