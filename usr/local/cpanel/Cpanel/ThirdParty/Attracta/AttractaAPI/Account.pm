#	Cpanel::ThirdParty::Attracta::AttractaAPI::Account.pm
#	Created by Attracta Online Services, Inc. http://attracta.com
#	Copyright (c) 2013 Attracta. All rights reserved. Copying is prohibited
#	The following code is subject to the General Embedded License Agreement for Use With Attracta
#	This license can be found at /usr/local/cpanel/3rdparty/attracta/LICENSE
#	Unauthorized use is prohibited

package Cpanel::ThirdParty::Attracta::AttractaAPI::Account;

use strict;
use Cpanel::Logger                                    ();
use Cpanel::ThirdParty::Attracta::AttractaAPI         ();
use Cpanel::ThirdParty::Attracta::Cpanel::Reseller    ();
use Cpanel::ThirdParty::Attracta::Cpanel::LicenseInfo ();
use Cpanel::ThirdParty::Attracta::Validation          ();
use Cpanel::ThirdParty::Attracta::Server              ();
use Cpanel::ThirdParty::Attracta::Server::Ethernet    ();

my $logger = Cpanel::Logger->new();

sub create {
    my $cpanel_user = $_[0];
    my $email       = $_[1];

    unless ($email) {
        return ( 0, 'No Email address provided' );
    }

    if ( Cpanel::ThirdParty::Attracta::Validation::isEmail($email) ) {

        my $resellerInfo = Cpanel::ThirdParty::Attracta::Cpanel::Reseller::getResellerInfo($cpanel_user) || {};

        my @params = (
            do             => 'create-account',
            name           => '-',
            email          => $email || '-',
            firstName      => '-',
            lastName       => '-',
            phone          => '-',
            serverId       => Cpanel::ThirdParty::Attracta::Server::getId() || '-',
            macaddress     => Cpanel::ThirdParty::Attracta::Server::Ethernet::getMac() || '-',
            resellerEmail  => $resellerInfo->{email} || '-',
            resellerDomain => $resellerInfo->{domain} || '-',
            license        => Cpanel::ThirdParty::Attracta::Cpanel::LicenseInfo::get() || '-',
            bundle         => 'Y',
            linuxuser      => $ENV{'REMOTE_USER'} || '-',
			requiretos     => 1	#hooks any modifying action in portal to require an accepted TOS before acting
        );

        my $response = Cpanel::ThirdParty::Attracta::AttractaAPI::sendRequest( { format => 'xml', location => '/rpc/api/webhost' }, @params );

        if ( ref($response) eq 'Cpanel::ThirdParty::Attracta::AttractaAPI::Response' ) {
            if ( !$response->has_errored() ) {
                if ( $response->{response} ) {

                    if ( $response->{response}->{company} ) {
                        my $configData = {
                            companyId => $response->{response}->{company}->{companyid}->{content},
                            key       => $response->{response}->{user}->{key}->{content},
                            userId    => $response->{response}->{user}->{userid}->{content},
                            username  => $response->{response}->{user}->{username}->{content}
                        };

                        return ( 1, $configData );
                    }
                    else {
                        return ( 0, 'Unable to create SEO Tools account. Please contact support. ' . $response->print_errors() );
                    }
                }
                else {
                    $logger->warn("ATTRACTA-SEO: could not register company with Attracta. No company info returned");
                    return (
                        0,
                        'Unable to create SEO Tools account. Invalid response from registration API.'
                    );
                }
            }
            else {
                if ( $response->{'response'}->{'errors'}->{'error'}->{'message'}->{'content'} =~ /Email Address Already Exists/ ) {
                    return ( 3, 'Email Address Already Exists' );
                }
                else {
                    $logger->warn( 'ATTRACTA-SEO: Error from SEO API ' . $response->print_errors() );
                    return ( 0, 'Unable to create SEO Tools account. Error: ' . $response->print_errors() );
                }
            }
        }
        else {
            $logger->warn( "ATTRACTA-SEO: Could not create account. API Error: " . $response );
            return (
                0,
                'Unable to create SEO Tools account. There was an API error.'
            );
        }
    }
    else {
        return ( 0, 'Please enter a valid email address' );
    }
}

sub get {
    my $password = $_[0];

    my @params = (
        do       => 'get-user',
        username => $password->{username},
        password => $password->{password}
    );

    my $response = Cpanel::ThirdParty::Attracta::AttractaAPI::sendRequest( { format => 'xml', location => '/rpc/api/webhost' }, @params );

    if ( ref($response) eq 'Cpanel::ThirdParty::Attracta::AttractaAPI::Response' ) {
        if ( !$response->has_errored() ) {
            if ( $response->{response}->{company} ) {
                return $response->{response};
            }
            else {
                $logger->warn("ATTRACTA-SEO: could not login to Attracta account");
                return -1;
            }
        }
        else {
            $logger->warn( 'ATTRACTA-SEO: Error from SEO API ' . $response->print_errors() );
            return $response->print_errors();
        }
    }
    else {
        $logger->warn( "ATTRACTA-SEO: Could not login to Attracta account. API Error: " . $response );
        return -1;
    }

}

sub reset_pass {
    my $username = $_[0];

    my @params = (
        do    => 'reset-password',
        email => $username
    );

    my $response = Cpanel::ThirdParty::Attracta::AttractaAPI::sendRequest( { format => 'xml', location => '/rpc/api/webhost' }, @params );

    if ( ref($response) eq 'Cpanel::ThirdParty::Attracta::AttractaAPI::Response' ) {
        if ( !$response->has_errored() ) {
            if ( $response->{response}->{response} ) {
                if ( $response->{response}->{response}->{success} ) {
                    if ( $response->{response}->{response}->{success}->{content} == 1 ) {
                        return ( 1, 'Password Reset' );
                    }
                    else {
                        return ( 0, 'Password could not be reset' );
                    }
                }
                else {
                    $logger->warn("ATTRACTA-SEO: could not reset password");
                    return ( 0, 'Password not reset' );
                }
            }
            else {
                $logger->warn("ATTRACTA-SEO: could not reset password");
                return ( 0, 'Password not reset' );
            }
        }
        else {
            $logger->warn( 'ATTRACTA-SEO: Could not reset password ' . $response->print_errors() );
            return ( 0, $response->print_errors() );
        }
    }
    else {
        $logger->warn( "ATTRACTA-SEO: Could not reset account password. API Error: " . $response );
        return ( 0, 'Unable to reset password. Could not connect to Attracta API' );
    }

}
1;
