use Test::More tests => 3;

BEGIN {
    use_ok('App::ZofCMS::Plugin::Base');
    use_ok('HTML::Entities');
	use_ok( 'App::ZofCMS::Plugin::DBIPPT' );
}

diag( "Testing App::ZofCMS::Plugin::DBIPPT $App::ZofCMS::Plugin::DBIPPT::VERSION, Perl $], $^X" );
