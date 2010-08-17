use Test::More;

use strict;
use warnings;

use HTTP::Request::Common;
use File::Spec;
use JSON;

use lib qw(t/lib);

use TestSchema;
use MyApp;

my $schema = MyApp->model('DBIC')->schema;

foreach my $i (1..200) {
    ok($schema->resultset('User')->create({name => sprintf('%04d', $i), password => 'password'.sprintf('%04d', 200-$i)}));   
}

is($schema->resultset('User')->count, 200, '200 users in db');


use Test::WWW::Mechanize::Catalyst 'MyApp';

my $mech = Test::WWW::Mechanize::Catalyst->new();

$mech->add_header('Accept' => 'application/json');

$mech->get_ok('/users', undef, 'request list of users (/users)');

ok(my $json = JSON::decode_json($mech->content), 'response is JSON response');

is(@{$json->{data}}, 200, '200 data');

is($json->{results}, 200, '200 data');

$mech->get_ok('/user', undef, 'request list of users (/user)');

ok($json = JSON::decode_json($mech->content), 'response is JSON response');

is(@{$json->{data}}, 200, '200 data');

is($json->{results}, 200, '200 data');

$mech->get_ok('/users?start=10', undef, 'request list of users');

ok($json = JSON::decode_json($mech->content), 'response is JSON response');

is(@{$json->{data}}, 190, '190 data');

is($json->{results}, 200, '200 data');

$mech->get_ok('/users?start=10&limit=20', undef, 'request list of users');

ok($json = JSON::decode_json($mech->content), 'response is JSON response');

is(@{$json->{data}}, 20, '20 data');

is($json->{results}, 200, '200 data');

$mech->get_ok('/users?start=10&limit=20&sort=name', undef, 'request list of users');

ok($json = JSON::decode_json($mech->content), 'response is JSON response');

is(@{$json->{data}}, 20, '20 data');

is($json->{results}, 200, '200 data');

is($json->{data}->[0]->{name}, '0011', 'First row is user "0011"');

$mech->get_ok('/users?start=10&limit=20&sort=name&dir=desc', undef, 'request list of users');

ok($json = JSON::decode_json($mech->content), 'response is JSON response');

is($json->{data}->[0]->{name}, '0190', 'First row is user "0190"');

$mech->get_ok('/users?start=10&limit=20&sort=password&dir=asc', undef, 'request list of users');

ok($json = JSON::decode_json($mech->content), 'response is JSON response');

is($json->{data}->[0]->{name}, '0190', 'First row is user "0190"');

# custom options with validation

is(MyApp->controller('User')->list_options_file, File::Spec->catfile('t','root','lists','user_options.yml'));

$mech->get('/users?start=10&limit=20&sort=password&dir=asc&ending=1');

ok($json = JSON::decode_json($mech->content), 'response is JSON response');

is(@{$json->{errors}}, 1, 'one error found');

$mech->get_ok('/users?start=10&limit=20&sort=password&dir=ASC&ending=2', undef, 'get users which end with 2');

ok($json = JSON::decode_json($mech->content), 'response is JSON response');

is(@{$json->{data}}, 10, '10 users found');

map { ok($_->{name} =~ /2$/, 'user ends with 2') } @{$json->{data}};

done_testing;


