=head1 NAME

CatalystX::ExtJS::Tutorial::Direct

=head1 INTRODUCTION

Ext.Direct is an ExtJS component which creates classes and methods
according to an API provided by the server. 
These methods are used to communicate with the server in a Remote
Procedure Call fashion. 
This requires a router on the server side to route the requests to the
matching method.

L<CatalystX::Controller::ExtJS::Direct> will take care of creating the
API and an convenient way to include it in your web application
as well as providing a router which takes care of calling the correct
Catalyst actions when it comes to a request.

=head1 EXAMPLES

=head2 Building the Playground

In order to run the examples we need to bootstrap a Catalyst
application. 

First go to your working directory and run:

 # catalyst.pl MyApp

This will create a basic Catalyst application. Open up C<lib/MyApp.pm>
and add C<Unicode> 
to the list of plugins (after C<Static::Simple>). Next we need a model,
where we can store
our data. We will use L<DBIx::Class> as ORM which means we have to set
up a DBIC schema first.

Create the file C<lib/MyApp/Schema.pm> and paste the following:

	package MyApp::Schema;
	use Moose;
	extends 'DBIx::Class::Schema';

	__PACKAGE__->load_namespaces;

	1;

Now we need a result class which describes the a user object. Create
C<lib/MyApp/Schema/Result/User.pm>:

	package MyApp::Schema::Result::User;

	use strict;
	use warnings;

	use base qw(MyApp::Schema::Result);

	__PACKAGE__->table('user');

	__PACKAGE__->add_columns(
		qw(email first last)
	);

	1;
	
To glue the DBIC schema and Catalyst together we create a model called
C<MyApp::Model::DBIC>.
Paste the following in C<lib/MyApp/Model/DBIC.pm>:

	package MyApp::Model::DBIC;
	use Moose;
	extends 'Catalyst::Model::DBIC::Schema';

	__PACKAGE__->config({
		schema_class => 'MyApp::Schema',
		connect_info => ['dbi:SQLite:dbname=:memory:']
	});

	after BUILD => sub {
		my $self = shift;
		my $schema = $self->schema;
		$schema->deploy;
		$schema->resultset('User')->create({
		    email => 'onken@netcubed.de', 
		    first => 'Moritz', 
		    last => 'Onken'
		});
	};

	1;

Next we need a view. We will go with a Template::Alloy view which will
take care of rendering
the HTML and JavaScript sources. Create C<lib/MyApp/View/TT.pm> with:

	package MyApp::View::TT;
	use Moose;
	extends 'Catalyst::View::TT::Alloy';

	__PACKAGE__->config( {
			CATALYST_VAR => 'c',
			INCLUDE_PATH => [ MyApp->path_to( 'root', 'src' ) ]
		} );

	1;

The JavaScript sources should be generated through the view we just
created. For this to work, we
need a controller, which handles that. We can use the C<Root> controller
which was created when
we created C<MyApp>. Open up C<lib/MyApp/Controller/Root.pm> and change
the C<index> subroutine
to:

	sub index :Path :Args(0) { }

This removes the Catalyst welcome message and a request to </> will run
the C<index> template 
(which we will create later) via the TT view. Now we create a, action
which will route any
request to C</js/*> to the according template in C<root/src/js>.

	sub js : Path : Args {
		my ($self, $c, $template) = @_;
		$c->stash->{template} = $template;
	}

Last but not least we add the Direct controller. Create
C<lib/MyApp/Controller/API.pm> and paste:

	package MyApp::Controller::API;
	use Moose;
	extends q(CatalystX::Controller::ExtJS::Direct::API);
	1;

That's it. Let the games begin!
	
=head2 Calculator Example

Every controller which wants to add an action to the Ext.Direct API
needs to consume the 
L<CatalystX::Controller::ExtJS::Direct> role. Furthermore each action
which should be
accessible needs the C<Direct> attribute. This simple example adds two
numbers and returns
the result:

	package MyApp::Controller::Calculator;

	use Moose;
	BEGIN { extends 'Catalyst::Controller' };
	with 'CatalystX::Controller::ExtJS::Direct';

	sub add : Chained('/') : Path : CaptureArgs(1) {
		my($self,$c, $arg) = @_;
		$c->stash->{add} = $arg;
	}

	sub add_to : Chained('add') : PathPart('to') : Args(1) : Direct('add') {
		my($self,$c,$arg) = @_;
		$c->res->body( $c->stash->{add} + $arg );
	}

As you can see the C<add_to> action has the C<Direct> attribute attached
to it. 
By default the method's name for the API is the same as the action's
name.
In this case however we changed the name of the action to C<add> by
adding
this as parameter to the C<Direct> attribute.

Run the server (C<# script/myapp_server.pl -r>) and access
L<http://localhost:3000/api>.
You should see something like this:

 {
	url => '/api/router',
	type => 'remoting',
	actions => {
		Calculator => {
			methods => [
					{ name => 'add', len => 2 }
				]
		}
	}
 }

Now it's time to build some HTML and JavaScript. First of all we need to
extract the ExtJS
sources to C<root/static/ext/>. Now we build the file C<root/src/index>:

	<html>
	<head>
	<title>Ext.Direct and Catalyst</title>
	<link rel="stylesheet" type="text/css" href="/static/ext/resources/css/ext-all.css" />
	<script type="text/javascript" src="/static/ext/adapter/ext/ext-base.js"></script>
	<script type="text/javascript" src="/static/ext/ext-all-debug.js"></script>
	<script type="text/javascript" src="/api/src"></script>
	</head>
	<body>Hello World!</body>
	</html>
	
Fire up your favourite browser and open it's debugger. Type in the
command line:

	Calculator.add(3, 2, function(){alert()});
	
And watch the request and response.

=head2 REST