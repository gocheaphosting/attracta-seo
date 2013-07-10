#!/usr/bin/perl
#	fix_icon_group_orders.pl
#	Created by David Koston (david@attracta.com) for Attracta (attracta.com)
#	Copyright (c) 2013 Attracta. All rights reserved. Copying is prohibited
#	The following code is subject to the General Embedded License Agreement for Use With Attracta
#	This license can be found at /usr/local/cpanel/3rdparty/attracta/LICENSE
#	Unauthorized use is prohibited

BEGIN {
    unshift( @INC, '/usr/local/cpanel' );
}

use strict;
use Cpanel::ThirdParty::Attracta::Cpanel::DynamicUI ();

#exit if not root
if ( $> != 0 ) {
    print "This script must be run by the root user.\n";
    exit(2);
}

Cpanel::ThirdParty::Attracta::Cpanel::DynamicUI::fix_group_orders();
