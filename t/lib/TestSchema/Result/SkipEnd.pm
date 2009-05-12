package
  TestSchema::Result::SkipEnd;

use base 'DBIx::Class';

__PACKAGE__->load_components(qw(Core));

__PACKAGE__->table('skip_end');

__PACKAGE__->add_columns(

    id => { data_type => 'integer' },
    name => { data_type => 'character varying' },
    password => { data_type => 'character varying' },
    
);

__PACKAGE__->set_primary_key('id');

1;