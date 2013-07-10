#	Cpanel::ThirdParty::Attracta::Company::Config.pm
#	Created by Attracta Online Services, Inc. http://attracta.com
#	Copyright (c) 2013 Attracta. All rights reserved. Copying is prohibited
#	The following code is subject to the General Embedded License Agreement for Use With Attracta
#	This license can be found at /usr/local/cpanel/3rdparty/attracta/LICENSE
#	Unauthorized use is prohibited

package Cpanel::ThirdParty::Attracta::Company::Config;

use strict;
use Cpanel::CachedDataStore                        ();
use Cpanel::PwCache                                ();
use Cpanel::ThirdParty::Attracta::Validation ();

sub get {
    my $user = $_[0];
    my $url  = $_[1];

    my $homedir    = Cpanel::PwCache::gethomedir($user);
    my $configFile = $homedir . '/.attracta/user.config';

    my $configData = Cpanel::CachedDataStore::loaddatastore( $configFile, 0 );

    my $key =
      Cpanel::ThirdParty::Attracta::Validation::isKey( $configData->{data}->{key} )
      ? $configData->{data}->{key}
      : 0;

    my $userId =
      Cpanel::ThirdParty::Attracta::Validation::isInt( $configData->{data}->{userId} )
      ? $configData->{data}->{userId}
      : 0;

    my $sites = $configData->{data}->{sites};

    my $siteId;

    if ( ref($sites) eq 'HASH' ) {
        while ( my ( $key, $value ) = each( %{$sites} ) ) {
            if ( $value->{url} eq $url ) {
                $siteId = $value->{siteId};
            }
        }
    }
    elsif ( ref($sites) eq 'ARRAY' ) {
        foreach my $site ( @{$sites} ) {
            while ( my ( $key, $value ) = each( %{$sites} ) ) {
                if ( $value->{url} eq $url ) {
                    $siteId = $value->{siteId};
                }
            }
        }
    }

    my $config_data = {
        key    => $key,
        siteId => $siteId,
        userId => $userId
    };

    return $config_data;

}

1;
