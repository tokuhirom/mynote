use strict;
use warnings;
use MyNote::Web;
use HTTP::Message::PSGI;
use HTTP::Request;
use Plack::Util;

my $req = HTTP::Request->new(GET => 'http://localhost/');
my $env = req_to_psgi($req);

my $app = Plack::Util::load_psgi('mynote.psgi');
print "ready\n";
for (1..1000) {
    $app->($env);
}

