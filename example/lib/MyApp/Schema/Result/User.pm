package MyApp::Schema::Result::User;

use strict;
use warnings;

use base qw(MyApp::Schema::Result);

__PACKAGE__->table('user');

__PACKAGE__->add_columns(
    qw(email first last)
);

1;