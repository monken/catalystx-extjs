use inc::Module::Install;

name     'CatalystX-ExtJS';
all_from 'lib/CatalystX/ExtJS.pm';
author   'Moritz Onken <onken@netcubed.de>';
license  'BSD';


requires 'Catalyst::Action::RenderView';
requires 'Catalyst::Model::DBIC::Schema';
requires 'Catalyst::Request::REST::ForBrowsers';
requires 'Catalyst::Runtime' => '5.8';
requires 'Config::Any' => '0.17';
requires 'DBIx::Class';
requires 'HTML::Entities';
requires 'HTML::FormFu::ExtJS' => '0.07';
requires 'HTML::FormFu::Model::DBIC';
requires 'JSON';
requires 'Lingua::EN::Inflect';
requires 'Path::Class';


test_requires 'Test::WWW::Mechanize::Catalyst';

build_requires 'Test::More';

auto_install;

tests_recursive( 't' );

WriteAll;

