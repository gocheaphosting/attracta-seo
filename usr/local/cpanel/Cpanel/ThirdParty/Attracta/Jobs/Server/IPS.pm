#	Cpanel::ThirdParty::Attracta::Jobs::Server::IPS.pm
#	Created by David Koston (david@attracta.com) for Attracta (attracta.com)
#	Copyright (c) 2013 Attracta. All rights reserved. Copying is prohibited
#	The following code is subject to the General Embedded License Agreement for Use With Attracta
#	This license can be found at /usr/local/cpanel/3rdparty/attracta/LICENSE
#	Unauthorized use is prohibited

package Cpanel::ThirdParty::Attracta::Jobs::Server::IPS;

use strict;
use Cpanel::Ips                                            ();
use Cpanel::ThirdParty::Attracta::AttractaAPI::Server::IPS ();
use Cpanel::ThirdParty::Attracta::Validation               ();

sub get_ip_list {
    my $ip_list;

    my %IPS = Cpanel::Ips::fetchipslist();

    foreach my $key ( sort keys %IPS ) {
        $ip_list .= $key . ',';
    }
    $ip_list = substr( $ip_list, 0, -1 );    #remove last ,

    return $ip_list;
}

sub update {
    my $ip_list = Cpanel::ThirdParty::Attracta::Jobs::Server::IPS::get_ip_list();
    if ( Cpanel::ThirdParty::Attracta::Validation::isIPCSV($ip_list) ) {
        return Cpanel::ThirdParty::Attracta::AttractaAPI::Server::IPS::update($ip_list);
    }
    return 500;
}

1;
