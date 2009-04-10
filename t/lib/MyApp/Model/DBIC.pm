package
  MyApp::Model::DBIC;

use base 'Catalyst::Model::DBIC::Schema';

__PACKAGE__->config({
    schema_class => 'TestSchema',
    connect_info => ['dbi:SQLite:dbname=t/var/test.db']
});

sub new {
    my $self = shift->next::method(@_);
    my $db = Path::Class::File->new('t/var/test.db');
    $db->remove if(-e $db);
    $self->schema->deploy;
    return $self;
}

1;