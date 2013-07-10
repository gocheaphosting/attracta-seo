#	Cpanel::ThirdParty::Attracta::Cpanel::ContactEmail.pm
#	Created by Attracta Online Services, Inc. http://attracta.com
#	Copyright (c) 2013 Attracta. All rights reserved. Copying is prohibited
#	The following code is subject to the General Embedded License Agreement for Use With cPanel
#	This license can be found at /usr/local/cpanel/3rdparty/attracta/LICENSE
#	Unauthorized use is prohibited

package Cpanel::ThirdParty::Attracta::Cpanel::ContactEmail;

use strict;
use Cpanel::Config::LoadCpUserFile ();

sub get {
    my $user = $_[0] || $ENV{'REMOTE_USER'};
    my $cpuser_ref = Cpanel::Config::LoadCpUserFile::loadcpuserfile( $user );
    if ( ref($cpuser_ref) eq 'HASH' ) {
        return $cpuser_ref->{'CONTACTEMAIL'};
    }
    else {
        return 406;	#user not found
    }
}

1;
