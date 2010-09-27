use Test::More;

use strict;
use warnings;

use HTTP::Request::Common;
use JSON::XS qw(decode_json);

use lib qw(t/lib);

use Test::WWW::Mechanize::Catalyst 'MyApp';

my $mech = Test::WWW::Mechanize::Catalyst->new();
$mech->add_header( 'Content-type' => 'application/json' );

my $api = {
    url     => '/api/router',
    type    => 'remoting',
    actions => {
        JSON => [
            { name => 'index', len => 0 },
        ],
        Calculator => [
            { name => 'add',      len => 2 },
            { name => 'upload',   len => 0 },
            { name => 'subtract', len => 0 },
        ],
        REST => [
            { name => 'create',  len => 2 },
            { name => 'read',    len => 2 },
            { name => 'update',  len => 2 },
            { name => 'destroy', len => 2 },
            { name => 'submit', len => 0, formHandler => \1 },
        ],
        User => [
            { name => 'create',  len => 1 },
            { name => 'read',    len => 1 },
            { name => 'update',  len => 1 },
            { name => 'destroy', len => 1 },
            { name => 'submit', len => 0, formHandler => \1 },
            { name => 'list',    len => 1 },
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

# fix formHandler
$api->{actions}{User}[4]{formHandler} = 'true';
$api->{actions}{REST}[4]{formHandler} = 'true';

is_deeply( $json, $api, 'expected api' );

my $lens = 0;
my $content = $mech->content;
$lens++ while( $content =~ /"len":(\d+)/g );
is($lens, 16 );

# $api = MyApp->controller('API')->api;
# use Data::Dumper; print Dumper $api;

done_testing;
