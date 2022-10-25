#!/usr/bin/env perl

# converts vim documentation to simple html
# Sirtaj Singh Kang (taj@kde.org)

# Sun Feb 24 14:49:17 CET 2002

# Updated by Willis (yianwillis@users.sourceforge.net)
# Sat Mar 24 12:11:02 EST 2006

use strict;
use utf8;
use Text::Tabs; # Willis: expand replaced by myexpand. So no longer necessary.
use Encode;
use vars qw/%url $date/;
use Getopt::Long qw(GetOptions);

my %url = ();
my %filedesc = ();
my $date = Encode::decode_utf8(`date -u`);
chop $date;

my $banner_file;
my $conceal=1;
my $global_tag='';
my $global_url='';
my $canonical_prefix='';
my $help_file='';

sub maplink
{
	my $tag = shift;
	if( exists $url{ $tag } ){
		return $url{ $tag };
	} else {
		#warn "Unknown hyperlink target: $tag\n";
		$tag =~ s/</&lt;/g;
		$tag =~ s/>/&gt;/g;
		return "<code class=\"badlink\">$tag</code>";
	}
}

sub mapcategory
{
	my $tag = shift;
	if ($tag =~ /^usr_/) {
		return "中文用户手册";
	} else {
		return "中文帮助";
	}
}

sub mapdesc
{
	my $tag = shift;
	if( exists $filedesc{ $tag } ){
		return $filedesc{ $tag };
	} elsif ($tag eq "vim_faq") {
		return "常见问题解答";
  } else {
		return $tag;
	}
}

sub readTagFile
{
	my($tagfile) = @_;
	my( $tag, $file );

	open(TAGS,"$tagfile") || die "can't read $tagfile\n";

	while( <TAGS> ) {
		next unless /^(\S+)\s+(\S+)\s+/;

		$tag = $1;
		my $label = $tag;
		($file= $2) =~ s/.\w+$/.html/g;

		$url{ $tag } = "<a href=\"$file#".escurl($tag)."\">".esctext($label)."</a>";
	}
	$url{ "help-tags" } = "<a href=\"tags.html"."\">".esctext("help-tags")."</a>";
	close( TAGS );
}

sub readExternalTagFile
{
	my($tagfile, $tagurl) = @_;
	my( $tag, $file );

	open(TAGS,"$tagfile") || die "can't read $tagfile\n";

	while( <TAGS> ) {
		next unless /^(\S+)\s+(\S+)\s+/;

		$tag = $1;
		my $label = $tag;
		($file= $2) =~ s/.\w+$/.html/g;

		$url{ $tag } = "<a href=\"$tagurl/$file#".escurl($tag)."\">".esctext($label)."</a>";
	}
	close( TAGS );
}

sub readHelpFile
{
	my($helpfile) = @_;
	my( $tag, $file );

	open(HELP,"<:utf8","$helpfile") || die "can't read $helpfile\n";

	while( <HELP> ) {
		next unless /^\|(\w+)(?:\.txt)?\|\s+(.+)/;
		$filedesc{ $1 } = $2;
	}
	$filedesc{ "help" } =~ s/ \(本文件\)//;
	close( HELP );
}

sub esctext
{
	my $text = shift;
	$text =~ s/&/&amp;/g;
	$text =~ s/</&lt;/g;
	$text =~ s/>/&gt;/g;
	return $text;
}

sub escurl
{
	my $url = shift;
	$url =~ s/"/%22/g;
	$url =~ s/~/%7E/g;
	$url =~ s/</%3C/g;
	$url =~ s/>/%3E/g;
	$url =~ s/=/%20/g;
	$url =~ s/#/%23/g;
	$url =~ s/\//%2F/g;

	return $url;
}

# expand() count bytes when computing tabstops. But each utf-8 character may
# take up to 3 bytes, we all know CJK characters use double width only.
$tabstop = 8;

sub mylength
{
	my ($str) = @_;
	my $length = length($str);
	my $i = 0;
	my @chars = unpack("U*", $str);
	foreach $i (@chars) {
		$length++ if $i > 255;
	}
	return $length;
}

# expand tabs.
sub myexpand
{
	my (@l) = @_;
	for $_ (@l) {
		1 while s/(^|\n)([^\t\n]*)(\t+)/
						$1. $2 . (" " x
								($tabstop * length($3)
									- (mylength($2) % $tabstop)))
						/sex;
	}
	return @l if wantarray;
	return $l[0];
}

