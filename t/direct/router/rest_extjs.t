use Test::More;

use strict;
use warnings;

use HTTP::Request::Common;
use JSON::XS;
BEGIN { $ENV{DBIC_TRACE} = 1};
use lib qw(t/lib);

use Test::WWW::Mechanize::Catalyst 'MyApp';

my $mech = Test::WWW::Mechanize::Catalyst->new();
my $tid  = 1;

ok(
    my $api = MyApp->controller('API')->api,
    'get api directly from controller'
);

ok(
    $mech->request(
        POST $api->{url},
        Content_Type => 'application/json',
        Content      => q({"action":"User","method":"create","data":[{"rows":[{"name":"a","password":1},{"name":"m","password":1}]}],"type":"rpc","tid":6})
    ),
    'create users'
);

#count_users(2);

print $mech->content;


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
