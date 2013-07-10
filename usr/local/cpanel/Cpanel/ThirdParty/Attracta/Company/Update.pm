#	Cpanel::ThirdParty::Attracta::Company::Update.pm
#	Created by Attracta Online Services, Inc. http://attracta.com
#	Copyright (c) 2013 Attracta. All rights reserved. Copying is prohibited
#	The following code is subject to the General Embedded License Agreement for Use With cPanel
#	This license can be found at /usr/local/cpanel/3rdparty/attracta/LICENSE
#	Unauthorized use is prohibited

package Cpanel::ThirdParty::Attracta::Company::Update;

use strict;
use Cpanel::ThirdParty::Attracta::AttractaAPI::Sites ();
use Cpanel::ThirdParty::Attracta::Company            ();

sub update_all_sites {
    my $user                = $_[0];
    my $reseller_email_hash = $_[1];
    my $server_id           = $_[2];

    my $company = Cpanel::ThirdParty::Attracta::Company->new( { user => $user } );

    #If the company has a valid Attracta user.config, update each site with this server's id
    if ( $company->get_config() ) {
        my $matched_sites = $company->get_matched_sites();
        exit if ( $matched_sites == 2 );
        if ( ref($matched_sites) eq 'ARRAY' ) {
            foreach my $attracta_site ( @{$matched_sites} ) {
                my $url    = $attracta_site->{url}->{content};
                my $siteId = $attracta_site->{siteid}->{content};
                my $key    = $attracta_site->{ajsa}->{content};

                #update server id
                Cpanel::ThirdParty::Attracta::AttractaAPI::Sites::update_site_serverid( $siteId, $key, $server_id );

                #update reseller email
                Cpanel::ThirdParty::Attracta::AttractaAPI::Sites::update_reseller_email( $user, $reseller_email_hash, $url );
            }
        }
    }
}

1;