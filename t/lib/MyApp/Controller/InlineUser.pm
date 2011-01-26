package MyApp::Controller::InlineUser;

use Moose;
BEGIN { extends 'CatalystX::Controller::ExtJS::REST' }
with 'CatalystX::Controller::ExtJS::Direct';

__PACKAGE__->config(
                 limit             => 0,
                 default_resultset => 'User',
                 forms             => {
                     default => [ map { { name => $_ } } qw(id name password) ],
                     options => [
                                  { name        => 'ending',
                                    constraints => { type => 'Range',
                                                     min  => 2,
                                                     max  => 3
                                    } } ] } );

1;
