use Test::More;

use strict;
use warnings;

use HTTP::Request::Common;
use JSON::XS;

use lib qw(t/lib);

use Test::WWW::Mechanize::Catalyst 'MyApp';

my $mech = Test::WWW::Mechanize::Catalyst->new();
my $tid  = 1;

ok(
    my $api = MyApp->controller('API')->api,
    'get api directly from controller'
);

is( $api->{url}, '/api/router' );

ok( $mech->get_ok('/add/8/to/9') );

is( $mech->content, '17', 'calculator works' );

ok( $mech->get( $api->{url} ) );

is( $mech->status, 400, 'bad request' );

my $request = {
    action => 'Calculator',
    method => 'add',
    data   => [ 1, 3 ],
    tid    => $tid,
    type   => 'rpc'
};

ok(
    $mech->request(
        POST $api->{url},
        Content_Type => 'application/json',
        Content      => encode_json($request)
    ),
    'get via json in body'
);

ok( my $json = decode_json( $mech->content ), 'response is valid json' );

is_deeply(
    $json,
    {
        action => 'Calculator',
        method => 'add',
        result => 4,
        tid    => $tid++,
        type   => 'rpc'
    },
    'expected response'
);

ok(
    $mech->request(
        POST $api->{url},
        [
            extAction => 'Calculator',
            extMethod => 'add',
            extData   => encode_json( [ 1, 3 ] ),
            extTID    => $tid,
            extType   => 'rpc'
        ]
    ),
    'get via body parameters'
);

ok( $json = decode_json( $mech->content ), 'response is valid json' );

is_deeply(
    $json,
    {
        action => 'Calculator',
        method => 'add',
        result => 4,
        tid    => $tid,
        type   => 'rpc'
    },
    'expected response'
);

my $requests = [
    map {
        { %$request, tid => $_ }
      } ( 1 .. 4 )
];
ok(
    $mech->request(
        POST $api->{url},
        Content_Type => 'application/json',
        Content      => encode_json($requests)
    ),
    'batched requests'
);

ok( $json = decode_json( $mech->content ), 'response is valid json' );

my $response = [
    map {
        {
            action => 'Calculator',
            method => 'add',
            result => 4,
            tid    => $_,
            type   => 'rpc'
        }
      } ( 1 .. 4 )
];
is_deeply( $json, $response, 'expected response' );

ok(
    $mech->request(
        POST $api->{url},
        Content_Type => 'form-data',
        Content      => [
            extAction => 'Calculator',
            extMethod => 'upload',
            extTID    => 9,
            extUpload => 'true',
            extType   => 'rpc',
            file      => [
                undef, 'calc.txt',
                'Content-Type' => 'text/plain',
                Content        => '4*8'
            ],
        ]
    ),
    'upload request'
);

is( $mech->content_type, 'text/html', 'content type is text/html' );

like( $mech->content, qr/<textarea>(.*)</, 'result enclosed in textarea' );
$mech->content =~ /<textarea>(.*)<\/textarea>/;
ok( $json = decode_json($1), 'response is valid json' );

is( $json->{result}, 32, 'eval calculator works' );

ok( $mech->request( POST '/rest/object/1' ), 'chained action is working' );

foreach my $action (qw(create read update destroy)) {
    ok(
        $mech->request(
            POST $api->{url},
            Content_Type => 'application/json',
            Content      => encode_json(
                {
                    action => 'REST',
                    method => $action,
                    data   => [1],
                    tid    => $tid,
                    type   => 'rpc'
                }
            )
        ),
        'rest interface: ' . $action
    );

    ok( my $json = decode_json( $mech->content ), 'response is valid json' );

    is_deeply(
        $json,
        {
            action => 'REST',
            method => $action,
            result => { action => $action },
            tid    => $tid++,
            type   => 'rpc'
        },
        'expected response'
    );
}

ok(
    $mech->request(
        POST $api->{url},
        [
            extAction => 'User',
            extMethod => 'create',
            extTID    => $tid,
            extType   => 'rpc',
            password  => 'foobar',
            name      => 'testuser',
        ]
    ),
    'create user'
);

ok( $json = decode_json( $mech->content ), 'response is valid json' );
is( ref $json->{result}, 'HASH', 'result is a hash' );

$json = count_users(1);

is_deeply(
    $json->{result}->{rows},
    [
        {
            'password' => 'foobar',
            'name'     => 'testuser',
            'id'       => 1
        },
    ]
);

ok(     $mech->request(
        POST $api->{url},
        Content_Type => 'application/json',
        Content      => encode_json(
            {
                action => 'User',
                method => 'read',
                data   => [],
                tid    => $tid,
                type   => 'rpc'
            }
        )
    ),
    'list users'
);


ok( $json = decode_json( $mech->content ), 'response is valid json' );
is( $json->{type}, 'rpc', 'type is rpc' );
is( $json->{result}->{results}, 1, 'one result' );
die $mech->content;

ok(
    $mech->request(
        POST $api->{url},
        [
            extAction => 'User',
            extMethod => 'update',
            extTID    => $tid,
            extType   => 'rpc',
            id => 1,
            password  => 'foobar2',
            name      => 'testuser',
        ]
    ),
    'change user'
);

ok( $json = decode_json( $mech->content ), 'response is valid json' );
is( ref $json->{result}, 'HASH', 'result is a hash' );

$json = count_users(1);

is_deeply(
    $json->{result}->{rows},
    [
        {
            'password' => 'foobar2',
            'name'     => 'testuser',
            'id'       => 1
        },
    ]
);

ok(
    $mech->request(
        POST $api->{url},
        Content_Type => 'application/json',
        Content      => encode_json(
            {
                action => 'User',
                method => 'destroy',
                data   => [1],
                tid    => $tid,
                type   => 'rpc'
            }
        )
    ),
    'delete user'
);

ok( $json = decode_json( $mech->content ), 'response is valid json' );
is( ref $json->{result}, 'HASH', 'result is a hash' );

count_users(0);




sub count_users {
	my $user = shift;
	ok(
		$mech->request(
			POST $api->{url},
			Content_Type => 'application/json',
			Content      => encode_json(
				{
					action => 'User',
					method => 'list',
					tid    => $tid,
					data   => [],
					type   => 'rpc',
				}
			)
		),
		'get list of users'
	);

	ok( my $_json = decode_json( $mech->content ), 'response is valid json' );
	is($_json->{result}->{results}, $user, $user . ' users');
	return $_json;

}

done_testing;
