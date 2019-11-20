# Based on work seen here: https://blog.floydhub.com/gentle-introduction-to-text-summarization-in-machine-learning/
package Summary::Extract;

use v5.10;
use strict;
use warnings;

use Lingua::Stem qw(stem stem_in_place);

# INIT
	sub new {
		my $class = shift;
		my %data = @_;
		# DEFAULTS
		my $self = {
			stop_words => ['[0-9]', "a", "about", "above", "after", "again", "against", "all", "am", "an", "and", "any", "are", "as", "at", "be", "because", "been", "before", "being", "below", "between", "both", "but", "by", "could", "did", "do", "does", "doing", "down", "during", "each", "few", "for", "from", "further", "had", "has", "have", "having", "he", "he'd", "he'll", "he's", "her", "here", "here's", "hers", "herself", "him", "himself", "his", "how", "how's", "I", "I'd", "I'll", "I'm", "I've", "if", "in", "into", "is", "it", "it's", "its", "itself", "let's", "me", "more", "most", "my", "myself", "nor", "of", "on", "once", "only", "or", "other", "ought", "our", "ours", "ourselves", "out", "over", "own", "same", "she", "she'd", "she'll", "she's", "should", "since", "so", "some", "such", "than", "that", "that's", "the", "their", "theirs", "them", "themselves", "then", "there", "therefore", "there's", "these", "they", "they'd", "they'll", "they're", "they've", "this", "those", "through", "to", "too", "under", "until", "up", "very", "was", "we", "we'd", "we'll", "we're", "we've", "were", "what", "what's", "when", "when's", "where", "where's", "which", "while", "who", "who's", "whom", "why", "why's", "with", "would", "you", "you'd", "you'll", "you're", "you've", "your", "yours", "yourself", "yourselves"]
		};
		# OVERRIDES
		foreach my $key (keys %data){
			if($key eq 'stop_words_add'){
				if(ref $data{$key} eq 'ARRAY'){
					push @{$self->{stop_words}}, $_ foreach @{$data{$key}};
				}else{
					warn "stop_words_add not an array refernce";
				}
			}else{
				$self->{$key} = $data{$key};
			}
		}
		# DATA
		$self->{stop_words_regex} = '(\b|\.|^)('.join('|', @{$self->{stop_words}}).')(\b|\.|$)';
		
		bless( $self, $class );    
		return $self;        
	}

	sub summarise {
		my $self = shift;
		my $text = shift;
		my @text_lines = split ('\.\s?', $text);
		my @data;
		foreach my $line (@text_lines){
			chomp $line;
			$line = $self->clean_line($line);
			push @data, $line;
		}
		my @tokens = $self->tokenization(@data);
		my $weights = $self->weigh(@tokens);
		@text_lines = split ('\.\s?', $text);
		my ($average_weight, $total_weight, $weighted_lines);
		foreach my $line (@text_lines){
			chomp $line;
			$weighted_lines->{$line} = score($line, $weights);
			$total_weight += $weighted_lines->{$line};
		}
		$average_weight = ($total_weight / (scalar @text_lines));
		return {
			lines => [map {[$_, $weighted_lines->{$_}, (($weighted_lines->{$_} > $average_weight) ? 1 : 0)]} (sort {$weighted_lines->{$b} <=> $weighted_lines->{$a}} keys %{$weighted_lines})],
			average => $average_weight
		}
	}

	sub clean_line {
		my $self = shift;
		my $text_line = shift;
		$text_line = $self->remove_stop_words($text_line);
		$text_line = $self->remove_punctuation($text_line);
		$text_line = $self->clear_spaces($text_line);
		return $text_line;
	}

	sub remove_stop_words {
		my $self = shift;
		my $text_line = shift;
		$text_line =~ s/$self->{stop_words_regex}//igm;
		return $text_line;
	}

	sub remove_punctuation {
		my $self = shift;
		my $text_line = shift;
		$text_line =~ s/[,\.\/\\!@#$%^&*\(\)\[\]]//igm;
		return $text_line;
	}

	sub clear_spaces {
		my $self = shift;
		my $text_line = shift;
		$text_line =~ s/\s{1,}/ /igm;
		$text_line =~ s/^\s|\s$//igm;
		return $text_line;
	}

	sub tokenization {
		my $self = shift;
		my @lines = @_;
		my @tokens;
		foreach my $l (@lines){
			my @words = split('\b', $l);
			stem_in_place(@words);
			foreach my $w (@words){
				push @tokens, lc($w) if $w;
			}
		}
		return @tokens;
	}

	sub weigh {
		my $self = shift;
		my @tokens = @_;
		my $words;
		foreach my $t (@tokens){
			$words->{$t}->{occurence}++;
		}
		my $max;
		$max = max(($max || 0), $words->{$_}->{occurence}) foreach keys %{$words};
		foreach my $w (keys %{$words}){
			$words->{$w}->{weight} = $words->{$w}->{occurence} / $max;
		}
		return $words;
	}

	sub score {
		my ($line, $weights) = @_;
		my $score = 0;
		my @words = split('\b', $line);
		stem_in_place(@words);
		foreach my $w (@words){
			$score += ($weights->{lc($w)}->{weight} || 0);
		}
		return $score;
	}

	sub max {
		my ($x, $y) = @_;
		return ($x, $y)[$x < $y];
	}

1;
