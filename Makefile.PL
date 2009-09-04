use inc::Module::Install;

name     'CatalystX-ExtJS';
all_from 'lib/CatalystX/ExtJS.pm';
author   'Moritz Onken <onken@netcubed.de>';
license  'BSD';


requires 'Config::Any' => '0.17';
requires 'HTML::FormFu::ExtJS' => '0.07';
requires 'Path::Class';
requires 'HTML::Entities';
requires 'JSON';
requires 'Lingua::EN::Inflect';
requires 'Catalyst::Request::REST::ForBrowsers';
requires 'Catalyst::Runtime' => '5.8';
requires 'Catalyst::Model::DBIC::Schema';
requires 'DBIx::Class';
requires 'Catalyst::Action::RenderView';


test_requires 'Test::WWW::Mechanize::Catalyst';

build_requires 'Test::More';

auto_install;

tests_recursive( 't' );

WriteAll;

