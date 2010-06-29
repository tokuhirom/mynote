use strict;
use warnings;
use 5.00800;
our $VERSION = '0.01';
use Path::Class;
use DBI;
use autodie;

package MyNote {
    use parent qw/AggreSiF/;

    __PACKAGE__->init();
};

package MyNote::M::Entries {
    use Text::Xslate qw/mark_raw/;

    sub fill_body_html {
        my ($class, $c, $entries) = @_;
        for my $entry (@$entries) {
            $entry->{body_html} //= do {
                my $html = MyNote::Formatter->new->parse($entry->{body});
                $c->dbh->do(q{UPDATE entry SET body_html=? WHERE id=?}, {}, $html, $entry->{id}) == 1 or die "cannot update";
                $html;
            };
            $entry->{body_html} = mark_raw( $entry->{body_html} );
        }
        $c->dbh->commit;
    }

    sub search {
        my ($class, $c, $entries_per_page, $page, $word) = @_;
        my $offset = $entries_per_page*($page-1);

        return () unless $word;

        MyNote::M::SearchHistory->update($c, $word);

        my $rows = $c->dbh->selectall_arrayref(
            q{SELECT * FROM entry WHERE id IN (SELECT entry_id FROM entry_index WHERE MATCH(body) AGAINST(CONCAT('+"', ?, '"') IN BOOLEAN MODE)) ORDER BY id DESC LIMIT ? OFFSET ?},
            { Slice => {} },
            $word, $entries_per_page+1, $offset
        );
        $class->fill_body_html($c, $rows);
        my $has_next;
        if (@$rows == $entries_per_page+1) {
            pop @$rows;
            $has_next = 1;
        }
        return ($rows, MyNote::Pager->new(has_next => $has_next, page => $page));
    }

    sub select {
        my ($class, $c, $entries_per_page, $page, $word) = @_;
        my $offset = $entries_per_page*($page-1);

        my ($rows) = $c->dbh->selectall_arrayref(q{SELECT * FROM entry ORDER BY id DESC LIMIT ? OFFSET ?}, {Slice => {}}, $entries_per_page+1, $offset);
        $class->fill_body_html($c, $rows);
        my $has_next;
        if (@$rows == $entries_per_page+1) {
            pop @$rows;
            $has_next = 1;
        }
        return ($rows, MyNote::Pager->new(has_next => $has_next, page => $page));
    }
};

package MyNote::Pager {
    use Mouse;
    has 'has_next' => (is => 'ro', isa => 'Bool', required => 1);
    has page => (is => 'ro', isa => 'Int', required => 1);
    __PACKAGE__->meta->make_immutable;
};

package MyNote::M::SearchHistory {
    use autobox::Core;

    sub select {
        my ($class, $c) = @_;
        my $rows = $c->dbh->selectall_arrayref(q{SELECT word, DATE(FROM_UNIXTIME(atime)) AS date FROM search_history ORDER BY atime DESC LIMIT 30}, {Slice => {}}, );
        my $date_entries;
        for my $row (@$rows) {
            push @{$date_entries->{$row->{date}}}, $row->{word};
        }
        my @ret =
          map { +{ date => $_, words => $date_entries->{$_} } }
          $date_entries->keys->sort->reverse;
        return wantarray ? @ret : \@ret;
    }
    sub update {
        my ($class, $c, $word) = @_;

        $c->dbh->do(
            q{INSERT INTO search_history (word) VALUES (?) ON DUPLICATE KEY UPDATE atime=UNIX_TIMESTAMP(NOW())},
            {}, $word );
    }
};

1;
__END__

=encoding utf8

=head1 NAME

MyNote -

=head1 SYNOPSIS

  use MyNote;

=head1 DESCRIPTION

MyNote is

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom AAJKLFJEF GMAIL COME<gt>

=head1 SEE ALSO

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
