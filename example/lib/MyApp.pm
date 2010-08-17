package MyApp;
use Moose;
use namespace::autoclean;

use Catalyst::Runtime 5.80;

use Catalyst qw/
    Static::Simple
    Unicode::Encoding
/;

extends 'Catalyst';

__PACKAGE__->config(
    name => 'MyApp',
    disable_component_resolution_regex_fallback => 1,
    encoding => 'UTF-8'
);

__PACKAGE__->setup();


1;
