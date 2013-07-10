#	Cpanel::ThirdParty::Attracta::AttractaAPI::Campaign.pm
#	Created by Attracta Online Services, Inc. http://attracta.com
#	Copyright (c) 2013 Attracta. All rights reserved. Copying is prohibited
#	The following code is subject to the General Embedded License Agreement for Use With Attracta
#	This license can be found at /usr/local/cpanel/3rdparty/attracta/LICENSE
#	Unauthorized use is prohibited

package Cpanel::ThirdParty::Attracta::AttractaAPI::Campaign;

use strict;
use Cpanel::ThirdParty::Attracta::AttractaAPI      ();
use Cpanel::ThirdParty::Attracta::Server           ();
use Cpanel::ThirdParty::Attracta::Server::Ethernet ();

sub get {
    my $linux_user = $_[0] || $ENV{'REMOTE_USER'};

    my @params = (
        do         => 'get-user-campaign',
        serverId   => Cpanel::ThirdParty::Attracta::Server::getId() || '-',
        macaddress => Cpanel::ThirdParty::Attracta::Server::Ethernet::getMac() || '-',
        linuxuser  => $linux_user
    );

    my $response = Cpanel::ThirdParty::Attracta::AttractaAPI::sendRequest( { format => 'xml', location => '/rpc/api/webhost' }, @params );

    if ( ref($response) eq 'Cpanel::ThirdParty::Attracta::AttractaAPI::Response' ) {
        if ( !$response->has_errored() ) {
            if ( $response->{response}->{campaign} ) {
                return $response->{response}->{campaign}->{content};
            }
        }
    }
    return 0;
}

1;
