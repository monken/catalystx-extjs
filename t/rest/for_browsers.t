use Test::More tests => 3;

use strict;
use warnings;

use Test::WWW::Mechanize::Catalyst;

use lib qw(t/lib);

use TestSchema;

my $schema = TestSchema->connect;
$schema->deploy;

my $app = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'MyApp');