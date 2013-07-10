#	Cpanel::ThirdParty::Attracta::AttractaAPI::Sites.pm
#	Created by Attracta Online Services, Inc. http://attracta.com
#	Copyright (c) 2013 Attracta. All rights reserved. Copying is prohibited
#	The following code is subject to the General Embedded License Agreement for Use With Attracta
#	This license can be found at /usr/local/cpanel/3rdparty/attracta/LICENSE
#	Unauthorized use is prohibited

package Cpanel::ThirdParty::Attracta::AttractaAPI::Sites;

use strict;
use Cpanel::Logger                                 ();
use Cpanel::ThirdParty::Attracta::AttractaAPI      ();
use Cpanel::ThirdParty::Attracta::Company::Config  ();
use Cpanel::ThirdParty::Attracta::Company::Sites   ();
use Cpanel::ThirdParty::Attracta::Validation       ();
use Cpanel::ThirdParty::Attracta::Server           ();
use Cpanel::ThirdParty::Attracta::Server::Ethernet ();

my $logger = Cpanel::Logger->new();

sub add {
    my $config_data = $_[0];
    my $url         = $_[1];

    if ($config_data) {
        if ( Cpanel::ThirdParty::Attracta::Validation::isURL($url) ) {
            my $response = Cpanel::ThirdParty::Attracta::AttractaAPI::sendRequest(
                { format => 'xml', location => '/rpc/api/webhost' },
                (
                    do              => 'site-add',
                    url             => $url,
                    companyId       => $config_data->{companyId},
                    serverId        => Cpanel::ThirdParty::Attracta::Server::getId() || '-',
                    macaddress      => Cpanel::ThirdParty::Attracta::Server::Ethernet::getMac() || '-',
                    hostname        => Cpanel::ThirdParty::Attracta::Server::Ethernet::getHostname() || '-',
                    ipaddress       => Cpanel::ThirdParty::Attracta::Server::Ethernet::getIP() || '-',
                    robotsInstalled => 'N'
                )
            );
            if ( ref($response) eq 'Cpanel::ThirdParty::Attracta::AttractaAPI::Response' ) {
                if ( !$response->has_errored() ) {
                    Cpanel::ThirdParty::Attracta::Company::Sites::saveSite(
                        {
                            'siteId' => $response->{response}->{site}->{siteid}->{content},
                            'asja-key' =>
                              $response->{response}->{site}->{'asja-key'}->{content},
                            'url' => $url
                        }
                    );
                    return ( 1, $url . 'Added' );
                }
                else {
                    return (
                        0,
                        'Could not add site: ' . $url . '. Error: ' . $response->print_errors()
                    );
                }
            }
            else {
                return (
                    0,
                    'Could not add site: ' . $url . '. API Error: ' . $response
                );
            }
        }
        else {
            return ( 0, 'Could not add site. No URL provided' );
        }
    }
    else {
        $logger->warn("Could not add site to attracta: $url No account config data found");
        return ( 0, 'Could not add site: ' . $url . 'No config data found' );
    }
}

sub get {
    my $options = $_[0];

    if ( $options->{config} ) {
        my @sites = ();

        #this will be returning a Attracta::AttractaAPI::Response object
        my $response = Cpanel::ThirdParty::Attracta::AttractaAPI::sendRequest(
            { format => 'xml', location => '/rpc/api/webhost' },
            (
                do        => 'site-list',
                key       => $options->{config}->{'key'},
                companyId => $options->{config}->{'companyId'}
            )
        );

        if ( ref($response) eq 'Cpanel::ThirdParty::Attracta::AttractaAPI::Response' ) {
            if ( !$response->has_errored() ) {
                if ( $response->{response}->{company} ) {

                    #If the company is disabled, we stop here and show a notice in cPanel
                    unless ( $options->{disabled_ok} ) {
                        if ( $response->{response}->{company}->{disabled} ) {
                            if ( $response->{response}->{company}->{disabled}->{content} eq 'Y' ) {
                                return 2;
                            }
                        }
                    }

                    if ( $response->{response}->{company}->{sitecount} ) {
                        if ( $response->{response}->{company}->{sitecount}->{content} == 1 ) {
                            while ( my ( $key, $value ) = each %{ $response->{response}->{sites} } ) {
                                push( @sites, $value );
                            }
                            return \@sites;
                        }
                        else {
                            foreach my $site ( @{ $response->{response}->{sites}->{site} } ) {
                                push( @sites, $site );
                            }
                            return \@sites;
                        }
                    }
                    else {
                        return \@sites;
                    }
                }
                else {
                    $logger->warn("ATTRACTA-SEO: could not get list of sites from attracta API - no company info");
                    return 0;
                }
            }
            else {
                $logger->warn( 'ATTRACTA-SEO: Error from SEO API ' . $response->print_errors() );
                return 0;
            }

        }
        else {
            $logger->warn("ATTRACTA-SEO: could not get list of sites from attracta API. API Error $response");
            return 0;
        }
    }
    else {
        $logger->warn("ATTRACTA-SEO: could not get list of sites from attracta API - company config not found");
        return 0;
    }
}

sub update_reseller_email {
    my $domain_owner        = $_[0];
    my $reseller_email_hash = $_[1];
    my $url                 = $_[2];

    if ( Cpanel::ThirdParty::Attracta::Validation::isCpanelUsername($domain_owner) ) {

        #Get user's config data
        my $configData = Cpanel::ThirdParty::Attracta::Company::Config::get( $domain_owner, $url );

        if ( ref($configData) eq 'HASH' ) {

            #update the reseller email (one way hashed email)
            my $response = Cpanel::ThirdParty::Attracta::AttractaAPI::sendRequest(
                { format => 'xml', location => '/rpc/api/webhost' },
                (
                    do            => 'update-reseller-email',
                    siteId        => $configData->{siteId},
                    key           => $configData->{key},
                    userId        => $configData->{userId},
                    resellerEmail => $reseller_email_hash
                )
            );
        }
    }

}

sub update_site_serverid {
    my $site_id       = $_[0];
    my $key           = $_[1];
    my $new_server_id = $_[2];

    if (   Cpanel::ThirdParty::Attracta::Validation::isInt($site_id)
        && Cpanel::ThirdParty::Attracta::Validation::isKey($key)
        && Cpanel::ThirdParty::Attracta::Validation::isServerIDUUID($new_server_id) ) {

        my $response = Cpanel::ThirdParty::Attracta::AttractaAPI::sendRequest(
            { format => 'xml', location => '/rpc/api/webhost' },
            (
                do          => 'update-site-serverid',
                siteId      => $site_id,
                key         => $key,
                newServerId => $new_server_id,
                macaddress  => Cpanel::ThirdParty::Attracta::Server::Ethernet::getMac() || '-'
            )
        );
    }

}

1;
