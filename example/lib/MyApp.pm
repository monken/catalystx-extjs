package MyApp;
use Moose;
use namespace::autoclean;

use Catalyst::Runtime 5.80;

use Catalyst qw/
    Static::Simple
    Unicode
/;

extends 'Catalyst';

__PACKAGE__->config(
    name => 'MyApp',
    disable_component_resolution_regex_fallback => 1,
);

__PACKAGE__->setup();


1;
