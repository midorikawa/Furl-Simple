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

        subtest 'simple get' => sub {

            my $content = get( "http://127.0.0.1:$port/1" );

            is $content, 'OK';
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
                return [ 200, [ 'Content-Length' => 2 ], ['OK'] ];
            } elsif ($id =~ /^3\d\d$/) {
                my $base = $req->base;
                $base->path("/200"); # redirect target, see below
                return [ $id, [ 'Location' => $base->as_string ] ];
            } elsif ($id == 200) {
                # redirect target, see above
                my $method = $req->method;
                return [ 200, [ 'Content-Length' => length $method ], [$method] ];
            } else {
                my $base = $req->base;
                $base->path('/' . ($id + 1));
                return [ 302, ['Location' => $base->as_string], []];
            }
        });
    }
);