sub vim2html
{
	my( $infile ) = @_;
	my( $outfile );

	open(IN, "<:utf8", "$infile" ) || die "Couldn't read from $infile: $!.\n";

	($outfile = $infile) =~ s:.*/::g;

	my $tagfile =  ($outfile =~ /^tags(-..)?$/);
	if ($tagfile) {
		$outfile = "tags";
	} else {
		$outfile =~ s/\.\w+$//g;
	}

	open( OUT, ">:utf8", "$outfile.html" )
			|| die "Couldn't write to $outfile.html: $!.\n";
	binmode STDOUT, ":utf8";
	my $category = mapcategory ($outfile );
	my $desc = mapdesc( $outfile );

	my $filler = ' ' x 80;
	my $banner = '';
	if ($banner_file) {
		$banner = do {
			local $/ = undef;
			open my $fh, "<:encoding(UTF-8)", $banner_file
					or die "could not open $banner_file: $!";
			<$fh>;
		};
	}

	my $canonical = '';
	if ($canonical_prefix) {
		$canonical =
		qq(<link rel="canonical" href="$canonical_prefix/$outfile.html" />);
	}

	print OUT<<EOF;
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8" />
<!--[if lt IE 9]>
  <script src="https://oss.maxcdn.com/libs/html5shiv/3.7.0/html5shiv.js"></script>
<![endif]-->
<title>VIM $category: $desc</title>
<link rel="stylesheet" href="vim-stylesheet.css" type="text/css" />
$canonical
<script type="text/javascript" src="vimcdoc.js"></script>
<meta name="viewport" content="width=device-width, initial-scale=1" />
</head>
<body>
$banner
<header>
<h2>$outfile</h2>
</header>
<article id=outer>
<section class=inner>
EOF

	my $inexample = 0;
	my $inheader = 0;
	if ($tagfile) {
		print OUT "<table>\n";
	}
	while( <IN> ) {
		chop;
		if ($tagfile) {
			print OUT "<tr>";
			my @fields = split(/\t/);
			if ($fields[0] eq "!_TAG_FILE_ENCODING") {
				print OUT "<td>" .  $fields[0] .  "</td><td>" .  $fields[1];
				print OUT "</td><td>" .  $fields[2] .  "</td></tr>\n";
			}
			else {
				$fields[1] =~ s/\.\w+/\.txt/;
				print OUT "<td>" .  maplink($fields[0]) .  "</td><td>";
				print OUT maplink($fields[1]) . "</td><td>". esctext($fields[2]);
				print OUT "</td></tr>\n";
			}
			next;
		}

		$_ = myexpand($_);
		if ( /^=+\s*$/ ) {
			print OUT "</section><hr class=\"doubleline\" /><section class=inner>\n";
			$inheader = 1;
			$inexample = 0;
			next;
		}
		elsif ( /^\s*-+\s*$/ ) {
			print OUT "</section><hr class=\"singleline\" /><section class=inner>\n";
			$inexample = 0;
			next;
		}

		# examples
		elsif( /^>$/ || /\s>$/ ) {
			if ( $inexample && /^(<)/ ) {
				$_ = $';
				$_ = " " . $_ if /^\s/;
			}
			$inexample = 1;
			chop;
		}
		elsif ( $inexample && /^([<\S])/ ) {
			$inexample = 0;
			$_ = $' if $1 eq "<";
			$_ = " " . $_ if /^\s/;
		}

		if( $inexample == 2 ) {
			print OUT "<code class=\"example\">" . esctext($_) . "</code>\n";
			$inheader = 0;
			next;
		}

		# Various vim highlights. note that < and > have already been escaped
		# so that HTML doesn't get screwed up.

		my @out = ();
		#		print "Text: $_\n";
		LOOP:
		# split on |token| or *token*
		foreach my $token ( split /((?:\|[^*"|[:space:]]+\|)|(?:\*[^*"|[:space:]]+\*(?=[[:space:]]|$)))/ ) {
			if ( $token =~ /^\|([^*"|[:space:]]+)\|/ ) {
				# link
				if ( $conceal ) {
					push( @out, " ".maplink( $1 )." " );
				} else {
					push( @out, "|".maplink( $1 )."|" );
				}
				next LOOP;
			}
			elsif ( $token =~ /^\*([^*"|[:space:]]+)\*/ ) {
				# target
				if ( $conceal ) {
					push( @out,
									"<b class=\"vimtag\"> <a name=\"".escurl($1)."\">".esctext($1)."<\/a> <\/b>");
				} else {
					push( @out,
									"<b class=\"vimtag\">\*<a name=\"".escurl($1)."\">".esctext($1)."<\/a>\*<\/b>");
				}
				next LOOP;
			}

			$_ = esctext($token);
			# keystroke; skip CTRL-{xyz} and CTRL-<xyz>, note that
			# < has been escaped so &lt; is actually seen here.
			s/CTRL-(\w+|[^{&])/<code class="keystroke">CTRL-$1<\/code>/g;

			# URL. Must be done before maplink.
			s/https?:\/\/[^' 	<>"]+[a-zA-Z0-9\/]/<a href="$&">$&<\/a>/g;

			# parameter '...'
			s/'([a-z]{2,}|t_..)'/maplink($&)/ge;

			# parameter `...`
			if ( $conceal ) {
				s/`([^` \t]+)`/" ".maplink($1)." "/ge;
			} else {
				s/`([^` \t]+)`/"`".maplink($1)."`"/ge;
			}

			# parameter <...>
			s/&lt;([a-zA-Z0-9_-]*)&gt;/<code class="special">&lt;$1&gt;<\/code>/g;

			# parameter [...]
			s/\[(range|line|count|offset|cmd|[-+]?num|\+cmd|\+\+opt|arg|arguments|ident|addr|group)\]/<code class="special">\[$1\]<\/code>/g;
			s/\s\K\[(\w+)\]/<code class="special">\[$1\]<\/code>/g;

			# note
			s/(Note[:\s])/<code class="note">$1<\/code>/gi;
			s/(注意|备注|警告)( (?=[^[:print:][:space:]]))?/<code class="note">$1<\/code>/g;

			# parameter {...}
			s/\{([^ {}'"|]*)\}/<code class="special">{$1}<\/code>/g;

			# emphasis
			s/_(\P{ASCII}+)_/ <code class="emphasis">$1<\/code> /g;

			# title
			s/VIM (?:参考手册|用户手册).*|译者[注]?/<code class="vim">$&<\/code>/g;

			# local heading
			s/^(.*)\~$/<code class="section">$1<\/code>/g;

			push( @out, $_ );
		}

		$_ = join( "", @out );

		# compatibility notes: {Vi: }.
		s/\{((?:Vi[ :]|仅)[^}]*)\}/<code class="notvi">{$1}<\/code>/g;

		if ($inheader == 1) {
			print OUT "<h4>$_</h4>";
		} else {
			print OUT $_,"\n";
		}

		$inexample = 2 if $inexample == 1;
		$inheader = 0;
	}
	if ($tagfile) {
		print OUT "</table>\n";
	}
	print OUT<<EOF;
</section>
</article>
<footer>
Generated by vim2html
</footer>
</body>
</html>
EOF
	close ( IN );
	close ( OUT );
}

sub usage
{
die<<EOF;
vim2html.pl: converts vim documentation to HTML.
usage:

	vim2html.pl [options] <tag file> <text files>
  Options:
	--banner: optional. banner HTML file.
	--conceal: optional. Conceal certain notations. Default is true.
	--global_url, --global_tag: optional. URL and tags file referring to the
	                            tags and general VIM help html page.
  --help_file: optional. the general VIM help file, used to extract file desc.
	--canonical_prefix: optional. canonical site prefix.
EOF
}



# main
#usage() if $#ARGV < 2;
usage() if !defined $ARGV[1];

GetOptions(
    'banner=s' => \$banner_file,
    'conceal!' => \$conceal,
    'global_tag=s' => \$global_tag,
    'global_url=s' => \$global_url,
    'canonical_prefix=s' => \$canonical_prefix,
    'help_file=s' => \$help_file,
) or usage();

print "Processing tags...\n";
readTagFile( $ARGV[ 0 ] );
if ($global_tag ne "" && $global_url ne "") {
  print "Processing external tags...\n";
	readExternalTagFile($global_tag, $global_url);
}
if ($help_file ne "") {
  print "Processing help_file...\n";
	readHelpFile($help_file);
}

vim2html( $ARGV[ 0 ] );
foreach my $file ( 1..$#ARGV ) {
	print "Processing ".$ARGV[ $file ]."...\n";
	vim2html( $ARGV[ $file ] );
}
print "done.\n"

# vi:ts=2:
