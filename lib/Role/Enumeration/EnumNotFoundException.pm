use Moops;

class Role::Enumeration::EnumNotFoundException extends Role::Enumeration::Exception {

    with 'Throwable';

    has enum_class => (is => 'rw');
    has field      => (is => 'rw');
    has value      => (is => 'rw');
}

1;
