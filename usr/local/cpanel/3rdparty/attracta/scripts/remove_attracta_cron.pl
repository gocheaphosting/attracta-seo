#!/usr/bin/perl
#	remove_attracta_cron.pl
#	Created by Attracta Online Services, Inc. http://attracta.com
#	Copyright (c) 2013 Attracta. All rights reserved. Copying is prohibited
#	The following code is subject to the General Embedded License Agreement for Use With Attracta
#	This license can be found at /usr/local/cpanel/3rdparty/attracta/LICENSE
#	Unauthorized use is prohibited

BEGIN { unshift( @INC, '/usr/local/cpanel' ); }

use strict;
use Cpanel::ThirdParty::Attracta::Cron ();

unless ( getpwuid($<) eq 'root' ) {
    print "This script may only be executed by root\n";
    exit;
}


Cpanel::ThirdParty::Attracta::Cron::removeAttracta();    #Remove any attracta entries
