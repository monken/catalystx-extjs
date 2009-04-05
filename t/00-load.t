#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'CatalystX::Controller::ExtJS' );
}

diag( "Testing CatalystX::Controller::ExtJS $CatalystX::Controller::ExtJS::VERSION, Perl $], $^X" );
