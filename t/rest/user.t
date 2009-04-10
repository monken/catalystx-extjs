use Test::More  tests => 16;

use strict;
use warnings;

use HTTP::Request::Common;
use JSON;

use lib qw(t/lib);

use Test::WWW::Mechanize::Catalyst 'MyApp';

my $mech = Test::WWW::Mechanize::Catalyst->new();

$mech->add_header('Accept' => 'application/json');

$mech->get_ok('/users', undef, 'request list of users');

ok(my $json = JSON::decode_json($mech->content), 'response is JSON response');

is($json->{results}, 0, 'no results');

$mech->request(POST '/user', [name => 'bar', password => 'foo']);

# POST issues a redirect because Controller::REST sets a Location header
# $mech follows this redirect to /user/1 but sends not the Accept header
# so we get an error on the catalyst console that the data could
# not be serialized.

$mech->get_ok('/users', undef, 'request list of users');

ok($json = JSON::decode_json($mech->content), 'response is JSON response');

is($json->{results}, 1, 'one results');

$mech->get_ok('/user/1', undef, 'get user 1');

ok($json = JSON::decode_json($mech->content), 'response is JSON response');

is($json->{data}->{name}, 'bar', 'user name is "bar"');

my $request = POST '/user/1', [name => 'bas', password => 'foo'];
$request->method('PUT');  # don't use PUT directly because it won't pick up the form parameters

ok($mech->request($request), 'change user name');

ok($json = JSON::decode_json($mech->content), 'response is JSON response');

is($json->{success}, 1, 'change was successful');

is($json->{data}->{name}, 'bas', 'user name has changed');

$mech->get_ok('/user/1', undef, 'get user 1');

ok($json = JSON::decode_json($mech->content), 'response is JSON response');

is($json->{data}->{name}, 'bas', 'user name has changed');