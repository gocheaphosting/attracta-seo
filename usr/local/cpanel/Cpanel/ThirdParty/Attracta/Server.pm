#	Cpanel::ThirdParty::Attracta::Server::Id.pm
#	Created by Attracta Online Services, Inc. http://attracta.com
#	Copyright (c) 2013 Attracta. All rights reserved. Copying is prohibited
#	The following code is subject to the General Embedded License Agreement for Use With Attracta
#	This license can be found at /usr/local/cpanel/3rdparty/attracta/LICENSE
#	Unauthorized use is prohibited

package Cpanel::ThirdParty::Attracta::Server;

use strict;
use Cpanel::AdminBin                               ();
use Cpanel::ThirdParty::Attracta::Validation ();
use Cpanel::ThirdParty::Attracta::Cpanel::AdminBin ();

sub getId {
    my $serverid = Cpanel::ThirdParty::Attracta::Cpanel::AdminBin::parseAdminBinOutput( Cpanel::AdminBin::adminrun( 'attracta', 'GETSERVERID', 'null' ) );

    if ( Cpanel::ThirdParty::Attracta::Validation::isServerId($serverid) ) {
        return $serverid;
    }
    else {
        return 0;
    }
}

sub getMac {
    my $mac = Cpanel::ThirdParty::Attracta::Cpanel::AdminBin::parseAdminBinOutput( Cpanel::AdminBin::adminrun( 'attracta', 'GETMAC', 'null' ) );

    if ( Cpanel::ThirdParty::Attracta::Validation::isMacAddress($mac) ) {
        return $mac;
    }
    else {
        return 0;
    }
}

1;

__END__

#These subroutines are for data access from cPanel
#See Attracta::Server::Id for generating and saving server ids and loading as root
#See Attracta::Server::Ethernet for data access as root
