#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'UbuntuOne' ) || print "Bail out!\n";
}

diag( "Testing UbuntuOne $UbuntuOne::VERSION, Perl $], $^X" );
