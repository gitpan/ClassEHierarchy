# Class::EHierarchy -- Base class for traditional OO objects
#
# (c) 2003, Arthur Corliss <corliss@digitalmages.com>
#
# $Id: EHierarchy.pm,v 0.6 2003/02/18 23:09:03 acorliss Exp acorliss $
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#
#####################################################################

=head1 NAME

Class::EHierarchy - Base class for traditional OO Objects

=head1 MODULE VERSION

$Id: EHierarchy.pm,v 0.6 2003/02/18 23:09:03 acorliss Exp acorliss $

=head1 SYNOPSIS

  package Foo;

  use Class::EHierarchy qw(:all);
  use vars qw(@ISA);

  @ISA = qw(Class::EHierarchy);

  sub _init {
    . . .
  }

  regObject($custom);
  deregObject($custom);

  package main;

  $obj = Foo->new(
    PROPERTIES  => {
      Name      => 'Bar',
      Value     => 'I have no value!',
      },
    FLAGS       => {
      ReadOnly  => 1,
      Changed   => 0,
      });
  $obj = Foo->new(
    Name      => 'Bar',
    Value     => 'I have no value!',
    ReadOnly  => 1,
    Changed   => 0,
    );

  @objects = listObjects;
  $objref = getObject('Bar');

  $rv = $obj->hasFlag('ReadOnly');
  $f = $obj->flag('ReadOnly');
  $f = $obj->flag('ReadOnly', 0);
  $rv = $obj->checkState(qw(OR ReadOnly Changed));

  $rv = $obj->hasProperty('Value');
  $v = $obj->property('Value');
  $rv = $obj->property('Value', 'Now I do!');

  $objref = $obj->parent;
  @childrefs = $obj->children;
  $ns = $obj->namespace;

  $obj->addChild($custom);
  $obj->delChild($custom);
  $obj->getChild('Custom Foo');

  $obj->terminate;

=head1 REQUIREMENTS

Nothing outside of core Perl modules.

=head1 DESCRIPTION

This module provides a base class for traditional OO objects.  As such, it is
not intended for use directly, only as exposed through derived or subclassed
modules.

This module aggregates three OO class traits into a single module.  It does
not implement some of these traits completely, focusing instead on specific
aspects (see the various subsections in the B<Introduction>).

Modules which subclass this module will inherit B<Properties> and state
B<Flags>, similar in usage to other language implementations.  In addition,
class functions provide for tracking and access of objects currently in
memory.  All objects can track internally parent/child relationships and do a
clean termination of object heirarchies automatically.

=cut

#####################################################################
#
# Environment definitions
#
#####################################################################

package Class::EHierarchy;

use strict;
use vars qw($VERSION $AUTOLOAD @EXPORT @EXPORT_OK %EXPORT_TAGS @ISA);
use Carp;
use Exporter;

($VERSION) = (q$Revision: 0.6 $ =~ /(\d+(?:\.(\d+))+)/);
@ISA = qw(Exporter);
@EXPORT = qw(listObjects getObject _genPropAccessor);
@EXPORT_OK = qw(listObjects getObject regObject deregObject);
%EXPORT_TAGS = (
  ':all'    => [@EXPORT_OK],
  );

#####################################################################
#
# Module code follows
#
#####################################################################

=head1 INTRODUCTION

Some usage of traditional nomenclature need some clarification.  In this
document the terms B<Parent> and B<Child> refer not to the normal class
ancestral ties but to the container relationship.  In other words, children
belong to their parent, and that parent is responsible for cleaning up after
them when they're all destroyed.

That said, this class provides three core capabilities for all subclasses:

=head2 Automatic Accessors

There are two main elements within an object that you gain automatic accessors
for:  B<Properties> and B<Flags>.  Both can be accessed via a self-named
virtual method:

  # Retrieve the state of the read-only flag
  $rv = $obj->ReadOnly;

  # Retrieve the name of the object
  $name = $obj->Name;

