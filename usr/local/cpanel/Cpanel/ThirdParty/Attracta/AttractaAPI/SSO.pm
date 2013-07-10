#	Cpanel::ThirdParty::Attracta::AttractaAPI::SSO.pm
#	Created by Attracta Online Services, Inc. http://attracta.com
#	Copyright (c) 2013 Attracta. All rights reserved. Copying is prohibited
#	The following code is subject to the General Embedded License Agreement for Use With Attracta
#	This license can be found at /usr/local/cpanel/3rdparty/attracta/LICENSE
#	Unauthorized use is prohibited

package Cpanel::ThirdParty::Attracta::AttractaAPI::SSO;

use strict;
use Cpanel::Logger                            ();
use Cpanel::ThirdParty::Attracta::AttractaAPI ();
use Cpanel::ThirdParty::Attracta::Validation  ();

my $logger = Cpanel::Logger->new();

sub get_sso_url {
    my $pageId      = $_[0];
    my $config_data = $_[1];    #Cpanel::ThirdParty::Attracta::Company->{config}

    my @sites;
    if ( Cpanel::ThirdParty::Attracta::Validation::isInt($pageId) ) {
        if ( ref($config_data) eq 'HASH' ) {
            my $response = Cpanel::ThirdParty::Attracta::AttractaAPI::sendRequest(
                { format => 'xml', location => '/rpc/api/webhost' },
                (
                    do     => 'sso-auth',
                    key    => $config_data->{'key'},
                    userId => $config_data->{'userId'}
                )
            );
            if ( !$response->has_errored() ) {
                if ( $response->{response} ) {
                    if ( $response->{response}->{'sso-auth'} ) {
                        if ( $response->{response}->{'sso-auth'}->{url} ) {
                            return $response->{response}->{'sso-auth'}->{url}->{content} . '&re=/link%3fid=' . $pageId;
                        }
                        else {
                            $logger->warn('ATTRACTA-SEO: could not get SSO URL from Attracta API - no url');
                            return 0;
                        }
                    }
                    else {
                        $logger->warn("ATTRACTA-SEO: could not SSO URL from Attracta API - no sso-auth");
                        return 0;
                    }
                }
                else {
                    $logger->warn('ATTRACTA-SEO: could not get SSO URL from Attracta API - no response');
                    return 0;
                }
            }
            else {
                $logger->warn( 'ATTRACTA-SEO: could not get SSO URL from Attracta API. Error: ' . $response->print_errors() );
                return 0;
            }
        }
        else {
            $logger->warn("ATTRACTA-SEO: could not get SSO URL from Attracta API - could not load company config");
            return 0;
        }
    }
    else {
        $logger->warn('ATTRACTA-SE0:  Invalid Page ID');
        return 0;
    }
}

1;
