use 5.13.2;
use strict;
use warnings;
use Plack::Loader;
use Plack::Middleware::Static;
use MyNote;
use MyNote::Web;

sub sort_by(&@) {
    my $code = shift;
    map { $_->[0] } sort { $a->[1] <=> $b->[1] } map { [$_, $code->($_)] } @_;
}

my $app = MyNote::Web->handler;
$app = Plack::Middleware::Static->wrap(
    $app,
    path => qr{^/static/},
    root => file(__FILE__)->dir->subdir('htdocs'),
);

if ($0 eq __FILE__) {
    Plack::Loader->load('Standalone')->run($app);
} else {
    return $app;
}
