package Role::EnumerationTest::TestClasses;

use Moops;

class Plain {

    use Role::Enumeration;

    with Enumeration(
        class => __PACKAGE__,
        enums => {
            NORTH              => { id => 1, short => 'N', },
            EAST               => { id => 2, },
            WEST               => { id => 3, },
            SOUTH              => { id => 4, },
            NORTH_BY_NORTHWEST => { id => 5, short => 'NNW', },
        },
    );

    has id    => (is => 'ro', isa => Int);
    has short => (is => 'ro', isa => Str);
    has undef_field => (is => 'ro');
}

class WithFallbacks {

    use Role::Enumeration;

    with Enumeration(
        class => __PACKAGE__,
        enums => {
            NORTH   => { id => 1, short => 'N', },
            SOUTH   => { id => 4, },
            INVALID => { id => 99, },
        },

        blank   => "NORTH",
        undef   => "SOUTH",
        invalid => "INVALID",
    );

    has id    => (is => 'ro', isa => Int);
    has short => (is => 'ro', isa => Str);
    has undef_field => (is => 'ro');
}

class WithArrayRefConstructor {

    use Role::Enumeration;

    with Enumeration(
        class => __PACKAGE__,
        enums => [ qw( FOO BAR BAZ ), ],
    );

    has id => (is => 'ro', isa => Int);
}

1;
