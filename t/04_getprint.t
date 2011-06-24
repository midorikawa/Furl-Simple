use strict;
use warnings;
use Furl::Simple;
use Test::TCP;
use Test::More;
use Test::Requires 'Plack::Loader', 'Plack::Request';

use Plack::Loader;
use Plack::Request;
my $storefile = "t/store/store_file";



test_tcp(
    client => sub {
        my $port = shift;

        subtest 'getprint' => sub {

            my $res_code = getprint( "http://127.0.0.1:$port/1" );

            is $res_code, 200, "status 200";

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
                return [ 200, [ 'Content-Length' => 6 ], ['200 OK'] ];
            }
        });
    }
);
