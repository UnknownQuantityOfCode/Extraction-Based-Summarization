use strict;
use warnings;

use v5.10;
use IO::All;
use HTML::Strip;
use Data::Dumper;
use Summary::Extract;
use LWP::UserAgent ();
use Math::Round qw(nhimult);
use JSON::XS;

my $ua = LWP::UserAgent->new;
my $hs = HTML::Strip->new();
my $e = Summary::Extract->new();

my $subreddit = shift || 'jokes';

my @stories = get_posts($subreddit);
foreach my $s (@stories){
	say '_'x80;
	say $s->{title} . ('-' x (nhimult(80, length($s->{title})) - length($s->{title})));
	say $s->{summary}->[0]->[0] if $s->{summary}->[0]->[0];
	say '_'x80 if $s->{summary}->[0]->[0];
}

sub get_posts {
	my $subreddit = shift;
	my $response = $ua->get('https://www.reddit.com/r/'.$subreddit.'/hot.json?limit=5');
	my @stories;
	if ($response->is_success) {
	    my $json = $response->decoded_content;
	    my $ref = decode_json($json);
		foreach my $s (@{$ref->{data}->{children}}){
			$s = $s->{data};
			my $title = $s->{title};
			$title =~ s/[^[:ascii:]]//igm;
			push @stories, {
				title => $title,
				link => $s->{url},
				summary => get_summary($s->{selftext_html}) || [[undef]]
			};
		}
	} else {
	    die "Cannot connect to $subreddit";
	}
	return @stories;
}

sub get_summary {
	my $content = shift || return;
    my $clean_text = $hs->parse( $content );
	$clean_text = $hs->parse($clean_text);
    $hs->eof;
    $clean_text =~ s/[^[:ascii:]]//igm;
    my $lines = $e->summarise($clean_text);
    return $lines->{lines};
}