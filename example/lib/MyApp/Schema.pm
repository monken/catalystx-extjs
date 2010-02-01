package MyApp::Schema;
  
use Moose;

extends 'DBIx::Class::Schema';

__PACKAGE__->load_namespaces;


sub ddl_filename {
    return 't/sqlite.sql';
}

1;