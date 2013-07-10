#	Cpanel::ThirdParty::Attracta::AttractaAPI::Reseller.pm
#	Created by Attracta Online Services, Inc. http://attracta.com
#	Copyright (c) 2013 Attracta. All rights reserved. Copying is prohibited
#	The following code is subject to the General Embedded License Agreement for Use With Attracta
#	This license can be found at /usr/local/cpanel/3rdparty/attracta/LICENSE
#	Unauthorized use is prohibited

package Cpanel::ThirdParty::Attracta::AttractaAPI::Reseller;

use strict;
use Cpanel::Logger                                 ();
use Cpanel::ThirdParty::Attracta::AttractaAPI      ();
use Cpanel::ThirdParty::Attracta::Validation       ();
use Cpanel::ThirdParty::Attracta::Server::Ethernet ();
use Cpanel::ThirdParty::Attracta::Server::Id::Load ();

my $logger = Cpanel::Logger->new();

#This call is only used in testing to create partner accounts to link servers to
sub create {
    my $email = shift;

    if ( Cpanel::ThirdParty::Attracta::Validation::isEmail($email) ) {
        my @params = (
            do             => 'create-account',
            name           => '-',
            email          => $email || '-',
            firstName      => '-',
            lastName       => '-',
            phone          => '-',
            serverId       => Cpanel::ThirdParty::Attracta::Server::Id::Load::load() || '-',
            resellerEmail  => '-',
            resellerDomain => '-',
            isverified     => 'Y',
            hostname       => Cpanel::ThirdParty::Attracta::Server::Ethernet::getHostname(),
            ipaddress      => Cpanel::ThirdParty::Attracta::Server::Ethernet::getIP(),
            macaddress     => Cpanel::ThirdParty::Attracta::Server::Ethernet::getMac()
        );

        if ( $ENV{'REMOTE_USER'} eq 'root' || getpwuid($<) eq 'root' ) {
            push( @params, isroot => '1' );
        }
        else {
            push( @params, isreseller => '1' );

        }
        my $response = Cpanel::ThirdParty::Attracta::AttractaAPI::sendRequest( { format => 'xml', location => '/rpc/api/webhost' },, @params );

        if ( ref($response) eq 'Cpanel::ThirdParty::Attracta::AttractaAPI::Response' ) {
            if ( !$response->has_errored() ) {
                if ( $response->{response}->{company} ) {
                    return $response->{response};
                }
                else {
                    $logger->warn("ATTRACTA-SEO: could not register company with Attracta. No company info returned");
                    return -1;
                }
            }
            else {
                $logger->warn( 'ATTRACTA-SEO: Error from SEO API ' . $response->print_errors() );
                return $response->print_errors();
            }
        }
        else {
            $logger->warn( "ATTRACTA-SEO: Could not create account. API Error: " . $response );
            return -1;
        }

    }
    else {
        $logger->warn( "ATTRACTA-SEO: Invalid email when trying to create SEO Tools account: " . $email );
        return 0;
    }
}

sub get {
    my $password = shift;

    my @params = (
        do       => 'get-reseller',
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
            if ( $response->{'response'}->{'error'}->{'message'}->{content} eq 'User Not Found' ) {
                return $response->{'response'}->{'error'}->{'message'}->{content} . ' or Password Incorrect';
            }
            else {
                return $response->{'response'}->{'error'}->{'message'}->{content};
            }
        }
    }
    else {
        $logger->warn( "ATTRACTA-SEO: Could not login to Attracta account. API Error: " . $response );
        return -1;
    }

}

1;
