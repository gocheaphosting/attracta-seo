#	Cpanel::ThirdParty::Attracta::Server::Id::Save.pm
#	Created by Attracta Online Services, Inc. http://attracta.com
#	Copyright (c) 2013 Attracta. All rights reserved. Copying is prohibited
#	The following code is subject to the General Embedded License Agreement for Use With Attracta
#	This license can be found at /usr/local/cpanel/3rdparty/attracta/LICENSE
#	Unauthorized use is prohibited

package Cpanel::ThirdParty::Attracta::Server::Id::Save;

use strict;
use Cpanel::CachedDataStore                        ();
use Cpanel::DAV::UUID                              ();
use Cpanel::FileUtils::TouchFile                   ();
use Cpanel::Logger                                 ();
use Cpanel::ThirdParty::Attracta::Version          ();
use Cpanel::ThirdParty::Attracta::Validation ();

my $logger = Cpanel::Logger->new();

sub generate {
    my $version = Cpanel::ThirdParty::Attracta::Server::Id::Save::set_length( Cpanel::ThirdParty::Attracta::Version::get() );

    my $serverId = $version . '-' . Cpanel::DAV::UUID::generate() . '-' . time();

    unless ( Cpanel::ThirdParty::Attracta::Validation::isServerIDUUID($serverId) ) {
        $logger->die('ATTRACTA-SEO - Could not generate server ID. Cannot use Attracta SEO Tools. Please contact Attracta support');
    }
    return $serverId;
}

sub save {
    my $serverId = $_[0];

    my $config_path = '/var/cpanel/attracta/';
    my $config_file = $config_path . 'server_info.conf';

    if ( Cpanel::ThirdParty::Attracta::Validation::existsDir($config_path) ) {
        if ( -f $config_file ) {
            chmod( 0600, $config_file );
        }
        else {
            Cpanel::FileUtils::TouchFile::touchfile( $config_file, 0600 );
        }

        my $result = Cpanel::CachedDataStore::savedatastore(
            $config_file,
            { 'data' => { serverId => $serverId } }
        );
        return $result;
    }
    else {
        return 0;
    }

}

sub set_length {
    my $version = $_[0];
    $version =~ s/\.//g;
    return ( '0' x ( 6 - length($version) ) . $version );
}

1;
