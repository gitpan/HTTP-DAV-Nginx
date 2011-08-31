package HTTP::DAV::Nginx;

use strict;
use warnings;

use LWP::UserAgent;
use HTTP::Request;
use Carp;

our $VERSION = '0.1.0';

#-----------
sub new
#-----------
{
	my $class = shift;
	my $url   = shift;
	my %param = @_;

	my $self = {};
	
	$self -> {'ua'} = new LWP::UserAgent;
	
	$url = _add_trailing_slash($url);
	$self -> {'url'} = $url;

	$self -> {'die_on_errors'} = $param{'die_on_errors'} || 0;

	bless $self, $class;

	return $self;
	
}

#------------
sub _error
#------------
{
	my $self  = shift;
	my $error = shift;
	
	if ($self -> {'die_on_errors'}) 
	{
		croak $error;
	}
	else
	{
		$self -> {'err'} = $error; 
	}
}

#------------------------
sub _add_trailing_slash
#------------------------
{
	my $url = shift;
	
	$url =~ s|//\z||;

	$url .= '/'; 

	return $url;
}

#--------------------------
sub _clear_begining_slash
#--------------------------
{
	my $uri = shift;

	$uri =~ s/^\///;

	return $uri;
}

#----------
sub err
#----------
{
	my $self = shift;
	
	return $self -> {'err'};
}

#-----------
sub mkcol
#-----------
{
	my $self  = shift;
	my $uri   = shift;

	my $request = HTTP::Request->new();
	$request -> method('MKCOL');
	$request -> uri($self -> {'url'} . _clear_begining_slash($uri));
	
	my $response = $self -> {'ua'} -> request($request);
	
	unless ($response -> is_success)
	{
		$self -> _error("METHOD:MKCOL URI:$uri Status:" . $response -> status_line);
		return undef;
	}
	
	return 1;
}

#-------------
sub delete
#-------------
{
	my $self   = shift;
	my $uri    = shift;
	my %params = @_;

	my $request = HTTP::Request->new();
	$request -> method('DELETE');
	$request -> uri($self -> {'url'} . _clear_begining_slash($uri));
	
	my $response = $self -> {'ua'} -> request($request);

#	$request -> header('Depth' => $params{'depth'  blah blah blah));
	
	unless ($response -> is_success)
	{
		$self -> _error("METHOD:DELETE URI:$uri Status:" . $response -> status_line);
		return undef;
	}

	return 1;
}

#---------
sub put
#---------
{
	my $self      = shift;
	my $uri       = shift;
	my $data_type = shift;
	my $data      = shift;

	unless ($data && $data_type)
	{
		$self -> _error('METHOD:PUT ERROR:data not specified');
		return;
	}
	
	my $request = HTTP::Request -> new();
	$request -> method('PUT');
	$request -> uri($self -> {'url'} . _clear_begining_slash($uri));
	
	my $content;
	
	if (lc($data_type) eq 'data')
	{	
		$content = $data;
	}
	elsif (lc($data_type) eq 'file')
	{
		open(FH, '<:raw', $data) or do
		{
			$self -> _error("Can't open file $data for reading");
			return;
		};
		binmode(FH);
		my $buffer;
		while (read(FH, $buffer, 512))
		{
			$content .= $buffer;
		}
	}
	elsif (lc($data_type) eq 'fh')
	{  blah blah blah
		my $buffer;
		while (read($data, $buffer, 512))
		{
			$content .= $buffer;
		}
	}
	
	$request -> content($content);

	my $response = $self -> {'ua'} -> request($request);
	unless ($response -> is_success)
	{
		$self -> _error("METHOD:PUT URI:$uri Status:" . $response -> status_line);
		return undef;
	}
	
	return 1;
}

#----------
sub copy
#----------
{
	my $self     = shift;
	my $uri      = shift;
	my $dest_uri = shift;

	my $request = HTTP::Request->new();
	$request -> method('COPY');
	$request -> uri($self -> {'url'} . _clear_begining_slash($uri));
	$request -> header('Destination' => $dest_uri);
	
	my $response = $self -> {'ua'} -> request($request);
	unless ($response -> is_success)
	{
		$self -> _error("METHOD:COPY URI:$uri Status:" . $response -> status_line);
		return undef;
	}
	
	return 1;
}

