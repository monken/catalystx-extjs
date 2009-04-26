use Test::More  tests => 2;

use strict;
use warnings;

use HTTP::Request::Common;
use JSON;

use lib qw(t/lib);

use Test::WWW::Mechanize::Catalyst 'MyApp';

my $mech = Test::WWW::Mechanize::Catalyst->new();

my $res = $mech->get('/skipend');

is($res->header('status'), 404, 'not found');

$mech->content_is('foo');