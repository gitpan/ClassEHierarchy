# 03_accessor.t
#
# Tests for accessor functionality

$|++;
print "1..7\n";
my $test = 1;

# 1 load
use lib qw(./t);
use Entity;
my $new = Entity->new(
  Name        => 'Person',
  FirstName   => 'Bob',
  LastName    => 'Smith',
  ReadOnly    => 1,
  );
defined $new ? print "ok $test\n" : print "not ok $test\n";
$test++;

# 2 Read values
$new->FirstName eq 'Bob' ? print "ok $test\n" : print "not ok $test\n";
$test++;

# 3 Write r/o values
! $new->FirstName('Joe') ? print "ok $test\n" : print "not ok $test\n";
$test++;

# 4 Write writable values
$new->ReadOnly(0);
$new->FirstName('Joe') ? print "ok $test\n" : print "not ok $test\n";
$test++;

# 5 Verify write
$new->FirstName eq 'Joe' ? print "ok $test\n" : print "not ok $test\n";
$test++;

# 6 Hash write/read
$new->Hash(Foo => 'Bar', Bar => 'Foo');
my %h = $new->Hash;
$h{Foo} = 'Bar' ? print "ok $test\n" : print "not ok $test\n";
$test++;

# 7 Array write/read
$new->Array(qw(Foo Bar));
my @a = $new->Array;
$a[1] = 'Bar' ? print "ok $test\n" : print "not ok $test\n";

# end 03_accessor.t
