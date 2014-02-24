use Moops;

class Role::Enumeration::UndefEnumNotAllowedException extends Role::Enumeration::Exception {

    with 'Throwable';

    has enum_class => (is => 'rw');
    has field      => (is => 'rw');
}

1;
