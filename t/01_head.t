use strict;
use warnings;
use Furl::Simple;
use Test::TCP;
use Test::More;
use Test::Requires 'Plack::Loader', 'Plack::Request';

use Plack::Loader;
use Plack::Request;

test_tcp(
    client => sub {
        my $port = shift;

        subtest 'simple head' => sub {

			my ($content_type, $content_length, $last_modified, $expires, $server ) = 

				head( "http://127.0.0.1:$port/1" );


			is $content_type, 'text/plain', "content type";
			is $content_length, 0, "content length";
			is $last_modified, 'Wed, 21 Jan 2004 19:51:30 GMT', "last modified";
			is $expires, 'Wed, 19 Apr 2000 11:43:00 GMT', "expires";
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
                return [ 200, [ 
					'Content-Type' => 'text/plain',
					'Content-Length' => 0, 
					'Expires' =>  'Wed, 19 Apr 2000 11:43:00 GMT', 
					'Last-Modified' => 'Wed, 21 Jan 2004 19:51:30 GMT' 
					], 
					[''] ];
            }
        });
    }
);


