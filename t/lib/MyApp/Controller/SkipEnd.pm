package
  MyApp::Controller::SkipEnd;
  
use base 'CatalystX::Controller::ExtJS::REST';

__PACKAGE__->config(
    form_base_path => [qw(t root forms)],
    list_base_path => [qw(t root lists)],
);

sub object_GET {
    my ($self, $c, @args) = @_;
    $self->maybe::next::method($c, @args);
    
    $c->res->body('foo');
    
}

1;