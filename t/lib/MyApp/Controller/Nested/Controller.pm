package
  MyApp::Controller::Nested::Controller;
  
use Moose;
BEGIN { extends 'Catalyst::Controller' };
with 'CatalystX::Controller::ExtJS::Direct';

sub index : Local : Direct {}


1;