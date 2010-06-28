use strict;
use warnings;
use 5.13.2;

package AggreSiF {
    use parent qw/Class::Data::Inheritable/;
    use Path::Class;

    __PACKAGE__->mk_classdata(qw/config/);
    __PACKAGE__->mk_classdata(qw/base_dir/);

    sub context { die "no context is awaked" }

    sub init {
        my ($class) = @_;
        $class->init_base_dir();
        $class->init_config();
    }

    sub init_base_dir {
        my ($class) = @_;
        $class->base_dir(file(__FILE__)->dir()->parent());
    }

    sub init_config {
        my ($class) = @_;

        my $env = $ENV{PLACK_ENV} || 'development';
        my $fname = MyNote->base_dir->file('conf', "$env.pl")->stringify;
        my $config = do $fname or die "cannot load configuration file: $fname";
        $class->config($config);
    }

    sub new {
        my $class = shift;
        my %args = @_==1 ? %{$_[0]} : @_;
        bless { %args }, $class;
    }

    sub DESTROY {
        my $self = shift;

        if ($self->{dbh}) {
            $self->{dbh}->disconnect;
        }
    }

    sub dbh {
        my $self = shift;
        $self->{dbh} //= DBI->connect(@{$self->config->{DB}}) or die "DBI connection failed";
    }
};

package AggreSiF::Request {
    use parent qw/Plack::Request/;
    use URI::QueryParam;

    # code taken from Catalyst::Request
    sub uri_with {
        my( $self, $args, $behavior) = @_;

        Carp::carp( 'No arguments passed to uri_with()' ) unless $args;

        my $append = 0;
        if((ref($behavior) eq 'HASH') && defined($behavior->{mode}) && ($behavior->{mode} eq 'append')) {
            $append = 1;
        }

        my $params = do {
            foreach my $value ( values %$args ) {
                next unless defined $value;
                for ( ref $value eq 'ARRAY' ? @$value : $value ) {
                    $_ = "$_";
                    utf8::encode($_) if utf8::is_utf8($_);
                }
            }

            my %params = %{ $self->uri->query_form_hash };
            foreach my $key ( keys %{$args} ) {
                my $val = $args->{$key};
                if ( defined($val) ) {

                    if ( $append && exists( $params{$key} ) ) {

                    # This little bit of heaven handles appending a new value onto
                    # an existing one regardless if the existing value is an array
                    # or not, and regardless if the new value is an array or not
                        $params{$key} = [
                            ref( $params{$key} ) eq 'ARRAY'
                            ? @{ $params{$key} }
                            : $params{$key},
                            ref($val) eq 'ARRAY' ? @{$val} : $val
                        ];

                    }
                    else {
                        $params{$key} = $val;
                    }
                }
                else {

                    # If the param wasn't defined then we delete it.
                    delete( $params{$key} );
                }
            }
            \%params;
        };

        my $uri = $self->uri->clone;
        $uri->query_form($params);

        return $uri;
    }
};

1;
