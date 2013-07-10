#	Cpanel::ThirdParty::Attracta::Jobs::Server::Sites.pm
#	Created by David Koston (david@attracta.com) for Attracta (attracta.com)
#	Copyright (c) 2013 Attracta. All rights reserved. Copying is prohibited
#	The following code is subject to the General Embedded License Agreement for Use With Attracta
#	This license can be found at /usr/local/cpanel/3rdparty/attracta/LICENSE
#	Unauthorized use is prohibited

package Cpanel::ThirdParty::Attracta::Jobs::Server::Sites;

use strict;
use Cpanel::Config::userdata::Cache                          ();
use Cpanel::ThirdParty::Attracta::AttractaAPI::Server::Sites ();
use Cpanel::ThirdParty::Attracta::Validation                 ();

sub get_site_list {
    my $site_list = 500;

    my $userdata = Cpanel::Config::userdata::Cache::load_cache();

    if ( ref($userdata) eq 'HASH' ) {
        my %SITES = %{$userdata};

        foreach my $key ( sort keys %SITES ) {
            $site_list .= 'http://' . $key . '/,';
        }
        $site_list = substr( $site_list, 0, -1 );    #remove last ,
    }
    else {
        $site_list = 511;
    }

    return $site_list;
}

sub update {
    my $site_list = Cpanel::ThirdParty::Attracta::Jobs::Server::Sites::get_site_list();

    if ( Cpanel::ThirdParty::Attracta::Validation::isInt($site_list) ) {
        return $site_list;
    }
    return Cpanel::ThirdParty::Attracta::AttractaAPI::Server::Sites::update($site_list);
}





1;

