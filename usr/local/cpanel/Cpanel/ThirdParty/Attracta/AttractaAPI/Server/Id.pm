#	Cpanel::ThirdParty::Attracta::AttractaAPI::Server::Id.pm
#	Created by Attracta Online Services, Inc. http://attracta.com
#	Copyright (c) 2013 Attracta. All rights reserved. Copying is prohibited
#	The following code is subject to the General Embedded License Agreement for Use With Attracta
#	This license can be found at /usr/local/cpanel/3rdparty/attracta/LICENSE
#	Unauthorized use is prohibited

package Cpanel::ThirdParty::Attracta::AttractaAPI::Server::Id;

use strict;
use Cpanel::Logger                                    ();
use Cpanel::ThirdParty::Attracta::AttractaAPI         ();
use Cpanel::ThirdParty::Attracta::Cpanel::LicenseInfo ();
use Cpanel::ThirdParty::Attracta::Validation          ();
use Cpanel::ThirdParty::Attracta::Server::Ethernet    ();
use Cpanel::ThirdParty::Attracta::Server::Id::Load    ();

my $logger = Cpanel::Logger->new();

sub add {
    my $password = shift;

    my $username = getpwuid($<);

    unless ( $username eq 'root' ) {
        $logger->warn('Cannot link server unless you are root.');
        return 'Only root user can link servers';
    }

    my @params = (
        do         => 'add-serverid',
        serverId   => Cpanel::ThirdParty::Attracta::Server::Id::Load::load(),
        hostname   => Cpanel::ThirdParty::Attracta::Server::Ethernet::getHostname() || '-',
        ipaddress  => Cpanel::ThirdParty::Attracta::Server::Ethernet::getIP() || '-',
        macaddress => Cpanel::ThirdParty::Attracta::Server::Ethernet::getMac() || '-',
        license    => Cpanel::ThirdParty::Attracta::Cpanel::LicenseInfo::get() ||'-'
    );

    #add with either partner ID or username and password
    if ( $password->{username} && $password->{password} ) {
        push( @params, username => $password->{username} );
        push( @params, password => $password->{password} );
    }
    else {
        push( @params, affiliateId => $password->{partnerID} );
    }

    my $response = Cpanel::ThirdParty::Attracta::AttractaAPI::sendRequest( { format => 'xml', location => '/rpc/api/webhost' },, @params );

    if ( ref($response) eq 'Cpanel::ThirdParty::Attracta::AttractaAPI::Response' ) {
        if ( !$response->has_errored() ) {
            if ( $response->{response}->{user} ) {
                return $response->{response}->{user}->{userid}->{content};
            }
            else {
                $logger->warn("ATTRACTA-SEO: Could not link server with Attracta. Bad API response returned\n");
                return "ATTRACTA-SEO: Could not link server with Attracta. Bad API response returned\n";
            }
        }
        else {
            $logger->warn( 'ATTRACTA-SEO: Could not link server with Attracta: ' . $response->print_errors() . "\n" );
            return 'ATTRACTA-SEO: Could not link server with Attracta: ' . $response->print_errors() . "\n";
        }
    }
    else {
        $logger->warn( "ATTRACTA-SEO: Could not link server with Attracta. API Error: " . $response . "\n" );
        return "ATTRACTA-SEO: Could not link server with Attracta. API Error: " . $response . "\n";
    }
}

sub update {
    my $current_server_id = $_[0] || '';
    my $new_server_id     = $_[1] || '';

    my @params = (
        do          => 'update-server-serverid',
        oldServerId => $current_server_id,
        newServerId => $new_server_id,
        macaddress  => Cpanel::ThirdParty::Attracta::Server::Ethernet::getMac() || '-'
    );

    my $response = Cpanel::ThirdParty::Attracta::AttractaAPI::sendRequest( { format => 'xml', location => '/rpc/api/webhost' }, @params );
    if ( ref($response) eq 'Cpanel::ThirdParty::Attracta::AttractaAPI::Response' ) {
        if ( $response->has_errored() ) {
            $logger->warn( "ATTRACTA-SEO: Unable to update server id to new style: " . $response->print_errors() );
            return 599;
        }
        else {
            return 200;
        }
    }
    else {
        return 503;
    }
}

1;

