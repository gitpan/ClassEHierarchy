# 04_event.t
#
# Tests for event functionality

$|++;
print "1..5\n";
my $test = 1;

# 1 load
use lib qw(./t);
use Entity;
my $new = Entity->new(
  PROPERTIES    => {
    Name        => 'Person',
    FirstName   => 'Bob',
    LastName    => 'Smith',
    },
  FLAGS         => {
    ReadOnly    => 1,
    });
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

# end 04_event.t
