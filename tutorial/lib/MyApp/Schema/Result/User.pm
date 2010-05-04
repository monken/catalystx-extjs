package MyApp::Schema::Result::User;

use Moose;
extends 'DBIx::Class::Core';

__PACKAGE__->table('user');

__PACKAGE__->add_columns(
	id => { is_auto_increment => 1, data_type => 'integer' },
    qw(email first last)
);

__PACKAGE__->set_primary_key('id');

1;