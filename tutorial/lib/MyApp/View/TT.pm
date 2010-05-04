	package MyApp::View::TT;
	use Moose;
	extends 'Catalyst::View::TT::Alloy';

	__PACKAGE__->config( {
			CATALYST_VAR => 'c',
			INCLUDE_PATH => [ MyApp->path_to( 'root', 'src' ) ]
		} );

	1;