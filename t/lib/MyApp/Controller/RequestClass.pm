package
  MyApp::Controller::RequestClass;
  
use Moose;
use JSON::XS;

BEGIN { extends 'Catalyst::Controller' };

sub params : Local {
    my ($self, $c) = @_;
    my $body;
    for(qw(body_params query_params params)) {
        $body->{$_} = $c->req->$_;
    }
    $c->res->body(encode_json($body));
}

sub request_class : Local {
    my ($self, $c) = @_;
    $c->res->body($c->request_class);
}



1;