package Entity;

use Class::EHierarchy;
use vars qw(@ISA);

@ISA = qw(Class::EHierarchy);

sub _init {
  my $self = shift;
  my %conf = @_;
  my $flags = $self->{FLAGS};
  my $register = $self->{FLAGREGISTER};
  my $properties = $self->{PROPERTIES};
  my $propvals = $self->{PROPVALUES};

  # Define the properties
  %$properties = (
    %$properties,
    FirstName   => [\&_genPropAccessor, \&_genPropAccessor],
    LastName    => [\&_genPropAccessor, \&_genPropAccessor],
    Hash        => \&_genPropAccessor,
    Array       => \&_genPropAccessor,
    );

  # Define the flags
  %$flags = (
    %$flags,
    ReadOnly    => \&_switchMode,
    Error       => undef,
    );

  # Set the prop/flag defaults
  $$propvals{Hash} = {};
  $$propvals{Array} = {};
  foreach (keys %$properties) {
    $$propvals{$_} = $conf{PROPERTIES}{$_} if exists $conf{PROPERTIES}{$_};
    $$propvals{$_} = $conf{$_} if exists $conf{$_};
  }
  foreach (keys %$flags) {
    $self->flag($_, $conf{FLAGS}{$_}) if exists $conf{FLAGS}{$_};
    $self->flag($_, $conf{$_}) if exists $conf{$_};
  }

  return 1;
}

sub _switchMode {
  my $self = shift;
  my ($ovalue, $nvalue) = @_;
  my $properties = $self->{PROPERTIES};

  foreach (qw(FirstName LastName)) {
    $$properties{$_}[0] = $nvalue ? \&_wSetError : \&_genPropAccessor;
  }
}

sub _wSetError {
  my $self = shift;

  $self->Error(1);

  return 0;
}

1;
