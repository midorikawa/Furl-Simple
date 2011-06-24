use strict;
use Test::More;
BEGIN { use_ok "Furl::Simple"; }

my $url = "http://www.omakase.org/";


my $code = getprint($url);


is $code, 200, "status code";

done_testing;
