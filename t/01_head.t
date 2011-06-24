use strict;
use Test::More;


BEGIN { use_ok "Furl::Simple"; }

my $url = 'http://www.google.com/';

my  ( $content_type, $content_length, $last_modified, $expires, $server ) =
		 head($url);

like $content_type, qr/text/;


done_testing;
