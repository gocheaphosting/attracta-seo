#	Cpanel::ThirdParty::Attracta::AttractaAPI::Updates.pm
#	Created by Attracta Online Services, Inc. http://attracta.com
#	Copyright (c) 2013 Attracta. All rights reserved. Copying is prohibited
#	The following code is subject to the General Embedded License Agreement for Use With Attracta
#	This license can be found at /usr/local/cpanel/3rdparty/attracta/LICENSE
#	Unauthorized use is prohibited

package Cpanel::ThirdParty::Attracta::AttractaAPI::Updates;

use strict;
use Cpanel::Logger                                 ();
use Cpanel::ThirdParty::Attracta::AttractaAPI      ();
use Cpanel::ThirdParty::Attracta::FastInclude      ();
use Cpanel::ThirdParty::Attracta::Server::Ethernet ();
use Cpanel::ThirdParty::Attracta::Server::Id::Load ();
use Cpanel::ThirdParty::Attracta::Updates::Config  ();
use Cpanel::ThirdParty::Attracta::Version          ();

my $logger = Cpanel::Logger->new();


#
#
#	Consider backwards compatibility with older auto update versions before changing an API functionality
#
#

sub check {

    my ( $plugin_updates, $fi_updates ) = Cpanel::ThirdParty::Attracta::Updates::Config::get_update_values();
    my $server_id = Cpanel::ThirdParty::Attracta::Server::Id::Load::load() || '-';

    my $response = Cpanel::ThirdParty::Attracta::AttractaAPI::sendRequest(
        { format => 'xml', location => '/rpc/api/webhost' },
        (
            do            => 'update-check',
            platform      => 'cpanel',
            serverId      => $server_id,
            fiVersion     => Cpanel::ThirdParty::Attracta::Version::getFI() || '-',
            pluginUpdates => $plugin_updates,
            fiUpdates     => $fi_updates,
            ip            => Cpanel::ThirdParty::Attracta::Server::Ethernet::getIP() || '-',
            macaddress    => Cpanel::ThirdParty::Attracta::Server::Ethernet::getMac() || '-',
            hostname      => Cpanel::ThirdParty::Attracta::Server::Ethernet::getHostname() || '-',
            ami           => Cpanel::ThirdParty::Attracta::FastInclude::isEnabled() || 0
        )
    );

    if ( ref($response) eq 'Cpanel::ThirdParty::Attracta::AttractaAPI::Response' ) {

        if ( !$response->has_errored() ) {
            if ( $response->{response}->{'updates-available'} ) {
                if ( $response->{response}->{'updates-available'}->{content} == 1 ) {
                    return ( 1, 'Updates are available for this server.' );
                }
                else {
                    return ( 0, 'No updates are available for this server.' );
                }
            }
            else {
                return ( 0, 'Unable to obtain update status from the Attracta API. Server ID: ' . $server_id );
            }
        }
        else {
            return (
                0,
                'Unable to check for updates. Error: ' . $response->print_errors()
            );
        }
    }
    else {
        return ( 0, 'Unable to contact update server: api-cpanel.attracta.com' );
    }
}

sub get {

    my ( $plugin_updates, $fi_updates ) = Cpanel::ThirdParty::Attracta::Updates::Config::get_update_values();
    my $server_id = Cpanel::ThirdParty::Attracta::Server::Id::Load::load() || '-';

    my $response = Cpanel::ThirdParty::Attracta::AttractaAPI::sendRequest(
        { format => 'xml', location => '/rpc/api/webhost' },
        (
            do            => 'update-get',
            platform      => 'cpanel',
            serverId      => $server_id,
            fiVersion     => Cpanel::ThirdParty::Attracta::Version::getFI() || '-',
            pluginUpdates => $plugin_updates,
            fiUpdates     => $fi_updates,
            ip            => Cpanel::ThirdParty::Attracta::Server::Ethernet::getIP() || '-',
            macaddress    => Cpanel::ThirdParty::Attracta::Server::Ethernet::getMac() || '-',
            hostname      => Cpanel::ThirdParty::Attracta::Server::Ethernet::getHostname() || '-',
            ami           => Cpanel::ThirdParty::Attracta::FastInclude::isEnabled() || 0
        )
    );

    if ( ref($response) eq 'Cpanel::ThirdParty::Attracta::AttractaAPI::Response' ) {
        if ( !$response->has_errored() ) {
            if ( $response->{response}->{updates} ) {
                my @downloads = ();

                if ( ref( $response->{response}->{updates}->{update} ) eq 'HASH' ) {
                    my $download = {
                        loc => $response->{response}->{updates}->{update}->{loc}->{content},
                        sig => $response->{response}->{updates}->{update}->{sig}->{content}
                    };
                    push( @downloads, $download );
                }
                elsif ( ref( $response->{response}->{updates}->{update} ) eq 'ARRAY' ) {
                    foreach my $update ( @{ $response->{response}->{updates}->{update} } ) {
                        my $download = {
                            loc => $update->{loc}->{content},
                            sig => $update->{sig}->{content}
                        };
                        push( @downloads, $download );
                    }
                }
                else {
                    return ( 0, 'Unable to find available updates from API response.' );
                }

                return ( 1, \@downloads );
            }
            else {
                return ( 0, 'Unable to obtain update status from the Attracta API. Server ID: ' . $server_id );
            }
        }
        else {
            return (
                0,
                'Unable to check for updates. Error: ' . $response->print_errors()
            );
        }
    }
    else {
        return ( 0, 'Unable to contact update server: api-cpanel.attracta.com' );
    }
}

1;
