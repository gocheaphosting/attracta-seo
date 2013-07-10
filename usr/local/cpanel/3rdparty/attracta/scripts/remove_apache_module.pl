#!/usr/bin/perl
#	remove_apache_module.pl
#	Created by David Koston (david@attracta.com) for Attracta (attracta.com)
#	Copyright (c) 2013 Attracta. All rights reserved. Copying is prohibited
#	The following code is subject to the General Embedded License Agreement for Use With Attracta
#	This license can be found at /usr/local/cpanel/3rdparty/attracta/LICENSE
#	Unauthorized use is prohibited

BEGIN { unshift( @INC, '/usr/local/cpanel' ); }

use strict;
use Cpanel::ThirdParty::Attracta::FastInclude::Setup ();


unless ( getpwuid($<) eq 'root' ) {
    print "This script may only be executed by root\n";
    exit;
}


my $response = Cpanel::ThirdParty::Attracta::FastInclude::Setup::remove();
if ($response) {
    print "mod_fastinclude removed\n";
}
else {
    print "Could not remove mod_fastinclude. Check /usr/local/cpanel/logs/error_log for details\n";
}
