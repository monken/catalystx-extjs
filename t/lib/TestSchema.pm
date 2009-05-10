package
  TestSchema;
  
use strict;
use warnings;

use Path::Class::File;

use base 'DBIx::Class::Schema';

__PACKAGE__->load_namespaces;

sub connect {
    my $db = Path::Class::File->new('t/var/test.db');
    #$db->remove if(-e $db);
    return shift->next::method('dbi:SQLite:dbname=t/var/test.db');
}

1;