package
  TestSchema::Result::FindOrDefault;

use base 'DBIx::Class';

__PACKAGE__->load_components(qw(Core));

__PACKAGE__->table('findordefault');

__PACKAGE__->add_columns(
    id       => { data_type => 'integer' },
    name     => { data_type => 'character varying',  default_value => 'myname' },
    password => { data_type => 'character varying',  default_value => 'mypassw0rd'  },
);

__PACKAGE__->set_primary_key('id');

1;