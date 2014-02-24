package Role::EnumerationTest;

use Test::Roo;
use Test::Exception;
use autobox::Core;

use lib 'lib', 't/lib';

my $class        = "Role::Enumeration";
my $test_classes = "Role::EnumerationTest::TestClasses";
my $test_class   = "Role::EnumerationTest::TestClasses::Plain";

my $enum;

before setup => sub {
    require_ok($class);
    require_ok($test_classes);
};

before each_test => sub {

    # $enum = $test_class->new;
    $enum = $test_class;
};

test 'can values ' => sub {
    can_ok $enum, "values";
};

test 'can names' => sub {
    can_ok $enum, "names";
};

test 'can map' => sub {
    can_ok $enum, "map";
};

test 'map() isa HASH' => sub {
    is ref($enum->map), "HASH";
};

test 'names' => sub {
    is_deeply [ $enum->names ], [qw(EAST NORTH NORTH_BY_NORTHWEST SOUTH WEST)];
};

test 'values size' => sub {
    is scalar($enum->values), 5;
};

test 'values isa' => sub {
    isa_ok [ $enum->values ]->first, $test_class;
};

test 'can $enum' => sub {
    can_ok $enum, "SOUTH";
};

test 'can is_$enum' => sub {
    can_ok $enum, "is_north";
};

test 'isa $enum' => sub {
    isa_ok $enum->NORTH, $test_class;
};

test 'is_$enum true' => sub {
    ok $enum->NORTH->is_north;
};

test 'is_$enum false' => sub {
    ok !$enum->NORTH->is_south;
};

test 'from_name' => sub {
    ok $enum->from_name("SOUTH")->is_south;
};

test 'from_name: undef fallback' => sub {
    ok Role::EnumerationTest::TestClasses::WithFallbacks->from_name(undef)
        ->is_south;
};

test 'from_name: undef - but no fallback' => sub {

    throws_ok sub { ok $enum->from_name(undef)->is_south; },
        Role::Enumeration::UndefEnumNotAllowedException->new;
};

test 'from_name: blank fallback' => sub {
    ok Role::EnumerationTest::TestClasses::WithFallbacks->from_name("")
        ->is_north;
};

test 'from_name: blank - but no fallback' => sub {

    throws_ok sub { ok $enum->from_name("")->is_south; },
        Role::Enumeration::BlankEnumNotAllowedException->new;
};

test 'from_name: invalid fallback' => sub {
    ok Role::EnumerationTest::TestClasses::WithFallbacks->from_name("invalid")
        ->is_invalid;
};

# TODO
# Enum->is_valid
# Enum->blank
# Enum->undef
# Enum->invalid

test 'from_name: not found' => sub {

    throws_ok sub { $enum->from_name("NORTHEAST") },
        Role::Enumeration::EnumNotFoundException->new;

    my $e = $@;
    is($e->enum_class, $test_class);
    is($e->field,      'name');
    is($e->value,      "NORTHEAST");
};

test 'guess_from_name: trailing space' => sub {
    ok $enum->guess_from_name("NORTH ")->is_north;
};

test 'guess_from_name: preceding space' => sub {
    ok $enum->guess_from_name(" NORTH")->is_north;
};

test 'guess_from_name: mixed case' => sub {
    ok $enum->guess_from_name("norTh")->is_north;
};

test 'guess_from_name: intermittend space' => sub {
    ok $enum->guess_from_name("NORTH BY NORTHWEST")->is_north_by_northwest;
};

test 'can user defined attribute' => sub {
    can_ok $enum->NORTH, 'id';
};

test 'user defined attribute: value' => sub {
    is $enum->SOUTH->id, 4;
};

test 'user defined attribute: value = undef' => sub {
    is $enum->SOUTH->short, undef;
};

test 'can from_-user defined attribute' => sub {
    can_ok $enum->NORTH, 'from_id';
};

test 'from_-user defined attribute' => sub {
    is $enum->from_id(4)->name, "SOUTH";
};

test 'from_-user defined attribute: not found' => sub {

    throws_ok sub { $enum->from_id(99) },
        Role::Enumeration::EnumNotFoundException->new;

    my $e = $@;
    is($e->enum_class, $test_class);
    is($e->field,      'id');
    is($e->value,      99);
};

test 'array ref constructor: can $enum' => sub {
    can_ok Role::EnumerationTest::TestClasses::WithArrayRefConstructor->new,
        'FOO';

    # can_ok $enum_with_array_ref_constructor, 'FOO';
};

run_me;
done_testing;

# TODO
# - unknown attribute on construction
# - test undef values + within search
# - test upper case on construction
# - restrict to ascii for now
# - guess_from_name: undef
