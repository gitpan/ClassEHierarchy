# 02_container.t
#
# Tests for container functionality

$|++;
print "1..5\n";
my $test = 1;

# 1 load
use Class::EHierarchy;
my $new = Class::EHierarchy->new(PROPERTIES => { Name => 'Foo' });
ref $new ? print "ok $test\n" : print "not ok $test\n";
$test++;

# 2 create child object
my $child = Class::EHierarchy->new(
  PARENT => $new, PROPERTIES => { Name => 'Foo' });
ref $child ? print "ok $test\n" : print "not ok $test\n";
$test++;

# 3 children
my @children = $new->children;
@children == 1 && $children[0] == $child ? print "ok $test\n" : 
  print "not ok $test\n";
@children = ();
$test++;

# 4 parent
$new == $child->parent ?  print "ok $test\n" : print "not ok $test\n";
$child = undef;
$test++;

# 5 terminate
$new->terminate;
$new = undef;
(listObjects()) == 0 ? print "ok $test\n" : print "not ok $test\n";
$test++;

# end 02_container.t
