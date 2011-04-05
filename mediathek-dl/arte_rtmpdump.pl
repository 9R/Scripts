#!/usr/local/bin/perl -s

# arte_rtmpdump.pl
# - Simple script do simplify arte mediathek downloads
# - by Stefan `Sec` Zehl <sec@42.org>
# - Licence: BSD (2-clause)

our ($dwim);

#$_='http://videos.arte.tv/de/videos/flaschenwahn_statt_wasserhahn-3775760.html';

$_=$ARGV[0];

use warnings;
use strict;
use GET;

GET::config (
		min_cache => 3000,
        );

my $body;
my $err;
my ($proto,$host,$app,$path);
my $name;
my $player;

$body=GET::get_url($_);

if ($_ =~ /ardmediathek.de/){
	#mediaCollection.addMediaStream(0, 1, "rtmp://swr.fcod.llnwd.net/a4332/e6/", "mp4:kultur/30-extra/alpha07/409171.m");

	if(!($body=~m!<h2>([^<]*)!)){
		die "Can't find title tag\n";
	};
	$name=$1;
	$name=~s!&.*?;!!g;
	$name=~y!0-9a-zA-Z -!!cd;
	$name=~s!\s*-\s*!-!g;
	$name=~s!\s+!_!g;
	$name="ARD-".$name.".flv";

	if (!($body=~m!mediaCollection.addMediaStream[^"]*"
				(rtmp)://([^/]*)/([^"]*)/",\s*"(mp4:[^"]*)"!ix)){
		die "Can't find stream URL\n";
	};
	($proto,$host,$app,$path)=($1,$2,$3,$4);
	$path=~s!\.[sm]$!.l!; # Use better stream!
}else{

if (!($body=~/url_player\s*=\s*"([^"]*)/s)){
	die "Can't find player URL\n";
};
$player=$1;

if(!($body=~/<embed src="([^"]*)/)){
	die "Can't find embed tag\n";
};

my $embed=$1;

#http://videos.arte.tv/blob/web/i18n/view/player_16-3188338-data-4836231.swf?admin=false&amp;autoPlay=true&amp;configFileUrl=http%3A%2F%2Fvideos.arte.tv%2Fcae%2Fstatic%2Fflash%2Fplayer%2Fconfig.xml&amp;embed=false&amp;lang=de&amp;localizedPathUrl=http%3A%2F%2Fvideos.arte.tv%2Fcae%2Fstatic%2Fflash%2Fplayer%2F&amp;mode=prod&amp;videoId=3783544&amp;videorefFileUrl=http%3A%2F%2Fvideos.arte.tv%2Fde%2Fdo_delegate%2Fvideos%2Falles_im_griff_-3783544%2Cview%2CasPlayerXml.xml';

$embed=~ s/.*videorefFileUrl=//;

$embed=~s/&amp;/\&/g;
$embed=~s/%(..)/chr hex $1/ge;


#

$body=GET::get_url($embed);

use strict;
use XML::LibXML;
my $parser = XML::LibXML->new();

my $doc = $parser->parse_string($body);
my $url=${
			$doc->findnodes('//*/video[@lang="de"]/@ref')
		}[0] -> textContent;

if(!$url){
	die "Couldn't find second xml url\n";
};

$body=GET::get_url($url);

if(!$body){
		die "No content?";
};

#print $body;

my $doc2 = $parser->parse_string($body);
$name= ${
			$doc2->findnodes('/video/name')
		}[0] -> textContent;

print "Video name: $name\n";

$name=~s! !_!g;
$name=~y!a-zA-Z_!!cd;
$name="ARTE-".$name.".flv";
my $url2=${
			$doc2->findnodes('//*/url[@quality="hd"]')
		}[0] -> textContent;

#print $url2,"\n";
#rtmp://artestras.fcod.llnwd.net/a3903/o35/MP4:geo/videothek/EUR_DE_FR/arteprod/A7_SGT_ENC_04_040261-000-A_PG_HQ_DE?h=404905af3f3096a4b903ca476b089063

if (!($url2=~ m!(rtmp)://([^/]*)/(.*)/(MP4:.*)!)){
	die "Can't match URL: $url2\n";
}; 

($proto,$host,$app,$path)=($1,$2,$3,$4);
};

if($player){
	$player="-W '$player' \\\n";
};

print <<EOM
rtmpdump \\
--protocol '$proto' --host '$host' --app '$app' \\
--playpath '$path' \\
${player}--flv '$name'
EOM
;
if ($dwim){
	system("rtmpdump \\
--protocol '$proto' --host '$host' --app '$app' \\
--playpath '$path' \\
${player}--flv '$name' ");
};
