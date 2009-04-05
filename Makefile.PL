use inc::Module::Install;

name     'CatalystX-Controller-ExtJS';
all_from 'lib/CatalystX/Controller/ExtJS.pm';
author   'Moritz Onken <onken@netcubed.de>';
license  'perl';

build_requires 'Test::More';

auto_install;

WriteAll;