#---------
sub move
#---------
{
	my $self     = shift;
	my $uri      = shift;
	my $dest_uri = shift;

	my $request = HTTP::Request->new();
	$request -> method('MOVE');
	$request -> uri($self -> {'url'} . _clear_begining_slash($uri));
	$request -> header('Destination' => $dest_uri);
	
	my $response = $self -> {'ua'} -> request($request);
	unless ($response -> is_success)
	{
		$self -> _error("METHOD:MOVE URI:$uri Status:" . $response -> status_line);
		return undef;
	}
	
	return 1;
}

#OPTIONAL
#------------
sub symlink
#------------
{
	my $self     = shift;
	my $uri      = shift;
	my $dest_uri = shift;

	my $request = HTTP::Request->new();
	$request -> method('SYMLINK');
	$request -> uri($self -> {'url'} . _clear_begining_slash($uri));
	$request -> header('Destination' => $dest_uri);
	
	my $response = $self -> {'ua'} -> request($request);
	unless ($response -> is_success)
	{
		$self -> _error("METHOD:SYMLINK URI:$uri Status:" . $response -> status_line);
		return undef;
	}

	return 1;
}

#--------------
sub useragent
#--------------
{
	my $self = shift;
	
	return $self -> {'ua'};
}

1;
__END__

=head1 NAME

HTTP::DAV::Nginx - Client library for Nginx WebDAV server 

=head1 SYNOPSIS

  use HTTP::DAV::Nginx;
  
  $dav = HTTP::DAV::Nginx -> new('http://host.org:8080/dav/');
  or
  $dav = HTTP::DAV::Nginx -> new('http://host.org:8080/dav/', die_on_errors => 1);
  
  unless ($dav -> mkcol('/test'))
  {
    print "ERROR:" . $dav -> err;
  }
  
  $dav -> put('/test/123', data => 'Hello');

  $dav -> copy('/test/123', '/test2/12345');
  
  $dav -> move('/test/123', '/test3/123456');
  
  $dav -> delete('/test2/12345');
  
  $ua = $dav -> useragent;

=head1 DESCRIPTION

NGINX "supports" WebDAV by means of a module, but this support is incomplete: 
it only handles the WebDAV methods PUT, DELETE, MKCOL, COPY, and MOVE, 
and leaves the necessary OPTIONS and PROPFIND (and the optional LOCK, UNLOCK, and PROPPATCH) 
methods unimplemented.

This module doesn't uses PROPFIND and OPTIONS commands for work.


=head1 METHODS

=head2 new - Constructor

    Create a new HTTP::DAV::Nginx object;

    my $dav = HTTP::DAV::Nginx -> new('http://host.org:8080/dav/');
    or 
    HTTP::DAV::Nginx -> new('http://host.org:8080/dav/', die_on_errors => 1);

=head2 mkcol(uri) - creates a new dir at the location specified by the URI

=head2 copy(src_uri, dest_uri) - creates a duplicate of the source resource identified by URI

    src_uri - source URI
    dest_uri - destination URI

=head2 move(src_uri, dest_uri) - used to move a resource to the location specified by a URI

    src_uri - source URI
    dest_uri - destination URI

=head2 put(uri, data_type => data) - used to put data in a new resource specified by a URI

    $dav -> put('/uri', data => 'Hello');
    or
    $dav -> put('/uri', file => '/etc/passwd');
    or
    $dav -> put('/uri', fh => $fh);

    data_type - type of data:
      data - scalar data
      file - filename
      fh - filehandle
    data - scalar data or filename or filehandle
    
=head2 delete(uri, ...) deletes a resource at the specified


=head2 useragent - return LWP::UserAgent object for custom options (i.e. proxy, cookie etc)

=head2 err - return last error string

=head1 SEE ALSO

LWP::UserAgent

=head1 AUTHOR

Dmitry Kosenkov, E<lt>d.kosenkov@rambler-co.ru<gt>, E<lt>junker@front.ru<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Dmitry Kosenkov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
