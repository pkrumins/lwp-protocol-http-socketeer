package LWP::Protocol::http::Socketeer;

use strict;
use warnings;

use vars qw(@ISA $VERSION %SOCKET_OPTS);

use IO::Socket::Socks;
use LWP::Protocol::http;

@ISA = qw(LWP::Protocol::http);

$VERSION = 1.00;

our $MAX_CONNECT_ATTEMPTS = 1;
our $DEBUG = 0;

sub _new_socket
{
    my($self, $host, $port, $timeout) = @_;

    my $conn_cache = $self->{ua}{conn_cache};
    if ($conn_cache) {
        if (my $sock = $conn_cache->withdraw("http", "$host:$port")) {
            return $sock if $sock && !$sock->can_read(0);
            # if the socket is readable, then either the peer has closed the
            # connection or there are some garbage bytes on it.  In either
            # case we abandon it.
            $sock->close;
        }
    }

    local($^W) = 0;  # IO::Socket::INET can be noisy

    my $socket = $self->getSocket($host, $port);

    unless ($socket) {
        # IO::Socket::INET leaves additional error messages in $@
        die "Can't connect to $host:$port ($@)";
    }

    # perl 5.005's IO::Socket does not have the blocking method.
    eval { $socket->blocking(0); };

    return $socket;
}

sub getSocket
{
   my($self, $host, $port) = @_;

   die "No proxy was specified!" unless exists $SOCKET_OPTS{proxy};
   my $proxy = $SOCKET_OPTS{proxy};

   if ($DEBUG) {
      print "Host: ",     $proxy->{host},     "\n",
            "Port: ",     $proxy->{port},     "\n",
            "Username: ", $proxy->{login},    "\n",
            "Pass: ",     $proxy->{pass},     "\n";
   }

   my $socket;
   my $attempts = 0;
   do {
       print "Creating socket (attempt $attempts) to $host:$port via $proxy->{host}:$proxy->{port}\n" if $DEBUG;
       $socket = $self->createSocket($proxy, $host, $port);
       $attempts++;
   } while (!$socket && ($attempts <= $MAX_CONNECT_ATTEMPTS));

   return $socket;
}

sub createSocket {
    my ($self, $proxy, $host, $port) = @_;
    
    my $socket = $self->socket_class->new(
        ProxyAddr   => $proxy->{host},
        ProxyPort   => $proxy->{port},

        AuthType    => 'userpass',
        Username    => $proxy->{login},
        Password    => $proxy->{pass},

        ConnectAddr => $host,
        ConnectPort => $port,

        SocksDebug  => $DEBUG
    );
    
    return $socket;
}

#-----------------------------------------------------------
package LWP::Protocol::http::Socketeer::Socket;

use strict;
use warnings;
use vars qw( @ISA );

@ISA = qw(LWP::Protocol::http::SocketMethods Net::HTTP::Methods IO::Socket::Socks);

sub configure {
   my ($self, $cnf) = @_;
   $self->http_configure($cnf);
}

sub http_connect {
   my ($self, $cnf) = @_;
   $self->SUPER::configure($cnf);
}

1;

