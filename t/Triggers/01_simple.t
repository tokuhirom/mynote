use 5.13.2;
use t::Util;
use Test::More;

my $c = init_db();
$c->dbh->do(q{INSERT INTO entry (body) VALUES ("FIRST")});

my $entry_id = $c->dbh->{mysql_insertid};
ok $entry_id, 'entry_id';

subtest 'entry [cm]time' => sub {
    my ($ctime, $mtime) = $c->dbh->selectrow_array(q{SELECT ctime, mtime FROM entry WHERE id=?}, {}, $entry_id);
    ok $ctime;
    ok $mtime;
    is $ctime, $mtime;
    done_testing;
};

subtest 'entry_history' => sub {
    $c->dbh->do(q{UPDATE entry SET body="SECOND" WHERE id=?}, {}, $entry_id) == 1 or die;
    my ($body, $ctime) = $c->dbh->selectrow_array(q{SELECT body, ctime FROM entry_history WHERE entry_id=?}, {}, $entry_id);
    is $body, 'FIRST';
    ok $ctime;
    done_testing;
};

subtest 'search_history' => sub {
    MyNote::M::SearchHistory->update($c, 'foo');
    my ($atime1) = $c->dbh->selectrow_array(q{SELECT atime FROM search_history WHERE word="foo"});
    ok $atime1;

    sleep 1;

    MyNote::M::SearchHistory->update($c, 'foo');

    my ($atime2) = $c->dbh->selectrow_array(q{SELECT atime FROM search_history WHERE word="foo"});

    isnt $atime1, $atime2;

    done_testing;
};

done_testing;

