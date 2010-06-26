use 5.13.2;
use autodie;

BEGIN {
    $ENV{PLACK_ENV} = 'test';
};

package t::Util {
    use parent qw/Exporter/;
    our @EXPORT = qw/init_db/;
    use MyNote;
    use Storable qw/dclone/;
    use Test::mysqld;
    use autodie;

    sub init_db {
        my $c = MyNote->new();

        my $dbconf = dclone($c->config->{DB});
        $dbconf->[0] =~ s/database=test_MyNote;//;

        $c->{mysqld} = my $mysqld = Test::mysqld->new(
            my_cnf => {
                'skip-networking' => '',    # no TCP socket
            }
        );
        my $dbh = DBI->connect($mysqld->dsn(dbname => 'test', mysql_enable_utf8 => 1, mysql_multi_statements => 1)) or die;

        {
            open my $fh, '<', 'sql/my.sql';
            my @sql = MySQL::Splitter->split($fh);
            $dbh->do($_) for @sql;
        }

        $c->{dbh} = $dbh;

        return $c;
    }

    package MySQL::Splitter {
        our $DEFAULT_DELIMITER = ';';

        sub split {
            my ($class, $fh) = @_;

            my $delimiter = $DEFAULT_DELIMITER;
            my $buf = '';
            my @sql;
            while (<$fh>) {
                given ($_) {
                    when (/^\s*DELIMITER\s+(.+)\s*$/) {
                        $delimiter = $1;
                    }
                    when (m{^(.*)\Q$delimiter\E\s*$}) {
                        $buf .= $1;
                        push @sql, "$buf";
                        $buf = '';
                    }
                    default {
                        $buf .= $_;
                    }
                }
            }
            push @sql, "$buf" if $buf;
            @sql = grep /\S/, @sql;
            return wantarray ? @sql : \@sql;
        }
    }
}

1;