In the case that both a flag and a property share the same name the virtual
method will always work on the property.  The only way to access the flag at
this point would be with the B<flag> method:

  # Equivalent call as above
  $rv = $obj->flag('ReadOnly');

Properties have an equivalent call, in those rare cases that you have a method
of the same name that doesn't do property manipulation (please don't interpret
the presence of this method as encouragement for more API obsfucation ;-):

  # Equivalent call as above
  $name = $obj->property('Name');

Flags differ from properties in that they are strictly boolean (Perlish
booleans, anyway, either 1 or 0).  In addition, each flag can be tied to an
"event handler", which is a method which is called each time the flag is
accessed (yes, that's right, B<accessed>, not B<modified>).  Flags don't
require a developer-provided accessor method since the value of the flag is
read and written directly to the register.

Properties have the extra capability of being write-only, read-only, or
read-write.  The mutability of a property is defined by the associated
accessor methods listed for that property in the PROPERTIES hash.  These are
installed by the B<_init> method, which is called by the B<new> constructor.
It is expected that each subclassed module override the _init method
appropriately.

Accessor methods can be defined in one of four ways:

    sub _init {
      my $self = shift;
      my $properties = $self->{PROPERTIES};
      . . .

      # Write-only example
      $$properties{'Value'} = [\&_wValue, undef];

      # Read-only example
      $$properties{'Value'} = [undef, \&_rValue];

      # Read-Write w/separate methods per access mode
      $$properties{'Value'} = [\&_wValue, \&_rValue];

      # Unified read-write handler
      $$properties{'Value'} = \&_rwValue;

      . . .
    }

As a convenience, a generic property accessor method is provided as part of
this class (B<_genPropAccessor>) which can be used in any of the above modes.
Custom accessors should accept the same calling list that the generic accessor
does:

  $self->_customAccessor($property, @values);

Since we always pass the property being accessed as the first value, you can
write generic accessors that can handle access for several properties.  A
values list is not needed, of course, for read-only accessors.

Write and unified accessors should always return a boolean value for attempted
write operations.  The return value should designate whether or not the write
operation succeeded.

B<NOTE>:  The generic accessor assumes that all property values are stored in
the PROPVALUES hash:

  # Retrieving the value of the Value property
  $value = $self->{PROPVALUES}->{Value};

It also attempts to do the Right Thing, depending on the reference type of the
hash value.  If it's a hash or array, it dereferences the value and returns it
in a list fashion.  If it's a scalar or any other kind of reference
(code, object, or scalar reference, etc.) it returns the value directly.

During assignment multiple values are assigned only if the hash value is an
array or hash reference.  Otherwise, it assumes that you're doing an
assignment to a scalar value, and stores the number of values passed, B<not>
the values themselves.

Understanding this is important:  if you have a property that stores a list of
values, you must initialise that hash value with, at minimum, an empty array
reference.  If you don't, you will be forced to make the initial assignment by
passing a value list by reference, instead of as normal arguments to the
method.  The same holds true for hash properties.  Also note that assigning a
list to an array or hash property B<overwrites> the previous contents.  This
method does not combine or aggregate them.

Regardless of whether or not you use the generic accessor method, it would be
wise to keep with the internal convention and store all of your property
values in the PROPVALUES hash space, and not the object hash space itself.

=head2 Rudimentary Event Handlers

A rudimentary event system exists based on the B<Flag> register.  Flags, as
mentioned above, are essentially boolean properties, but properties that you
associate event handlers for in lieu of accessors.  Any associated event
handler is called with each access or modification to that flag.  Event
handlers are associated with specific flags in the B<_init> method:

  sub _init {
    my $self = shift;
    my $flags = $self->{FLAGS};
    . . .

    %$flags = (
      %$flags,
      ReadOnly  => \&_roHandler,  # Flag w/event handler
      Changed   => undef,         # Flag w/o event handler
      );

    . . .
  }

Event handlers will be called with the following syntax and arguments (using
the above ReadOnly example):

  $obj->_rohandler($oldvalue, $newvalue);

The code withing the handler can decide whether to take action by comparing
the old and new values of the flag.

  # This handler only takes action when the flag changes
  sub _rohandler {
    my $self = shift;
    my ($ovalue, $nvalue) = @_;

    if ($ovalue != $nvalue) {
      # do something
    }
  }

  # This handler takes action whenever the flag is accessed/set and
  # and is true
  sub _rohandler {
    my $self = shift;
    my ($ovalue, $nvalue) = @_;

    if ($nvalue) {
      # do something
    }
  }

  # This handler takes action whenever the flag is set to true
  sub _rohandler {
    my $self = shift;
    my ($ovalue, $nvalue) = @_;

    if ($nvalue && ! $ovalue) {
      # do something
    }
  }

The thing to remember is that event handlers are called immediately upon
register access, so you need to take care that you don't overflow the
execution stack by getting stuck in a recursive calling loop (i.e., an event
handler accesses a different flag which sets off an event handler that
accesses the original flag, and sets off another event handler call, etc.).

Event handlers must return the final flag state as their return value.

=head2 Containers

The relationship implied by the container aspect of this class lies not in
common ancestry or interface, but in ownership (i.e., an object exists only
within the context of the container, once the container is destroyed, all
contained objects are destroyed as well).  The point of tracking this
relationship is to do a more orderly destruction of objects than what Perl's
normal garbage collection does.

Take database container object that contains table objects that cache writes.
The container is responsible for maintaining the database connection, and uses
a DESTROY method to close any existing connections cleanly.  The table objects
have a DESTROY method that flushes and changes to the data in memory to the
database.  If you were to rely on Perl's normal garbage collection, the
container's last reference would go out of scope first, causing the database
connection to close.  Then, as the container's resources are freed, the last
references to the table objects would close and they would subsequently try to
flush their data to a closed connection.

For this reason, we need the container to make sure that it destroys the
objects it contains before it destroys itself.  And for that we have the
B<terminate> method:

  $container->terminate;

Every subclass based on this class will recursively call terminate so that the
container's subcontainers and objects are freed from the bottom up.

=head1 CLASS FUNCTIONS

=cut

{
  my %objects;

=head2 regObject

  $rv = regObject($obj);

B<NOTE>:  Any object class that uses the constructor method provided in this
module should never have to call this function.

This function registers the creation of a new object with the class tracking
hash.  It will return a true or a false depending on whether registration
was successful.

While each object must have a unique name, each object provides a private
namespace for any children.  As an example:

  # Registered in the class tracking hash as 'Foo'
  $parent = Class::EHierarchy::Derived->new(
    PROPERTIES => { Name => 'Foo' });

  # Registered in the class tracking hash as 'Foo::Bar'
  $child = Class::EHierarchy::Derived->new(
    PARENT  => $parent,
    PROPERTIES => { Name => 'Bar' },
    );

Creating an object with the same name as another object in the same namespace
will cause this function to return a false value.

This function is only exported as part of the B<:all> export tag set.

=cut

  sub regObject {
    my $object = shift;
    my $name = $object->Name;
    my $ns = $object->namespace;

    if (exists $objects{"$ns$name"}) {
      carp "An object by that name ($name) already exists " .
        "within the $ns namespace, not registering";
      return 0;
    }

    $objects{"$ns$name"} = $object;
    return 1;
  }

=head2 deregObject

  $rv = deregObject($obj);

B<NOTE>:  Any object class that uses the terminate method provided in this
module should never have to call this function.

This function removes the object reference from the class tracking hash.  It
returns a true or false depending on whether the deregistration was
successful.

This function is only exported as part of the B<:all> export tag set.

=cut

  sub deregObject {
    my $object = shift;
    my $name = $object->Name;
    my $ns = $object->namespace;

    unless (exists $objects{"$ns$name"}) {
      carp "No object by that name ($name) exists to deregister " .
        "within the $ns namespace";
      return 0;
    }

    delete $objects{"$ns$name"};
    return 1;
  }

=head2 listObjects

  @objects = listObjects;

This function returns a list of all the full names of any objects registered 
with the class tracking hash.  Each full name consists of a namespace and a 
name a la:

  ($namespace, $name) = ($fullname =~ /^(.+::)?(.+)$/);

These names will be returned in random hash key order.

=cut

  sub listObjects {
    return keys %objects;
  }

=head2 getObject

  $obj = getObject($fullname);

This function returns a reference to the object specified by its full name.
If that object is not registered in the class tracking hash, an undef is
returned.

=cut

  sub getObject {
    my $name = shift;

    return exists $objects{$name} ? $objects{$name} : undef;
  }
}

=head1 METHODS

=head2 new

  $obj = Class::EHierarchy::Derived->new(
    PARENT      => $pobj,
    PROPERTIES  => {
      Name      => 'foo',
      },
    FLAGS       => {
      ReadOnly  => 1,
      Changed   => 0,
      },
    );
  $obj = Class::EHierarchy::Derived->new(
    PARENT    => $pobj,
    Name      => 'foo',
    ReadOnly  => 1,
    Changed   => 0,
    );

The new constructor instantiates an instance of the specified class.  The only
mandatory argument that needs to be passed is the B<Name> definition within
the B<PROPERTIES> hash.  The B<PARENT> argument specifies the container
(another object) that this object belongs to, and is optional.

As the above examples show, if all the passed values are truly unique (in
other words, no flags, properties, or other special keys with the same name) 
you can omit the PROPERTIES and FLAGS hashes, putting the key/value pairs 
directly in the constructor argument list.

=cut

sub new {
  my $class = shift;
  my %conf = @_;
  my $self = {};
  my %properties;
  my $err = 0;
  my $name;

  bless $self, $class;

  # Initialise a few structures
  $self->{FLAGREGISTER} = {};
  $self->{FLAGS} = {};
  $self->{PROPERTIES} = {};
  $self->{PROPVALUES} = {};
  $self->{CHILDREN} = [];
  $self->{PARENT} = exists $conf{PARENT} ? $conf{PARENT} : undef;

  # Make sure the object was named, and store the name
  $name = exists $conf{PROPERTIES}{Name} ? $conf{PROPERTIES}{Name} :
    exists $conf{Name} ? $conf{Name} : undef;
  if (defined $name) {
    $self->{PROPERTIES}->{Name} = [undef, \&_genPropAccessor];
    $self->{PROPVALUES}->{Name} = $name;
    delete $conf{PROPERTIES}{Name} if exists $conf{PROPERTIES}{Name};
    delete $conf{Name} if exists $conf{Name};
  } else {
    $err = 1;
    carp "Object instance created without a Name property";
  }

  # Process the _init method
  unless ($err) {
    $err = $self->_init(%conf) ? 0 : 1;
  }

  # Register the object
  unless ($err) {
    $err = regObject($self) ? 0 : 1;
  }

  # Add the child's handle the parent's children array
  $self->parent->addChild($self) if defined($self->parent) && ! $err;

  return $err ? undef : $self;
}

=head2 _init (OVERRIDE IN SUBCLASS)

  $rv = $self->_init(%conf);

This method performs any subclass-specific initialisation needed, and is
called from within the constructor.  Use this method to define the flags,
properties, and default values for that class.  It should return a true or
false, with the latter causing the constructor to not return a valid object
reference.

It is important to remember not to wipe out any information placed in the
PROPERTIES, PROPVALUES, FLAGS, and FLAGREGISTER hashes by the constructor.  In 
other words, dereference the existing hash references, don't replace it with 
another one (at this time, only the B<Name> property is being handled by the
constructor).

  Example:
  =========================================

  sub _init {
    my $self = shift;
    my %conf = @_;
    my $properties = $self->{PROPERTIES};
    my $propvals = $self->{PROPVALUES};
    my $flags = $self->{FLAGS};
    my $register = $self->{FLAGREGISTER};

    # Define some additional properties
    %$properties = (
      %$properties,

      # Separate routines for read and write access
      Value   => [ \&_wValue, \&_rValue],

      # A read-only property using the generic accessor method
      Foo     => [ undef, \&_genPropAccessor],

      # A read-write property using the generic accessor in unifed mode
      Bar     => \&_genPropAccessor,
      );

    # Use the conf values to set some default properties
    foreach (keys %$properties) {
      $$propvals{$_} = $conf{PROPERTIES}{$_} if exists $conf{PROPERTIES}{$_};
      $$propvals{$_} = $conf{$_} if exists $conf{$_};
    }

    # Define some additional flags
    %$flags = (
      %$flags,

      # Flag with no associated event handler
      ReadOnly    => undef,

      # Flag with an associated event handler
      Changed     => undef,
      );

    # Set whatever default flags and properties you want. . .
    $$register{ReadOnly} = 1;

    return 1;
  }

Please remember that the constructor allows the constructor to be passed a
flat hash as an argument list in lieu of separating the pairs into PROPERTIES
and FLAGS.  You should try to accommodate that as long as there are no name
collisions between the two.

=cut

sub _init {
  my $self = shift;
  my %conf = @_;

  return 1;
}

=head2 flag

  $value = $obj->flag('ReadOnly');
  $value = $obj->flag('ReadOnly', 1);

The flag method provides access to the flag register, and returns the value of
the flag.  The first argument is the name of the flag, while the second
optional argument is the value it is to be set to.

Please note that you can access flags in the same manner as properties
provided that there is no property with the same name:

  $value = $obj->ReadOnly;
  $value = $obj->ReadOnly(1);

=cut

sub flag {
  my $self = shift;
  my $flag = shift;
  my $value = shift;
  my $register = $self->{FLAGREGISTER};
  my $flags = $self->{FLAGS};
  my $ovalue;

  # Make sure the specified flag exists
  carp "No flag specified for access" and return undef unless
    defined $flag;
  carp "No flag defined by that name ($flag)" and return undef
    unless exists $$flags{$flag};

  # Initialise the register as false if it hasn't been used yet
  $$register{$flag} = 0 unless exists $$register{$flag};
  $ovalue = $$register{$flag};

  if (defined $value) {

    # Make sure we're dealing only with 1s or 0s
    $value = $value ? 1 : 0;

    # Set the new value
    $$register{$flag} = $value;

  } else {
    $value = $ovalue;
  }

  # Call the event handler
  $$register{$flag} = &{$$flags{$flag}}($self, $ovalue, $value) if 
    ref($$flags{$flag}) eq 'CODE';

  # Return the flag value
  return $$register{$flag};
}

=head2  checkState

  $rv = $obj->checkState(qw(OR ReadOnly Changed));

This method returns the logical result of the specified operation and the list
of flags.  You can choose from the following list of operators:  AND, OR, XOR.

=cut

sub checkState {
  my $self = shift;
  my $op = shift;
  my @operands = @_;
  my $register = $self->{FLAGREGISTER};
  my $flags = $self->{FLAGS};
  my ($rv, @values);

  # Make sure a known logical operator was requested
  return undef unless $op =~ /^(?:AND|OR|XOR)$/;

  # Retrieve the flag values
  foreach (@operands) {
    unless (exists $$flags{$_}) {
      carp ref($self), ":  no such flag ($_) to check";
      next;
    }

    $$register{$_} = 0 unless exists $$register{$_};
    push(@values, $$register{$_});
  }

  # Perform the logical operation
  foreach (@values) {
    if (defined $rv) {
      if ($op eq 'AND') {
        $rv = $rv & $_;
      } elsif ($op eq 'OR') {
        $rv = $rv | $_;
      } elsif ($op eq 'XOR') {
        $rv = $rv != $_ ? 1 : 0;
      }
    } else {
      $rv = $_;
    }
  }

  return $rv;
}

=head2 hasFlag

  $rv = $obj->hasFlag('Foo');

This method returns a boolean value designating whether or not a flag with
the given name exists.

=cut

sub hasFlag {
  my $self = shift;
  my $flag = shift;
  my $flags = $self->{FLAGS};
  my $rv = exists $$flags{$flag} ? 1 : 0;

  return $rv;
}

=head2 property

  $value = $obj->property('Value');
  $rv = $obj->property('Value', 1);

This method provides access to defined properties.  The first argument is the
name of the property to access, while the second optional argument is the new
value to assign to the property.  Write operations do not return the property
value, they return a boolean value designating whether or not the attempted
write operation was successful.

Please note that you can access all properties as a virtual method, provided
no other method exists with that name.

  $value = $obj->Value;
  $rv = $obj->Value(1);

=cut

sub property {
  my $self = shift;
  my $property = shift;
  my @values = @_;
  my $properties = $self->{PROPERTIES};
  my $method;

  # Make sure the specified property exists
  carp "No property specified for access" and return undef unless
    defined $property;
  carp "No property defined by that name ($property)" and return undef
    unless exists $$properties{$property};

  # Retrieve the accessor method
  if (ref($$properties{$property}) eq 'CODE') {
    $method = $$properties{$property};
  } elsif (ref($$properties{$property}) eq 'ARRAY') {
    $method = @values ? $$properties{$property}[0] : 
      $$properties{$property}[1];
  }

  # Return the results of the write operation
  if (@values) {

    # Warn if no method was found
    carp "Property $property doesn't appear to have a write method!" and
      return undef unless defined $method;

    # Return the results of the write method
    return &$method($self, $property, @values);

  # Return the results of the read method
  } else {

    # Warn if none were found
    carp "Property $property doesn't appear to have a read method!" and 
      return undef unless defined $method;

    # Return the results of the write method
    return &$method($self, $property);
  }
}

=head2 hasProperty

  $rv = $obj->hasProperty('Foo');

This method returns a boolean value designating whether or not a property with
the given name exists.

=cut

sub hasProperty {
  my $self = shift;
  my $property = shift;
  my $properties = $self->{PROPERTIES};
  my $rv = exists $$properties{$property} ? 1 : 0;

  return $rv;
}

sub AUTOLOAD {
  my $self = shift;
  my $property = ($AUTOLOAD =~ /([^:]+)$/)[0];
  my $properties = $self->{PROPERTIES};
  my @pnames = keys %$properties;
  my $flags = $self->{FLAGS};
  my @fnames = keys %$flags;

  return if $property eq 'DESTROY';

  # Check for defined properties
  if (grep /^\Q$property\E$/, @pnames) {
    
    # Create a permanent accessor method for future calls
    eval "sub $property { return shift->property('$property', \@_) }";
    return $self->property($property, @_);

  # Check for defined flags
  } elsif (grep /^\Q$property\E$/, @fnames) {
    eval "sub $property { return shift->flag('$property', \@_) }";
    return $self->flag($property, @_);

  # Handle access to undefined properties and flags
  } else {
    carp "Attempt to access an undefined property or flag ($property)";
    return undef;
  }
}

=head2 parent

  $objref = $obj->parent;

This method returns a reference to the container (or parent) of the object.
This will be undef for those objects that don't belong to any particular
container.

=cut

sub parent {
  my $self = shift;

  return $self->{PARENT};
}

=head2 children

  @children = $obj->children;

This method returns a list of object references to every object (or child) 
contained by this object.  The list will be empty for any childless object.

=cut

sub children {
  my $self = shift;

  return (@{$self->{CHILDREN}});
}

=head2 namespace

  $ns = $obj->namespace;

This method returns a scalar string containing the container this object
belongs to.  For parentless objects, this will be a zero-length string.

=cut

sub namespace {
  my $self = shift;
  my $p = $self;
  my $ns = '';

  while (defined($p = $p->parent)) {
    $ns = $p->Name . "::$ns";
  }

  return $ns;
}

=head2 addChild

  $obj->addChild($objref);

This method is not typically used by the developer, since the constructor of
this call automatically calls it upon successful initialisation of an object.
If, however, you want a non-Class::EHierarchy-derived module to be contained by
this object, this method is available.

=cut

sub addChild {
  my $self = shift;
  my $child = shift;
  my $children = $self->{CHILDREN};

  push (@$children, $child);

  return 1;
}

=head2 delChild

  $obj->delChild($objref);

Like the addChild method, this is not normally used by the developer, since
the terminate method calls it automatically.

=cut

sub delChild {
  my $self = shift;
  my $child = shift;
  my $children = $self->{CHILDREN};
  my $rv = 0;
  my $i;

  for ($i = 0; $i < @$children; $i++) {
    if ($$children[$i] == $child) {
      splice(@$children, $i, 1);
      $rv = 1;
      last;
    }
  }

 return $rv;
}

=head2 getChild

  $objref = $obj->getChild('Foo');

This method returns an object reference for the specified child, or undef if
no child by that name exists.

=cut

sub getChild {
  my $self = shift;
  my $name = shift;
  my $children = $self->{CHILDREN};
  my ($child, $i);

  unless (defined $name) {
    carp "You must specify the name of the child to retrieve";
    return undef;
  }

  for ($i = 0; $i < @$children; $i++) {
    if ($$children[$i]->Name eq $name) {
      $child = $$children[$i];
      last;
    }
  }

  return $child;
}

=head2 _genPropAccessor

As mentioned in the B<INTRODUCTION>, this method is provided as a convenience
for the class developer, and is not intended to be called directly by class
users.  Please read the B<Automatic Accessors> subsection for a more complete
description of the usage of this method.

=cut

sub _genPropAccessor {
  my $self = shift;
  my $property = shift;
  my @values = @_;
  my $properties = $self->{PROPERTIES};
  my $pvalues = $self->{PROPVALUES};
  my $type = ref($$pvalues{$property});

  return undef unless exists $$properties{$property};

  # Store the passed value(s), if any
  if (@values) {
    if ($type eq 'ARRAY') {
      $$pvalues{$property} = [@values];
    } elsif ($type eq 'HASH') {
      $$pvalues{$property} = {@values};
    } else {
      $$pvalues{$property} = @values > 1 ? @values : shift @values;
    }

    # Since this accessor does no validation of data, it always 
    # returns a successful write result
    return 1;
  }

  # Return the stored value(s)
  if ($type eq 'ARRAY') {
    return @{$$pvalues{$property}};
  } elsif ($type eq 'HASH') {
    return %{$$pvalues{$property}};
  } else {
    return $$pvalues{$property};
  }
}

=head2 terminate

  $obj->terminate;

This method should be called prior to letting your last object reference go
out of scope.  Failure to do so will cause memory leaks and other such badness
to happen.

=cut

sub terminate {
  my $self = shift;
  my $children = $self->{CHILDREN};
  my $child;

  # Terminate each of the children
  while ($child = shift @$children) {
    $child->terminate if $child->isa('Class::EHierarchy');
  }

  # Remove this object from its parent's children array
  $self->parent->delChild($self) if defined $self->parent;

  # Deregister the object from the class tracker
  deregObject($self);
}

=head2 can

  $obj->$method if $obj->can($method);

This module does override the B<UNIVERSAL::can> method to check for property
and flags that the B<AUTOLOAD> method may have not created a permanent method
for yet.  Since it uses and returns the result of the UNIVERSAL::can, there is
no difference in usage.

=cut

sub can {
  my $self = shift;
  my $method = shift;
  my @internal = (keys %{$self->{PROPERTIES}}, keys %{$self->{FLAGS}});
  my $rv;

  return undef unless defined $method;

  $rv = $self->SUPER::can($method);
  unless ($rv) {
    $self->$method and $rv = $self->SUPER::can($method) 
      if grep /^\Q$method\E$/, @internal;
  }

  return $rv;
}

END {
  my @objects = grep ! /^.+::/, listObjects;

  foreach (@objects) {
    getObject($_)->terminate;
  }
}

1;

=head1 HISTORY

=over

=item 2003/01/21 -- Original implemenation

=back

=head1 AUTHOR/COPYRIGHT

(c) 2003, Arthur Corliss (corliss@digitalmages.com)

=cut

