package Furl::Simple;

use strict;
use warnings;
use 5.008_001;

use vars qw($ua @EXPORT @EXPORT_OK $VERSION);
use URI;
require Exporter;

@EXPORT = qw(get head getprint getstore mirror valid_uri);
@EXPORT_OK = qw($ua);

$VERSION = "0.01";

use Furl::HTTP;
use Furl::Response;
sub import
{
    my $pkg = shift;
    my $callpkg = caller;
    Exporter::export($pkg, $callpkg, @_);
}

my $timeout = $ENV{WWW_MIRROR_FURL_TIMEOUT} || 10;
my $agent   = $ENV{WWW_MIRROR_FURL_AGENT}   || "libwww-perl/5.834";

$ua = Furl::HTTP->new(agent => $agent, timeout => $timeout);  # we create a global UserAgent object


sub valid_uri {
    my $uri = shift;

    if ( ref ($uri) !~ m{^URI} ) {
        $uri = URI->new($uri) or die "could not create URI";
    }
    $uri;
}
sub mirror {
    my ( $uri, $file ) = @_;

    my $request_opts = [];
    $uri = valid_uri( $uri );


    # If the file exists, add a cache-related header
    if ( -e $file ) {
        my ($mtime) = ( stat($file) )[9];
        if ($mtime) {
            require HTTP::Date;
            $request_opts = ['If-Modified-Since' => HTTP::Date::time2str($mtime)]
        }
    }
    my $tmpfile = "$file-$$";

    my $response = Furl::Response->new( getstore($uri, $tmpfile, $request_opts) );

    # Only fetching a fresh copy of the would be considered success.
    # If the file was not modified, "304" would returned, which 
    # is considered by HTTP::Status to be a "redirect", /not/ "success"
    if ( $response->is_success ) {
        my @stat        = stat($tmpfile) or die "Could not stat tmpfile '$tmpfile': $!";
        my $file_length = $stat[7];
        my ($content_length) = $response->header('Content-length');

        if ( defined $content_length and $file_length < $content_length ) {
            unlink($tmpfile);
            die "Transfer truncated: " . "only $file_length out of $content_length bytes received\n";
        }
        elsif ( defined $content_length and $file_length > $content_length ) {
            unlink($tmpfile);
            die "Content-length mismatch: " . "expected $content_length bytes, got $file_length\n";
        }
        # The file was the expected length. 
        else {
            # Replace the stale file with a fresh copy
            if ( -e $file ) {
                # Some dosish systems fail to rename if the target exists
                chmod 0777, $file;
                unlink $file;
            }
            rename( $tmpfile, $file )
                or die "Cannot rename '$tmpfile' to '$file': $!\n";

            # make sure the file has the same last modification time
            if ( my $lm = $response->headers->header("last_modified") ) {
                utime $lm, $lm, $file;
            }
        }
    }
    # The local copy is fresh enough, so just delete the temp file  
    else {
        unlink($tmpfile);
    }

    return wantarray 
    ? ($response->{minor_version}, $response->code, $response->message, $response->headers, $response->content)
    : ($response->code) ;
}

sub get {
    my $uri = valid_uri(shift);
    my ($minor_version, $code, $msg, $headers, $body) = $ua->request(
        method     => 'GET',
        host       => $uri->host,
        port       => $uri->port,
        path_query => $uri->path
    );
    return $body if $code =~ m{^2};
    return;
}

sub head {

    my $uri = valid_uri(shift);
    my ($minor_version, $code, $msg, $headers, $body) = $ua->request(
        method     => 'HEAD',
        host       => $uri->host,
        port       => $uri->port,
        path_query => $uri->path
    );

    return unless $code =~ m{^2};
    # ($content_type, $document_length, $modified_time, $expires, $server)
    # warn Dumper ($minor_version, $code, $msg, $headers, $body) ;
    my %hdrs = @$headers;
    ( $hdrs{'content-type'}, $hdrs{'content-length'}, $hdrs{'last-modified'}, $hdrs{'expires'}, $hdrs{'server'}    );
}

sub getprint {
    my $uri = valid_uri(shift);# warn "URI:", $uri->host, "  path:", $uri->path, ":", $uri->port;
    local($\) = ""; # ensure standard $OUTPUT_RECORD_SEPARATOR
    my $callback = sub { my ( $status, $msg, $headers, $buf ) = @_; print $buf; };
    if ($^O eq "MacOS") {
	$callback = sub { my ( $status, $msg, $headers, $buf ) = @_; $buf =~ s/\015?\012/\n/g; print $buf }
    }

    my ($minor_version, $code, $msg, $headers, $body) = $ua->request(
        method     => 'GET',
        host       => $uri->host,
        port       => $uri->port,
        path_query => $uri->path,
        write_code => $callback,
    );
    unless ($code =~ m{^2}) {
        print STDERR $msg, " <URL:$uri>\n";
    }
    $code;
}

sub getstore($$;@) { ## no critic

    my $uri = valid_uri(shift);
    my $file = shift or Carp::croak "require save file name.";
    my $req_headers = shift || [];
    Carp::croak "recive headers option type array ref allow" if ref $req_headers ne 'ARRAY';
    open my $fh, ">", $file or Carp::croak "could not write file: $file";

    my ($minor_version, $code, $msg, $res_headers, $body) = $ua->request(
        method     => 'GET',
        host       => $uri->host,
        port       => $uri->port,
        path_query => $uri->path,
        write_file => $fh,
        headers    => $req_headers, 
    );
    return wantarray 
        ? ($minor_version, $code, $msg, $res_headers, $body) 
        : $code;
}



1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

Furl::Simple - Furl wrapped easy access module.

=head1 SYNOPSIS

    use Furl::Simple;

    my $url = 'http://www.google.com/';

    my  ( $content_type, $content_length, $last_modified, $expires, $server ) = head($url);

    my $content = get($url);

    my $res_code = getstore($url, $storefile, [ 'Accept-Encoding' => 'gzip' ]);

    my ($minor_version, $res_code, $msg, $res_headers, $body) = 

        getstore($url, $storefile, [ 'Accept-Encoding' => 'gzip' ]);

    my $res_code = getprint($url);

    my $res_code = mirror($url, $stored_file);

    my ($minor_version, $res_code, $message, $headers, $content) = mirror($url, $stored_file);


=head1 DESCRIPTION

Furl::Simple is Furl wrapped easy access module.

=head1 AUTHOR

tooru midorikawa E<lt>tooru@omakase.orgE<gt>

=head1 COPYRIGHT

Copyright 2011- tooru midorikawa

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
