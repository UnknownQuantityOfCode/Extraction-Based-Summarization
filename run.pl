use v5.10;
use Summary::Extract;

my $e = Summary::Extract->new();

my $text = shift || "Peter and Elizabeth took a taxi to attend the night party in the city. While in the party, Elizabeth collapsed and was rushed to the hospital. Since she was diagnosed with a brain injury, the doctor told Peter to stay besides her until she gets well. Therefore, Peter stayed with her at the hospital for 3 days without leaving.";

my $lines = $e->summarise($text);
say "Highest Ranked:\n".$lines->{lines}->[0]->[0];