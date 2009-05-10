package
  MyApp::View::TT;

use strict;
use base 'Catalyst::View::TT';

__PACKAGE__->config( {
        CATALYST_VAR => 'Catalyst',
        INCLUDE_PATH => [ MyApp->path_to( '..', '..', 'root', 'src' ) ],
        WRAPPER      => 'wrapper',
        ERROR        => 'error.tt2',
        TIMER        => 0
    } );


1;

