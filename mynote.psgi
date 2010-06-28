use 5.13.2;
use strict;
use warnings;
use Plack::Loader;
use Plack::Middleware::Static;
use MyNote;
use MyNote::Web;
use Plack::Builder;

sub sort_by(&@) {
    my $code = shift;
    map { $_->[0] } sort { $a->[1] <=> $b->[1] } map { [$_, $code->($_)] } @_;
}

my $app = builder {
    enable 'Plack::Middleware::Static',
        path => qr{^/static/},
        root => file(__FILE__)->dir->subdir('htdocs'),
    ;
    enable "Plack::Middleware::ContentLength";
    MyNote::Web->handler;
};

if ($0 eq __FILE__) {
    Plack::Loader->load('Standalone')->run($app);
} else {
    return $app;
}
