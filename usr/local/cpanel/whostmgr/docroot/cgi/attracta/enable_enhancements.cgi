#!/usr/bin/perl
#	enable_enhancements.cgi
#	Created by Attracta Online Services, Inc. http://attracta.com
#	Copyright (c) 2013 Attracta. All rights reserved. Copying is prohibited
#	The following code is subject to the General Embedded License Agreement for Use With Attracta
#	This license can be found at /usr/local/cpanel/3rdparty/attracta/LICENSE
#	Unauthorized use is prohibited

BEGIN { unshift( @INC, '/usr/local/cpanel' ); }

use strict;
use JSON::Syck                                     ();
use Cpanel::ThirdParty::Attracta::FastInclude        ();
use Cpanel::ThirdParty::Attracta::FastInclude::Setup ();

print "Content-type: text/plain\nCache-control: no-cache\r\n\r\n";

if ( $ENV{'REMOTE_USER'} ne 'root' ) {
    print JSON::Syck::Dump( { status => 0, message => 'Not Authorized' } );
    exit;
}

my $response = Cpanel::ThirdParty::Attracta::FastInclude::Setup::install();
if ($response) {
    Cpanel::ThirdParty::Attracta::FastInclude::enable();
    print JSON::Syck::Dump( { status => 1, message => 'Attracta Site Enhancements Enabled' } );
    exit;
}
else {
    print JSON::Syck::Dump(
        {
            status  => 0,
            message => 'Could not enable Attracta Site Enhancements. Check /usr/local/cpanel/logs/error_log for details'
        }
    );
    exit;
}

print JSON::Syck::Dump( { status => 0, message => 'Unknown Error' } );
