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
    my ( $self, $controller, $c ) = @_;

    if (   $c->req->is_ext_upload )
    {
        return 1;
    }
    else {
        return $self->next::method( $controller, $c );
    }
}

1;
