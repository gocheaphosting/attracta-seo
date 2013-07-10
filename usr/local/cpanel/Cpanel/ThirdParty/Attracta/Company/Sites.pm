#	Cpanel::ThirdParty::Attracta::Company::Sites.pm
#	Created by Attracta Online Services, Inc. http://attracta.com
#	Copyright (c) 2012 Attracta. All rights reserved. Copying is prohibited
#	The following code is subject to the General Embedded License Agreement for Use With cPanel
#	This license can be found at /usr/local/cpanel/3rdparty/attracta/LICENSE
#	Unauthorized use is prohibited

package Cpanel::ThirdParty::Attracta::Company::Sites;

use strict;
use Cpanel::CachedDataStore ();
use Cpanel::PwCache         ();

sub saveSite {
    my $site = shift;

    my $homedir    = Cpanel::PwCache::gethomedir( $ENV{'REMOTE_USER'} );
    my $configfile = $homedir . '/.attracta/user.config';

    if ( my $localData = Cpanel::CachedDataStore::loaddatastore($configfile) ) {
        $localData->{data}->{sites}->{ $site->{siteId} } = $site;
        Cpanel::CachedDataStore::savedatastore(
            $configfile,
            { 'data' => $localData->{data} }
        );
    }
}

1;
