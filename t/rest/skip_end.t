use Test::More  tests => 4;

use strict;
use warnings;

use HTTP::Request::Common;
use JSON;

use lib qw(t/lib);

use Test::WWW::Mechanize::Catalyst 'MyApp';

my $mech = Test::WWW::Mechanize::Catalyst->new();

my $res = $mech->get('/skipend/form/edit_record');
is($res->header('status'), 200, 'status ok');
$mech->content_contains('MyApp.Forms.EditRecord.skipend_test', 'contains form name');
$mech->content_contains("this.rest_url = '/skipend/'", 'contains action');
$mech->content_contains('{"hideLabel":true,"name":"id","fieldLabel":null,"xtype":"textfield"},{"hideLabel":true,"name":"password","fieldLabel":null,"xtype":"textfield"},{"hideLabel":true,"name":"name","fieldLabel":null,"xtype":"textfield"}]', 'contains fields');
