use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'App::ZofCMS::Plugin::DBIPPT',
    license             => 'perl',
    dist_author         => q|'Zoffix <'zoffix@cpan.org'>|,
    dist_version_from   => 'lib/App/ZofCMS/Plugin/DBIPPT.pm',
    build_requires => {
        'Test::More' => 0,
    },
    build_recommends => {
        'App::ZofCMS::Test::Plugin' => '0.0104',
    },
    requires => {
        'App::ZofCMS::Plugin::Base' => 0.0103,
        'HTML::Entities'            => 1.35,
    },
    add_to_cleanup      => [ 'App-ZofCMS-Plugin-DBIPPT-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
