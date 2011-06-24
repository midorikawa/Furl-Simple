use strict;
use Test::More;
BEGIN { use_ok "Furl::Simple"; }

my $url = 'http://www.google.com/';
my $storefile = "t/store/store_file";

mkdir "t/store" or die "Could not create dir: t/store/";

my $code = getstore($url, $storefile, [ 'Accept-Encoding' => 'gzip' ]);

is $code, 200;

eval{ $code = getstore($url, $storefile, 'Accept-Encoding' => 'gzip' ); };

ok $@;


unlink $storefile;
done_testing;
