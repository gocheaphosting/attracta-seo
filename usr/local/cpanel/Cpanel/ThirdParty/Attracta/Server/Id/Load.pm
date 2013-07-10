#	Cpanel::ThirdParty::Attracta::Server::Id::Load.pm
#	Created by Attracta Online Services, Inc. http://attracta.com
#	Copyright (c) 2013 Attracta. All rights reserved. Copying is prohibited
#	The following code is subject to the General Embedded License Agreement for Use With Attracta
#	This license can be found at /usr/local/cpanel/3rdparty/attracta/LICENSE
#	Unauthorized use is prohibited

package Cpanel::ThirdParty::Attracta::Server::Id::Load;

use strict;
use Cpanel::CachedDataStore                        ();
use Cpanel::ThirdParty::Attracta::Validation ();

my $logger = Cpanel::Logger->new();

sub load {
    my $config_file = '/var/cpanel/attracta/server_info.conf';

    if ( Cpanel::ThirdParty::Attracta::Validation::isFile($config_file) ) {
        my $configData = Cpanel::CachedDataStore::loaddatastore( $config_file, 0 );
        if ($configData) {
            if ( $configData->{data} ) {
                if ( $configData->{data}->{serverId} ) {
                    if ( Cpanel::ThirdParty::Attracta::Validation::isServerId( $configData->{data}->{serverId} ) ) {
                        return $configData->{data}->{serverId};
                    }
                    else {
                        $logger->warn( 'ATTRACTA-SEO: Invalid serverId from ' . $config_file );
                        return -1;
                    }
                }
                else {
                    $logger->warn( 'ATTRACTA-SEO: Could load serverId from ' . $config_file );
                    return -2;
                }
            }
            else {
                $logger->warn( 'ATTRACTA-SEO: Unable to load datastore' . $config_file );
                return -3;
            }
        }
        else {
            $logger->warn( 'ATTRACTA-SEO: Attracta server config file is not present ' . $config_file );
            return -4;
        }
    }
}

1;
