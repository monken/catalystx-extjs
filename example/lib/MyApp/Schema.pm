package MyApp::Schema;
  
use Moose;

extends 'DBIx::Class::Schema';

__PACKAGE__->load_namespaces;


sub ddl_filename {
    return 'example/sqlite.sql';
}

1;