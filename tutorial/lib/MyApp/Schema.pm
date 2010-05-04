	package MyApp::Schema;
	use Moose;
	extends 'DBIx::Class::Schema';

	__PACKAGE__->load_namespaces;

	1;