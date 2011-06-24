use strict;
use warnings;
use Furl::Simple;
use Test::TCP;
use Test::More;
use Test::Requires 'Plack::Loader', 'Plack::Request';

use Plack::Loader;
use Plack::Request;
my $storefile = "t/store/store_file";

use Data::Dumper;

test_tcp(
    client => sub {
        my $port = shift;

        subtest 'mirror' => sub {
			mkdir ("t/store", 0777) or die "Could not create dir: t/store/";
            my $res_code = mirror( "http://127.0.0.1:$port/1", $storefile );

            is $res_code, 200, "first code";
			ok -e $storefile;
			
			open my $fh, $storefile or die "Could not create t/store/store_file";
			local $/ = undef;
			my $content = <$fh>;
			is $content, "200 OK", "file store content read";

			
			my ($minor_version, $code1, $message, $headers, $content1) = mirror("http://127.0.0.1:$port/1", $storefile);
			# diag Dumper ($minor_version, $code1, $message, $headers, $content1);
			is $code1, 200, "second code";
			is $content1, undef, "second content";
			
			unlink $storefile;
			rmdir "t/store";
        };



        done_testing;
    },
    server => sub {
        my $port = shift;
        Plack::Loader->auto(port => $port)->run(sub {
            my $env = shift;
            my $req = Plack::Request->new($env);
            $req->path_info =~ m{/(\d+)$} or die;
            my $id = $1;
            if ($id == 1) {
                return [ 200, [ 'Content-Length' => 6, 'Last-Modified' => 'Mon, 13 Jun 2011 02:04:51 GMT' ], ['200 OK'] ];
            }
        });
    }
);
