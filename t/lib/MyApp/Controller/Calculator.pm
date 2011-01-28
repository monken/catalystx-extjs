package
  MyApp::Controller::Calculator;
  
use Moose;

BEGIN { extends 'Catalyst::Controller' };
with 'CatalystX::Controller::ExtJS::Direct';

__PACKAGE__->config({ namespace => 'calc', action => { subtract => { Local => undef, Direct => undef } } });

sub add : Chained('/') : Path : CaptureArgs(1) {
	my($self,$c, $arg) = @_;
	$c->stash->{add} = $arg;
}

sub add_to : Chained('add') : PathPart('to') : Args(1) : Direct('add') {
	my($self,$c,$arg) = @_;
	$c->res->body( $c->stash->{add} + $arg );
}

sub subtract {
	my($self, $c) = @_;
}

sub upload : Path : Direct {
	my($self, $c) = @_;
	my $file = $c->req->upload('file')->slurp;
	$c->res->content_type('text/plain');
	$c->res->body( eval $file or die );
}

1;