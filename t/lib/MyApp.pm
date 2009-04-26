package
  MyApp;
  
use Moose;  

extends 'Catalyst';

use Catalyst::Request::REST::ForBrowsers;

__PACKAGE__->setup( qw(-Debug) );


1;