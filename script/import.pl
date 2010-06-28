use 5.13.2;
use warnings;
use Path::Class;
use MyNote;

my $c = MyNote->new;

my $dir = shift or die "Usage: $0 dir\n";;
my @files;
dir($dir)->recurse(
    callback => sub {
        my $f = shift;
        return unless -f $f;
        my $src = $f->slurp(iomode => '<:utf8');
        my $stat = $f->stat;
        push @files,
          {
            src  => $src,
            stat => $stat,
          };
    },
);

for my $f (sort { $a->{stat}->ctime <=> $b->{stat}->ctime } @files) {
    $c->dbh->do(q{INSERT INTO entry (body, ctime, mtime) VALUES (?,?,?)}, {}, $f->{src}, $f->{stat}->ctime, $f->{stat}->mtime);
}
$c->dbh->commit;

