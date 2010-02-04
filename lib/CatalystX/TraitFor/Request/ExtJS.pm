package CatalystX::TraitFor::Request::ExtJS;
use Moose::Role;

use namespace::autoclean;
use JSON::XS;

has 'is_ext_upload' => ( isa => 'Bool', is => 'rw', lazy_build => 1 );

sub _build_is_ext_upload {
    my ($self) = @_;
    return $self->header('Content-Type')
      && $self->header('Content-Type') =~ /^multipart\/form-data/;
}

around 'method' => sub {
    my ( $orig, $self, $method ) = @_;
    return $self->$orig($method) if($method);
    return $self->query_params->{'x-tunneled-method'} || $self->$orig();
    

};

1;

__END__

=head2 is_extjs_upload

Returns true if the current request looks like a request from ExtJS and has
multipart form data, so usually an upload. 
