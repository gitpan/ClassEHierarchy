# 01_ini.t
#
# Tests for proper loading of the module

$|++;
print "1..5\n";
my $test = 1;

# 1 load
use Class::EHierarchy;
my $new = Class::EHierarchy->new(PROPERTIES => { Name => 'Foo' });
ref $new ? print "ok $test\n" : print "not ok $test\n";
$test++;

# 2 load 2
$new->terminate;
$new = Class::EHierarchy->new(Name => 'Foo');
ref $new ? print "ok $test\n" : print "not ok $test\n";
$test++;

# 3 listObjects
(listObjects())[0] eq 'Foo' ? print "ok $test\n" : print "not ok $test\n";
$test++;

# 4 getObject
my $obj = getObject('Foo');
$new == $obj ? print "ok $test\n" : print "not ok $test\n";
$test++;

# 5 terminate
$new->terminate;
$obj = $new = undef;
$obj = getObject('Foo');
! defined($obj) ? print "ok $test\n" : print "not ok $test\n";
$test++;

# end 01_ini.t
