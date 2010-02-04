use Test::More;

use strict;
use warnings;

use HTTP::Request::Common;
use JSON;

use lib qw(t/lib);

use Test::WWW::Mechanize::Catalyst 'MyApp';

my $mech = Test::WWW::Mechanize::Catalyst->new();

ok($mech->request( GET '/requestclass/request_class'));

like($mech->content, qr/Class::MOP/);

ok($mech->request( POST '/requestclass/params?foo=bar', [qw(a b c d)]));

is_deeply(decode_json($mech->content), {params => { a => 'b', c => 'd', foo => 'bar'},body_params => { a => 'b', c => 'd'}, query_params => { foo => 'bar'}});

ok($mech->request(POST '/requestclass/params?foo=bar', [data => encode_json({qw(a b c d)})]));
    
is_deeply(decode_json($mech->content), {params => { a => 'b', c => 'd', foo => 'bar'},body_params => { a => 'b', c => 'd'}, query_params => { foo => 'bar'}});

done_testing;