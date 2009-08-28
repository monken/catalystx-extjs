package
  MyApp::Controller::User;
  
  use base 'CatalystX::Controller::ExtJS::REST';

use Moose;



#with Deletable;

__PACKAGE__->config(
    form_base_path => [qw(t root forms)],
    list_base_path => [qw(t root lists)],
);

1;