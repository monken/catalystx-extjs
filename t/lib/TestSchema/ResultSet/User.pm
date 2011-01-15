package # hide
    TestSchema::ResultSet::User;

use base 'DBIx::Class::ResultSet';

use strict;
use warnings;

sub extjs_rest_user {
    my ($self, $c) = @_;
    return $self unless(my $ending = $c->req->params->{ending});
    return $self->search({ id => { LIKE => '%'.$ending }  });
}

sub hri {
    shift->search( undef, { result_class => 'DBIx::Class::ResultClass::HashRefInflator' } );
}

sub none {
    shift->search({ id => undef });
}

sub not {
    my ($self, $c, $not) = @_;
    $self->search({ id => { '!=' => $not } });
}

sub foo { shift }

1;