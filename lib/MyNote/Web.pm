use 5.13.2;
use Plack::Request;
package MyNote::Web;

# extend context object
package MyNote {
    use Text::Xslate qw/mark_raw/;
    use Text::Xatena;
    use Encode;
    use Time::Piece;

    my $xslate = Text::Xslate->new(
        syntax   => 'TTerse',
        path     => 'tmpl',
        cache => 0,
        function => {
            c       => sub { MyNote->context },
            render_xatena => sub {
                my ($src) = @_;
                return mark_raw( Text::Xatena->new->format($src) );
            },
            format_unixtime => sub {
                my $t = shift;
                Time::Piece->new($t)->strftime('%Y-%m-%d(%a) %H:%M');
            },
            VERSION => sub { MyNote->VERSION },
        },
        module => [qw/URI::Escape/],
    );
    sub render {
        my $self = shift;
        my $html = $xslate->render(@_);
        $html = Encode::encode_utf8 $html;
        MyNote::Response->new(200, ['Content-Length' => length($html), 'Content-Type' => 'text/html; charset=utf-8'], [$html]);
    }
    sub return_404 {
        MyNote::Response->new(404, ['Content-Type' => 'text/plain; charset=utf-8'], ['not found']);
    }
    sub redirect {
        my ($self, $location) = @_;
        my $res = MyNote::Response->new();
        $res->redirect($location);
        $res;
    }
    sub show_error {
        my ($self, $msg) = @_;
        MyNote::Response->new(500, ['Content-Type' => 'text/plain; charset=utf-8'], [$msg]);
    }

    sub req { $_[0]->{req} }
};

package MyNote::Web {
    use Encode;

    sub handler {
        my ($class) = @_;

        sub {
            my $env = shift;
            my $req = MyNote::Request->new($env);

            my $c = MyNote->new(req => $req);
            local *MyNote::context = sub { $c };

            my $res = $class->handle_request( $c, $req );

            return $res->finalize;
        };
    };

    sub handle_request {
        my ($class, $c, $req) = @_;
        given ($req->path_info) {
            when ('/') {
                my $entries_per_page = 20;
                my $page = $req->param('page') // 1;

                my ($entries, $pager) = MyNote::M::Entries->select($c, $entries_per_page, $page);

                $c->render('index.tt', {entries => $entries, pager => $pager});
            }
            when ('/update') {
                my $body = $req->param('body') // die "missing body";
                $body = decode_utf8($body);
                my $entry_id = $req->param('entry_id') // die "missing entry_id";

                $c->dbh->do(q{UPDATE entry SET body=? WHERE id=?}, {}, $body, $entry_id) == 1 or return $c->show_error("cannot update entry");
                $c->dbh->commit;

                $c->redirect('/');
            }
            when ('/post') {
                if (my $body = $req->param('body')) {
                    $body = decode_utf8($body);
                    $c->dbh->do(q{INSERT INTO entry (body) VALUES (?)}, {}, $body);
                    $c->dbh->commit;
                }
                $c->redirect('/');
            }
            when ('/search_history') {
                my $search_histories = MyNote::M::SearchHistory->select($c);
                $c->render('search_history.tt', {search_histories => $search_histories});
            }
            when ('/search') {
                # run grep here.
                my $entries_per_page = 20;
                my $page = $req->param('page') // 1;
                my $word = $req->param('word') or return $c->redirect('/');

                my ($entries, $pager) = MyNote::M::Entries->search($c, $entries_per_page, $page, $word);
                $c->dbh->commit(); # save history

                $c->render('index.tt', {entries => $entries, word => $word, pager => $pager});
            }
            default {
                $c->return_404()
            }
        };
    }
};

package MyNote::Request {
    use parent -norequire, qw/AggreSiF::Request/;
};

package MyNote::Response {
    use parent qw/Plack::Response/;
};

1;
