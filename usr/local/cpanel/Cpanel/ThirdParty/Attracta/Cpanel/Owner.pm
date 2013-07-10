#	Cpanel::ThirdParty::Attracta::Cpanel::Owner.pm
#	Created by Attracta Online Services, Inc. http://attracta.com
#	Copyright (c) 2013 Attracta. All rights reserved. Copying is prohibited
#	The following code is subject to the General Embedded License Agreement for Use With Attracta
#	This license can be found at /usr/local/cpanel/3rdparty/attracta/LICENSE
#	Unauthorized use is prohibited

package Cpanel::ThirdParty::Attracta::Cpanel::Owner;

use strict;
use Cpanel::AcctUtils::DomainOwner           ();
use Cpanel::Logger                           ();
use Cpanel::ThirdParty::Attracta::Validation ();

my $logger = Cpanel::Logger->new();

sub get {
    my $site_url = $_[0];
    my $domain;

    if ( Cpanel::ThirdParty::Attracta::Validation::isURL($site_url) ) {
        $domain = Cpanel::ThirdParty::Attracta::Validation::parseSiteURL($site_url);
    }
    elsif ( Cpanel::ThirdParty::Attracta::Validation::isDomain($site_url) ) {
        $domain = $site_url;
    }

    if ($domain) {
        my $owner = Cpanel::AcctUtils::DomainOwner::getdomainowner($domain);

        if ( Cpanel::ThirdParty::Attracta::Validation::isCpanelUsername($owner) && $owner ne 'root' ) {    #for some reason cPanel returns root if the domain is not found
            return $owner;
        }
        else {
            $logger->warn("ATTRACTA-SEO: Unable to get site owner for $domain. Maybe that site is not on this server");
            return 404;
        }
    }
    else {
        $logger->warn("ATTRACTA-SEO: Unable to get site owner. Invalid site passed");
        return 400;
    }
}

1;
