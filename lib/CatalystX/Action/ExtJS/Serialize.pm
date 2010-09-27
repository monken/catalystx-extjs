package CatalystX::Action::ExtJS::Serialize;
# ABSTRACT: Handle responses from uploads
use strict;
use warnings;

use base 'Catalyst::Action::Serialize';

sub execute {
    my ( $self, $controller, $c ) = @_;
    $self->next::method( $controller, $c );
    if ( $c->stash->{upload} && $c->stash->{upload} eq 'true' ) {
        $c->res->content_type('text/html');
        my $body = $c->res->body;
        $body =~ s/&quot;/\&quot;/;
        $c->res->body(
            '<html><body><textarea>' . $body . '</textarea></body></html>' );
    }
}

1;

__END__

=head1 PUBLIC METHODS

=head2 execute

Wrap the serialized response in a textarea field if there was a file upload.
Furthermore set the C<content-type> to C<< text/html >>.

=cut