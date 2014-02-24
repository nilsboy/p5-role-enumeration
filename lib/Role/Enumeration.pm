package Role::Enumeration;

use strict;
use warnings;
no warnings 'uninitialized';
use Storable qw(dclone);
use Role::Enumeration::EnumNotFoundException;
use Role::Enumeration::UndefEnumNotAllowedException;
use Role::Enumeration::BlankEnumNotAllowedException;
use Data::Dumper;

use Package::Variant
    importing => [ 'Moo::Role', ],                      # what modules to 'use'
    subs      => [qw(has around before after with)];    # proxied subroutines

sub make_variant {
    my ($class, $target_package, %arguments) = @_;

    # print STDERR Dumper \%arguments;

    with 'MooX::Singleton';

    my $enum_class   = $arguments{class} || die "Specify enum class";
    my $enums_wanted = $arguments{enums} || die "Specify enums";

    my $blank_fallback   = $arguments{blank};
    my $undef_fallback   = $arguments{undef};
    my $invalid_fallback = $arguments{invalid};

    # TODO change name?
    my $enums = ();

    if (ref $enums_wanted eq 'ARRAY') {
        foreach my $enum (@$enums_wanted) {
            $enums->{$enum} = {};
        }
    }
    elsif (ref $enums_wanted eq 'HASH') {

        # TODO necessary? - prevent action at a distance
        $enums = dclone($enums_wanted);
    }
    else {
        die "Specify enum as ref of hash or array";
    }

    foreach my $enum_name (keys %$enums) {
        $enums->{$enum_name}{name} = $enum_name
            if !exists $enums->{$enum_name}{name};
    }

    has name => (is => 'rw');

    install names => sub {
        return sort keys %$enums;
    };

    install values => sub {
        my ($self) = @_;
        return values $self->instance->map;
    };

    install map => sub {
        my ($self) = @_;

        my $map = {};

        foreach my $enum_name (keys %$enums) {
            $map->{$enum_name} = $self->instance->$enum_name;
        }

        return $map;
    };

    # TODO use ->meta->attributes to find enum attributes instead of $enum
    # Where do I get meta() from?
    # use Class::MOP::Class ();
    # my $meta = $class->meta; # does not work

    # use Moose::Util qw(find_meta);
    # my $meta = find_meta($enum_class) || die "No metaclass found";

    # create subs ->$ENUM and ->is_$enum
    foreach my $enum_name (keys %$enums) {

        my $init_args = $enums->{$enum_name};
        $init_args->{name} = $enum_name;

        my $private_enum_name = "_" . $enum_name;

        has $private_enum_name => (is => 'lazy');

        install "_build_${private_enum_name}" => sub {
            return $enum_class->new(%$init_args);
        };

        install $enum_name => sub {
            my ($self) = @_;
            return $self->instance->$private_enum_name;
        };

        install "is_" . lc($enum_name) => sub {
            my ($self) = @_;
            return 1 if $self->name eq $enum_name;
            return 0;
        };
    }

    # create subs ->from_$field
    {
        my $from_subs = ();
        foreach my $enum (values %$enums) {

            foreach my $enum_field (keys %$enum) {

                next if $enum_field eq "name";

                my $from_sub = "from_" . $enum_field;

                next if exists $from_subs->{$from_sub};

                $from_subs->{$from_sub} = 1;

                install $from_sub => sub {
                    my ($self, $value) = @_;

                    foreach my $enum (values %$enums) {
                        my $enum_sub = $enum->{name};
                        return $self->$enum_sub
                            if $enum->{$enum_field} eq $value;
                    }

                    Role::Enumeration::EnumNotFoundException->throw(
                        enum_class => $enum_class,
                        field      => $enum_field,
                        value      => $value
                    );
                };
            }
        }
    }

    install guess_from_name => sub {
        my ($self, $name) = @_;

        $name =~ s/^\s+//g;
        $name =~ s/\s+$//g;
        $name =~ s/\s+/_/g;
        $name = uc($name);

        return $self->from_name($name);
    };

    install from_name => sub {
        my ($self, $name) = @_;

        if (!defined $name) {

            if (!$undef_fallback) {
                Role::Enumeration::UndefEnumNotAllowedException->throw(
                    enum_class => $enum_class,
                    field      => 'name',
                );
            }

            return $self->from_name($undef_fallback);
        }

        if ($name =~ /^\s*$/) {

            if (!$blank_fallback) {
                Role::Enumeration::BlankEnumNotAllowedException->throw(
                    enum_class => $enum_class,
                    field      => 'name',
                    value      => $name,
                );
            }

            return $self->from_name($blank_fallback);
        }

        if (!exists $enums->{$name}) {

            if (!$invalid_fallback) {
                Role::Enumeration::EnumNotFoundException->throw(
                    enum_class => $enum_class,
                    field      => 'name',
                    value      => $name,
                );
            }

            return $self->from_name($invalid_fallback);
        }

        return $self->$name;
    };
}

1;
