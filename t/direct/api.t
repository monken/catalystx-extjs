use Test::More;

use strict;
use warnings;

use HTTP::Request::Common;
use JSON::XS;

use lib qw(t/lib);

use Test::WWW::Mechanize::Catalyst 'MyApp';

my $mech = Test::WWW::Mechanize::Catalyst->new();
$mech->add_header( 'Content-type' => 'application/json' );

my $api = {
    url     => '/api/router',
    type    => 'remote',
    actions => {
        Calculator => [
            { name => 'add',      len => 2 },
            { name => 'upload',   len => 0 },
            { name => 'subtract', len => 0 },
        ],
        REST => [
            { name => 'create',  len => 0 },
            { name => 'read',    len => 1 },
            { name => 'update',  len => 0 },
            { name => 'destroy', len => 1 },
        ],
        User => [
            { name => 'list',    len => 0 },
            { name => 'create',  len => 0 },
            { name => 'read',    len => 1 },
            { name => 'update',  len => 0 },
            { name => 'destroy', len => 1 },
        ],
        NestedController => [
            { name => 'index', len => 0 },
        ]
    }
};

is_deeply( MyApp->controller('API')->api,
    $api, 'get api directly from controller' );

$mech->get_ok( '/api', undef, 'get api via a request' );

ok( my $json = decode_json( $mech->content ), 'valid json' );

is_deeply( $json, $api, 'expected api' );

#print $mech->content;

done_testing;
