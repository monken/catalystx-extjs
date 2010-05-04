package CatalystX::Action::ExtJS::REST;
# ABSTRACT: Construct a new request class
use Moose;
extends 'Catalyst::Action::REST';

use Catalyst::Utils;
use Carp;

my @traits = qw(Catalyst::TraitFor::Request::REST CatalystX::TraitFor::Request::ExtJS);

sub new {
    my $class    = shift;
    my ($config) = @_;
    my $app      = Catalyst::Utils::class2appclass( $config->{class} );
    unless ( $app && $app->can('request_class') ) {
        croak q(Couldn't set the request class. Use REST::ExtJS from your application classes only!);
    }

    my $req_class = $app->request_class;
    
    return $class->next::method(@_) if $req_class->can('is_ext_upload');

    my $meta = Moose::Meta::Class->create_anon_class(
        superclasses => [$req_class],
        roles        => [@traits],
        cache        => 1
    );
    $meta->add_method( meta => sub { $meta } );
    $meta->make_immutable;
    $app->request_class( $meta->name );
    return $class->next::method(@_);
}

1;
