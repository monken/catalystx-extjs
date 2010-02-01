package CatalystX::Action::ExtJS::Deserialize;

use strict;
use warnings;

use base 'Catalyst::Action::Deserialize';

use Catalyst::Request::REST::ForBrowsers;


=head1 PUBLIC METHODS

=head2 execute

Stops further deserialisation if the current request looks like a request
from ExtJS and has multipart form data, so usually an upload.

=cut

sub execute {
    my ($self, $controller, $c) = @_;
    my $class = 'Catalyst::Request::REST::ForBrowsers';
    $c->request_class($class) unless($c->engine->isa('Catalyst::Plugin::SubRequest::Internal::FakeEngine') || $c->request_class->isa($class));
    
    if($c->req->param('x-requested-by') && $c->req->param('x-requested-by') eq "ExtJS"
          && $c->req->header('Content-Type') && $c->req->header('Content-Type') =~ /^multipart\/form-data/ ) {
              return 1;
          } else {
              return $self->next::method($controller, $c);
          }
}


1;