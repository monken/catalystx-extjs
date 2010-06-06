package
  MyApp::View::JSON;

use strict;
use base 'Catalyst::View::JSON';

__PACKAGE__->config( expose_stash => 'json', encoding => 'utf-8' );

1;

