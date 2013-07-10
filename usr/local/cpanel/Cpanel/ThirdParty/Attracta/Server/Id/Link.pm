#	Cpanel::ThirdParty::Attracta::Server::Id::Link.pm
#	Created by Attracta Online Services, Inc. http://attracta.com
#	Copyright (c) 2013 Attracta. All rights reserved. Copying is prohibited
#	The following code is subject to the General Embedded License Agreement for Use With Attracta
#	This license can be found at /usr/local/cpanel/3rdparty/attracta/LICENSE
#	Unauthorized use is prohibited

package Cpanel::ThirdParty::Attracta::Server::Id::Link;

use strict;
use Cpanel::CachedDataStore      ();
use Cpanel::FileUtils::TouchFile ();
use Cpanel::Logger               ();
use Cpanel::PwCache              ();

my $logger = Cpanel::Logger->new();

sub save {
    my $partnerId = $_[0];

    unless ( getpwuid($<) eq 'root' ) {
        print "Only root can link servers\n";
        return 0;
    }

    my $configDir  = '/root/.attracta/';
    my $configFile = $configDir . 'reseller.config';

    if ( Cpanel::ThirdParty::Attracta::Validation::existsDir($configDir) ) {
        if ( -f $configFile ) {
            chmod( 0600, $configFile );
        }
        else {
            Cpanel::FileUtils::TouchFile::touchfile( $configFile, 0600 );
        }

        my $result = Cpanel::CachedDataStore::savedatastore(
            $configFile,
            { 'data' => { partnerId => $partnerId } }
        );
        chmod( 0600, $configFile );
        return $result;
    }
    else {
        return 0;
    }
}

sub load {
    my $configFile = '/root/.attracta/reseller.config';

    if ( -f $configFile ) {
        my $configData = Cpanel::CachedDataStore::loaddatastore( $configFile, 0 );

        if ($configData) {
            if ( $configData->{data} ) {
                if ( $configData->{data}->{partnerId} ) {
                    return $configData->{data}->{partnerId};
                }
                else {
                    $logger->warn( 'ATTRACTA-SEO: partner ID not found for server link: ' . $configFile );
                    return 0;
                }
            }
            else {
                $logger->warn( 'ATTRACTA-SEO: We expected to get config data from ' . $configFile . ' but we got no data' );
                return 0;
            }
        }
        else {
            $logger->warn( 'ATTRACTA-SEO: Could load data from ' . $configFile );
            return 0;
        }
    }
    else {
        return 0;
    }
}

1;
