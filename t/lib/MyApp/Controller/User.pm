package
  MyApp::Controller::User;
  
use Moose;
BEGIN { extends 'CatalystX::Controller::ExtJS::REST' };
with 'CatalystX::Controller::ExtJS::Direct';

__PACKAGE__->config(
    form_base_path => [qw(t root forms)],
    list_base_path => [qw(t root lists)],
    limit => 0,
);

sub add_to_group : Chained('base') Args(1) {
    
}


1;