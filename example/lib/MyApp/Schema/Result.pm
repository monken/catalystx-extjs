package MyApp::Schema::Result;
use strict;
use warnings;
use base 'DBIx::Class';
__PACKAGE__->load_components(qw(RandomColumns TimeStamp Core));

__PACKAGE__->table('foo');

__PACKAGE__->add_columns(
	id => {
      data_type => 'character',
      is_random => {size => 10, set => ['a'..'z','A'..'Z', 0..9]},
      size => 10,
    },
    created_on => {
        data_type => 'timestamp with time zone',
        set_on_create => 1
    },
    updated_on => {
        data_type => 'timestamp with time zone',
        set_on_create => 1,
        set_on_update => 1
    });

__PACKAGE__->set_primary_key('id');

1;