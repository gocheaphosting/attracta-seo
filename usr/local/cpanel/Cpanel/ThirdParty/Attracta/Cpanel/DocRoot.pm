#	Cpanel::ThirdParty::Attracta::Cpanel::DocRoot.pm
#	Created by Attracta Online Services, Inc. http://attracta.com
#	Copyright (c) 2013 Attracta. All rights reserved. Copying is prohibited
#	The following code is subject to the General Embedded License Agreement for Use With Attracta
#	This license can be found at /usr/local/cpanel/3rdparty/attracta/LICENSE
#	Unauthorized use is prohibited

package Cpanel::ThirdParty::Attracta::Cpanel::DocRoot;

use strict;
use Cpanel::Logger                              ();
use Cpanel::Config::userdata::Cache             ();
use Cpanel::ThirdParty::Attracta::Cpanel::Owner ();
use Cpanel::ThirdParty::Attracta::Validation    ();

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

    my $owner = Cpanel::ThirdParty::Attracta::Validation::isCpanelUsername( $_[1] ) ? $_[1] : '';

    if ($domain) {
        unless ($owner) {
            $owner = Cpanel::ThirdParty::Attracta::Cpanel::Owner::get($domain);
        }

        my $cache = Cpanel::Config::userdata::Cache::load_cache($owner);

        if ($cache) {
            if ( $cache->{$domain} ) {
                return @{ $cache->{$domain} }[4];
            }
            else {
                $logger->warn("ATTRACTA-SEO: Could not find document root for $domain. Does that domain exist on this server?");
                return 405;
            }
        }
        else {
            $logger->warn( "ATTRACTA-SEO: Could not find document root for $domain. Unabled to load user cache for: " . $owner );
            return 500;
        }
    }
    else {
        $logger->warn("ATTRACTA-SEO: Could not find document root. Invalid site data passed");
        return 400;
    }
}

1;
