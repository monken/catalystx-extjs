package CatalystX::Controller::ExtJS::Direct::API;
# ABSTRACT: API and router controller for Ext.Direct
use Moose;
extends qw(Catalyst::Controller::REST);

use List::Util qw(first);
use JSON::XS;
use CatalystX::Controller::ExtJS::Direct::Route;

__PACKAGE__->config(
    
    action => {
        end    => { ActionClass => '+CatalystX::Action::ExtJS::Serialize' },
        index  => { Path        => undef },
        router => { Path        => 'router' },
        src => { Local => undef },
    },
    
    default => 'application/json'
    
);


has 'api' => ( is => 'rw', lazy_build => 1 );

has 'routes' => ( is => 'rw', isa => 'HashRef', default => sub { {} } );

has 'namespace' => ( is => 'rw' );

sub index { }

sub src {
    my ($self, $c) = @_;
    $c->res->body( 'var Ext_PROVIDER = ' . $self->encoded_api . ';' );
}

sub _build_api {
    my ($self) = @_;
    my $c      = $self->_app;
    my $data   = {};
    foreach my $name ( $c->controllers ) {
        my $controller = $c->controller($name);
        $name =~ s/:://;
        my $meta       = $controller->meta;
        next
          unless ( $controller->can('is_direct') || $meta->does_role('CatalystX::Controller::ExtJS::Direct') );
		my @methods;
        foreach my $method ( $controller->get_action_methods() ) {
			next
              unless ( my $action = $controller->action_for( $method->name ) );
            next unless ( exists $action->attributes->{Direct} );
            my @routes =
              CatalystX::Controller::ExtJS::Direct::Route::Factory->build(
                $c->dispatcher, $action );
            foreach my $route (@routes) {
                $self->routes->{$name}->{ $route->name } = $route;
                push( @methods, $route->build_api );
            }

        }
        $data->{$name} = [@methods];
    }
    return {
        url => $c->dispatcher->uri_for_action( $self->action_for('router') )
          ->as_string,
        type    => 'remoting',
        actions => $data
    };
}

sub encoded_api {
    my ( $self, $c ) = @_;
    return encode_json( $self->api );
}

sub router {
    my ( $self, $c ) = @_;
    my $reqs = ref $c->req->data eq 'ARRAY' ? $c->req->data : [ $c->req->data ];
    my $api    = $self->api;      # populates $self->routes
    my $routes = $self->routes;
    if ( keys %{ $c->req->body_params }
        && ( my $params = $c->req->body_params ) )
    {
        $reqs = [
            {
                map {
                    my $orig = $_;
                    $orig =~ s/^ext//;
                    ( lc($orig) => delete $params->{$_} )
                  } qw(extType extAction extMethod extTID extUpload)
            }
        ];
        if ( $params->{extData} ) {
			$reqs->[0]->{data} = decode_json( delete $params->{extData} );
		} else {
			$reqs->[0]->{data} = [{%$params}];
		}
    }
	
	my @requests;
	
	foreach my $req (@$reqs) {
        unless ( $req && $req->{action}
            && exists $routes->{ $req->{action} }
            && exists $routes->{ $req->{action} }->{ $req->{method} } )
        {
            $self->status_bad_request( $c, { message => 'method not found' } );
            return;
        }
		 my $route = $routes->{ $req->{action} }->{ $req->{method} };
		
		push(@requests, $route->prepare_request($req));

	}
	
    my @res;
	REQUESTS:
	foreach my $req (@requests) {
		$req->{data} = [$req->{data}] if(ref $req->{data} ne "ARRAY");

        my $route = $routes->{ $req->{action} }->{ $req->{method} };
		my $params = @{$req->{data}} && ref $req->{data}->[-1] eq 'HASH' ? $req->{data}->[-1] : undef;

		my $body;
		{
			local $c->{response} = $c->response_class->new({});
			local $c->{stash} = {};
			local $c->{request} = $c->req;
			
			$c->req->parameters($params);
			$c->req->body_parameters($params);
			my %req = $route->request($req);
			$c->req($c->request_class->new(%{$c->req}, %req));
            eval {
                $c->visit($route->build_url( $req->{data} ));
                my $response = $c->res;
				if ( $response->content_type eq 'application/json' ) {
                    my $json = decode_json( $response->body );
					$json = $json->{data} if(ref $json eq 'HASH' && exists $json->{success} && exists $json->{data});
					$body = $json;
				} else {
					$body = $response->body;
				}
            } or do {
				push(@res, { type => 'exception', tid => $req->{tid}, message => "$@" });
                next REQUESTS;
			};
			
			
		}

        my $res = { map { $_ => $req->{$_} } qw(action method tid type) };
	    $c->stash->{upload} = 1 if ( $req->{upload} );
        push( @res, { %$res, result => $body } );

    }
    $c->stash->{rest} = @res != 1 ? \@res : $res[0];

}

sub end {
    my ( $self, $c ) = @_;
    $c->stash->{rest} ||= $self->api;
}

1;

__END__

=head1 ACTIONS

=head2 rpc

Every request to the API is going to hit this action, since the API's url will point to this action. 

You can change the url to this action via the class configuration.

Example:
	
  package MyApp::Controller::API;
  __PACKAGE__->config( action => { rpc => { Path => 'callme' } } );
  1;
  
The router is now available at C<< /api/callme >>.
  
=head2 index

This action is called when you access the namespace of the API. It will load L</api> and return
the JSON encoded API to the client. Since this class utilizes L<Catalyst::Controller::REST> you
can specify a content type in the request header and get the API encoded accordingly.

=head1 METHODS

=head2 api

Returns the API as a HashRef.

Example:

  {
	url => '/api/router',
	type => 'remote',
	actions => {
		Calc => {
			methods => [
					{ name => 'add', len => 2 },
					{ name => 'subtract', len => 0 }
				]
		}
	}
  }

=head2 encoded_api

This method returns the JSON encoded API which is useful when you want to include the API in a JavaScript file.

Example:

  Ext.app.REMOTING_API = [% c.controller('API').encoded_api %];
  Ext.Direct.addProvider(Ext.app.REMOTING_API);
  
  Calc.add(1, 3, function(provider, response) {
	// process response
  });
