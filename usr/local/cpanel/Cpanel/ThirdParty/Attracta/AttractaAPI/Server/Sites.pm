#	Cpanel::ThirdParty::Attracta::AttractaAPI::Server::Sites.pm
#	Created by Attracta Online Services, Inc. http://attracta.com
#	Copyright (c) 2013 Attracta. All rights reserved. Copying is prohibited
#	The following code is subject to the General Embedded License Agreement for Use With Attracta
#	This license can be found at /usr/local/cpanel/3rdparty/attracta/LICENSE
#	Unauthorized use is prohibited

package Cpanel::ThirdParty::Attracta::AttractaAPI::Server::Sites;

use strict;
use Cpanel::Logger                                 ();
use Cpanel::ThirdParty::Attracta::AttractaAPI      ();
use Cpanel::ThirdParty::Attracta::Server::Ethernet ();
use Cpanel::ThirdParty::Attracta::Server::Id::Load ();

my $logger = Cpanel::Logger->new();

sub update {
    my $site_list = $_[0];

    my $username = getpwuid($<);

    unless ( $username eq 'root' ) {
        $logger->warn('ATTRACTA SEO: Only root can update the server\'s site list.');
        return 500;
    }

    my @params = (
        do         => 'update-server-sites',
        serverId   => Cpanel::ThirdParty::Attracta::Server::Id::Load::load(),
        macaddress => Cpanel::ThirdParty::Attracta::Server::Ethernet::getMac() || '-',
        sites      => $site_list
    );

    my $response = Cpanel::ThirdParty::Attracta::AttractaAPI::sendRequest( { format => 'xml', location => '/rpc/api/webhost' },, @params );

    if ( ref($response) eq 'Cpanel::ThirdParty::Attracta::AttractaAPI::Response' ) {
        if ( !$response->has_errored() ) {
            return 200;
        }
        else {
            return 599;
        }
    }
    else {
        return 503;
    }
}

1;
