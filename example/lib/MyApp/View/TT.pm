package
  MyApp::View::TT;

use strict;
use base 'Catalyst::View::TT::Alloy';

__PACKAGE__->config( {
        CATALYST_VAR => 'c',
        INCLUDE_PATH => [ MyApp->path_to( 'root', 'src' ) ],
        TIMER        => 0,
        ENCODING => 'UTF8'
    } );


1;

