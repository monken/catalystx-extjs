package CatalystX::Action::ExtJS::Deserialize;

use strict;
use warnings;

use base 'Catalyst::Action::Deserialize';


sub execute {
    my ($self, $controller, $c) = @_;
    if($c->req->param('x-requested-by') && $c->req->param('x-requested-by') eq "ExtJS"
          && $c->req->header('Content-Type') && $c->req->header('Content-Type') =~ /^multipart\/form-data/ ) {
              return 1;
          } else {
              return $self->next::method($controller, $c);
          }
}


1;