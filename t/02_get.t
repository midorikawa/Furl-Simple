use strict;
use Test::More;
BEGIN { use_ok "Furl::Simple"; }

my $url = 'http://www.google.com/';


my $content = get($url);

like $content, qr/<html>/;

done_testing;
