#	Cpanel::ThirdParty::Attracta::Cpanel::LicenseInfo.pm
#	Created by Attracta Online Services, Inc. http://attracta.com
#	Copyright (c) 2013 Attracta. All rights reserved. Copying is prohibited
#	The following code is subject to the General Embedded License Agreement for Use With Attracta
#	This license can be found at /usr/local/cpanel/3rdparty/attracta/LICENSE
#	Unauthorized use is prohibited

package Cpanel::ThirdParty::Attracta::Cpanel::LicenseInfo;

BEGIN { unshift( @INC, '/usr/local/cpanel' ); }

use strict;
use Cpanel::ThirdParty::Attracta::Server::Ethernet ();
use Net::SSLeay                                    ();
use XML::Simple                                    ();

sub get {
    my $self = shift;

    #Add license info from verify.cpanel.net

    my $ip = Cpanel::ThirdParty::Attracta::Server::Ethernet::getIP();

    if ($ip) {
        my ( $page, $response, %reply_headers ) = Net::SSLeay::post_http(
            'verify.cpanel.net', 80, '/verifyFeed.cgi?xml=1&ip=' . $ip, '',
        );

        if ($page) {

            # get rid of root xml line
            $page =~ s/<xml.*//;
            my $verify = eval { XML::Simple::XMLin($page) };

            if ( ref($verify) eq 'HASH' ) {
                if ( $$verify{'license'} ) {
                    if ( ref( $$verify{'license'}{'attributes'} ) eq 'HASH' ) {
                        return $$verify{'license'}{'attributes'}{'company'};
                    }

                    if ( ref( $$verify{'license'}{'attributes'} ) eq 'ARRAY' ) {
                        return $$verify{'license'}{'attributes'}[-1]{'company'};

                    }
                }
            }
        }
    }

    return;
}

1;
