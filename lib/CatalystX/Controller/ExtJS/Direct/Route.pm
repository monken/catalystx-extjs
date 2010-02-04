package CatalystX::Controller::ExtJS::Direct::Route;
use Moose;

has 'action'     => ( is => 'ro', required   => 1 );
has 'name'       => ( is => 'rw', lazy_build => 1 );
has 'dispatcher' => ( is => 'rw', weak_ref   => 1 );

sub _build_name {
    my ($self) = @_;
    return $self->action->attributes->{Direct}->[0] || $self->action->name;
}

sub build_api {
    my ($self) = @_;
    return { name => $self->name, len => 0 };
}

sub build_url {
    my ( $self, $c, $data ) = @_;
    return $c->uri_for( $self->action );
}

sub build {
    return shift->new(@_);
}

sub request {
	my ($self, $req) = @_;
    return ( data => $req->{data});
}

package CatalystX::Controller::ExtJS::Direct::Route::Chained;
use Moose::Role;

has 'arguments' => ( is => 'rw', isa => 'Int', lazy_build => 1 );

sub _build_arguments {
    my ($self) = @_;
    my $action = $self->action;
    my $len = $action->attributes->{Args}[0] || 0;
    my $parent = $action;
    while (
        $parent->attributes->{Chained}
        && (
            $parent = $self->dispatcher->get_action_by_path(
                $parent->attributes->{Chained}->[0]
            )
        )
      )
    {

        $len += $parent->attributes->{CaptureArgs}[0];
    }
    return $len || 0;
}

sub build_api {
    my ($self) = @_;
    return { name => $self->name, len => $self->arguments+0 };
}

sub build_url {
    my ( $route, $c, $data ) = @_;
    my @data = @{ $data || [] };
	@data = grep { !ref $_ } @data;
	my $captures_length =
      defined $route->action->attributes->{Args}->[0]
      
      ? $route->arguments - $route->action->attributes->{Args}->[0]
      : 0;
    my @captures = splice( @data, 0, $captures_length );
    return $c->uri_for( $route->action, [@captures], @data );
}

package CatalystX::Controller::ExtJS::Direct::Route::REST;
use Moose::Role;

has 'crud_action' => ( is => 'rw', isa => 'Str' );

has 'crud_methods' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub {
        {
            create  => 'POST',
            update  => 'PUT',
            read    => 'GET',
            destroy => 'DELETE'
        };
    }
);

#around '_build_arguments' => sub {
#    my ( $orig, $self, $args ) = @_;
#    my $arguments = $self->$orig();
#    $arguments--
#      if ( $arguments > 0 && ($self->crud_action eq 'create'
#        || $self->crud_action eq 'update') );
#    return $arguments;
#};

sub _build_name {
    my ($self) = @_;
    return $self->crud_action;
}

sub build {
    my ( $class, $args ) = @_;
    my @routes;
    foreach my $action (qw(create read update destroy)) {
        push( @routes, $class->new( { %$args, crud_action => $action } ) );
    }
    return @routes;
}

around 'request' => sub {
    my ($orig, $self, $req)   = @_;
    my %params = $self->$orig($req);
    return (
        %params,
		method        => $self->crud_methods->{ $self->crud_action },
        content_types => ['application/json']
    );

};

package CatalystX::Controller::ExtJS::Direct::Route::REST::ExtJS;
use Moose::Role;

around '_build_arguments' => sub {
    my ( $orig, $self, $args ) = @_;
    my $arguments = $self->$orig();
    $arguments++;
    return $arguments;
};

package CatalystX::Controller::ExtJS::Direct::Route::Factory;

sub build {
    my ( $class, $dispatcher, $action ) = @_;
    my $params = { action => $action, dispatcher => $dispatcher };
    my @roles;
    if ( $action->attributes->{Chained} ) {
        push( @roles, 'Chained' );
    }
    if (   $action->attributes->{ActionClass}
        && ($action->attributes->{ActionClass}->[0] eq 'Catalyst::Action::REST'
        || $action->attributes->{ActionClass}->[0] eq 'CatalystX::Action::ExtJS::REST') )
    {
        push( @roles, 'REST' );
    }
    if (   $action->name eq 'object'
        && $action->class->isa('CatalystX::Controller::ExtJS::REST') )
    {
        push( @roles, 'REST::ExtJS' );
    }
    @roles =
      map { $_ = 'CatalystX::Controller::ExtJS::Direct::Route::' . $_ } @roles;
    my $anon_class = Moose::Meta::Class->create_anon_class(
        superclasses => [qw(CatalystX::Controller::ExtJS::Direct::Route)],
        ( @roles ? ( roles => [@roles] ) : () ),
        cache => 1,
    );
    return $anon_class->find_method_by_name('build')
      ->execute( $anon_class->name, $params );

}

1;
