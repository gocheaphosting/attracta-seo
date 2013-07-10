#!/usr/bin/perl
#	ensure_site_links.pl
#	Created by Attracta Online Services, Inc. http://attracta.com
#	Copyright (c) 2013 Attracta. All rights reserved. Copying is prohibited
#	The following code is subject to the General Embedded License Agreement for Use With cPanel
#	This license can be found at /usr/local/cpanel/3rdparty/attracta/LICENSE
#	Unauthorized use is prohibited

BEGIN { unshift( @INC, '/usr/local/cpanel' ); }
use strict;
use Cpanel::ThirdParty::Attracta::Jobs::Server::Id ();

unless ( getpwuid($<) eq 'root' ) {
    print "This script may only be executed by root\n";
    exit;
}

print "Updating domains to new server id for proper revenue tracking\n";

my $result = Cpanel::ThirdParty::Attracta::Jobs::Server::Id::update_site_serverids();

if ( $result eq '200' ) {
    print "done.\n";
}
else {
    print "There was an error updating sites: Error code: $result\n. Please contact support.attracta.com\n";
}
