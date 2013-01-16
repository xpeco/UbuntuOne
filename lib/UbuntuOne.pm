#!/usr/bin/perl
package UbuntuOne;

use warnings;
use strict;
use vars qw($VERSION);
$VERSION='0.2';

use JSON;
use Data::Dumper;
use Carp;
use LWP::UserAgent;
use LWP::Authen::OAuth;
use Net::OAuth;
use HTTP::Request::Common "GET";
use Digest::MD5  qw(md5 md5_hex md5_base64);

sub new{
  my $class=shift;
  my $self={@_};

  bless($self, $class);
  $self->_init;
  $self->_signon;
  return $self;
}

sub _init{
  my $self=shift;
  $self->{-device}='Perl' if (not defined($self->{-device}));

  my $file='.uo_'.$self->{-device};

  if(-e $file)
  {
    open(FH,'<'.$file);
    my @data=<FH>;chomp(@data);
    $self->{keys}->{consumer_key}=$data[0];
    $self->{keys}->{consumer_secret}=$data[1];
    $self->{keys}->{token}=$data[2];
    $self->{keys}->{token_secret}=$data[3];
    close FH;
   }
   else{
      if ( (not defined($self->{-user})) || (not defined($self->{-pass})) ){
         croak "Error: not user defined. Nor token file exists\n";
      }
      else{
       # Create token and store it on a file
       $self->_createtoken;
       open(FH,'>'.$file);
       print FH $self->{keys}->{consumer_key}."\n";
       print FH $self->{keys}->{consumer_secret}."\n";
       print FH $self->{keys}->{token}."\n";
       print FH $self->{keys}->{token_secret}."\n";
       close FH;
      }
   }
}

sub _createtoken
{
  my $self=shift;
  my $ua = LWP::UserAgent->new;
  my $req = HTTP::Request->new;
  $req->method('GET');
  $req->uri('https://login.ubuntu.com/api/1.0/authentications?ws.op=authenticate&token_name=Ubuntu One @ '.$self->{-device});
  $req->authorization_basic($self->{-user},$self->{-pass});
  my $result=$ua->request($req);
  if($result->content eq 'Authorization Required')
  {
    croak "UbuntuOne account fails to login";
  }
  else{
    my $data = from_json($result->content);
    $self->{keys}->{consumer_key}=$data->{consumer_key};
    $self->{keys}->{consumer_secret}=$data->{consumer_secret};
    $self->{keys}->{token}=$data->{token};
    $self->{keys}->{token_secret}=$data->{token_secret};
  }
  return $self;
}

sub _signon
{
  my $self=shift;
# Ahora debemos tener los valores de OAuth con lo que debemos prepara nuestras conexiones para que vayan firmadas con dichos valores
  my $b=LWP::Authen::OAuth->new(
              oauth_consumer_key => $self->{keys}->{consumer_key},
              oauth_consumer_secret => $self->{keys}->{consumer_secret},
              oauth_token => $self->{keys}->{token},
              oauth_token_secret => $self->{keys}->{token_secret},
  );
# If ok...
# Segun la documentacion de UbuntuOne ahora debemos cerrar el proceso de OAuth para que nos permita acceder a la API
  my $r = $b->get("https://one.ubuntu.com/oauth/sso-finished-so-get-tokens/");
  $b->oauth_update_from_response($r);
  print "Firmando: ".$r->content."\n";
}

sub simple_call
{
 my $self=shift;
 my $uri=shift; 
 my $time=time;
 my $nonce = md5_hex("nonce_key".$time);
 my $request = Net::OAuth->request("protected resource")->new(
            consumer_key => $self->{keys}->{consumer_key},
            consumer_secret => $self->{keys}->{consumer_secret},
            request_url => $uri,
            request_method => 'GET',
            signature_method => 'PLAINTEXT',
            signature => $self->{keys}->{consumer_secret}.'%26'.$self->{keys}->{token_secret},
            timestamp => $time,
            nonce => $nonce,
            token => $self->{keys}->{token},
            token_secret => $self->{keys}->{token_secret},
        );
 $request->sign;
 my $lwp_object = LWP::UserAgent->new;
 my $lwp_request = GET $request->to_url;
 my $response = $lwp_object->request($lwp_request);
 my $result = from_json($response->content);
 return $result;
}

sub account
{
 my $self=shift;
 return $self->simple_call('https://one.ubuntu.com/api/account');
}

sub quota
{
 my $self=shift;
 return $self->simple_call('https://one.ubuntu.com/api/quota');
}

sub get_files
{
 my $self=shift;
 my $vol=shift || '';
 my $path=shift || '';
 return $self->simple_call('https://one.ubuntu.com/api/file_storage/v1'.$vol.$path);
}

=head1 NAME

UbuntuOne - The great new UbuntuOne!

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use UbuntuOne;

    my $foo = UbuntuOne->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 function1

=head2 function2

=cut

sub function2 {
}

=head1 AUTHOR

Peco, C<< <peco at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ubuntuone at rt.cpan.org>, o
r through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=UbuntuOne>
.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc UbuntuOne


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=UbuntuOne>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/UbuntuOne>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/UbuntuOne>

=item * Search CPAN

L<http://search.cpan.org/dist/UbuntuOne/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Peco.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;
