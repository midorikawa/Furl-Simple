use strict;
use Test::More;
BEGIN { use_ok "Furl::Simple"; }


my $url = "http://www.omakase.org/";
my $stored_file = "t/store/mirrored_file";
{
my $code = mirror($url, $stored_file);

is $code, "200";
}

{
my ($minor_version, $code, $message, $headers, $content) = mirror($url, $stored_file);
diag $minor_version;
is $code, 304;
}

unlink $stored_file;
rmdir "t/store";

done_testing;
