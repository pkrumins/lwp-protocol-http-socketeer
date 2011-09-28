HTTP protocol implementation for LWP that uses a proxy.

This module was written by Peteris Krumins (peter@catonmat.net, @pkrumins).
His blog is at http://www.catonmat.net  --  good coders code, great reuse.

------------------------------------------------------------------------------

Here is an example of how to use it:

#!/usr/bin/perl 
#

use strict;
use warnings;

use LWP::UserAgent;
use LWP::Protocol::http::Socketeer;

LWP::Protocol::implementor( http => 'LWP::Protocol::http::Socketeer' ); 

my $ua = new_agent;
my $resp = $ua->get('http://www.catonmat.net');
die unless defined $resp;

print $resp->content;

sub new_agent {
    my $proxy = { 
        login   =>  'your_proxy_login',
        pass    =>  'your_proxy_password',
        host    =>  'your_proxy.com',
        port    =>  '1088',
        type    =>  'socks5'
    };
    %LWP::Protocol::http::Socketeer::SOCKET_OPTS = (proxy => $proxy);

    my $ua = LWP::UserAgent->new;
}

