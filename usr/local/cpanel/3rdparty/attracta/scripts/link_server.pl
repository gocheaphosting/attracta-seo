#!/usr/bin/perl
#	link_server.pl
#	Created by David Koston (david@attracta.com) for Attracta (attracta.com)
#	Copyright (c) 2013 Attracta. All rights reserved. Copying is prohibited
#	The following code is subject to the General Embedded License Agreement for Use With Attracta
#	This license can be found at /usr/local/cpanel/3rdparty/attracta/LICENSE
#	Unauthorized use is prohibited

BEGIN { unshift( @INC, '/usr/local/cpanel' ); }

use strict;
use Cpanel::ThirdParty::Attracta::AttractaAPI::Server::Id ();
use Cpanel::ThirdParty::Attracta::Validation              ();
use Cpanel::ThirdParty::Attracta::Server::Id::Link        ();
use IPC::Open3                                            ();

my $partnerId = @ARGV ? join( ' ', @ARGV ) : '';
if ( !$partnerId ) {
    if ( -t STDIN ) {
        print "Enter your partner ID\n";
    }
    $partnerId = <STDIN>;
}
chomp($partnerId) if $partnerId;
unless ( Cpanel::ThirdParty::Attracta::Validation::isInt($partnerId) ) {
    print "Partner ID should be numeric\n";
    exit;
}

unless ( getpwuid($<) eq 'root' ) {
    print "Only root can link servers\n";
    exit;
}

#Link the server with Attracta
my $partner_id = Cpanel::ThirdParty::Attracta::AttractaAPI::Server::Id::add( { partnerID => $partnerId } );

if ( Cpanel::ThirdParty::Attracta::Validation::isInt($partner_id) ) {

    #Save partner ID
    Cpanel::ThirdParty::Attracta::Server::Id::Link::save($partner_id);
    print "Server linked with Attracta\n";

    #Update all sites to the proper server id
    print "Updating account links to ensure revenue tracking\n";
    my $pid = IPC::Open3::open3( my $wh, my $rh, my $eh, '/usr/local/cpanel/3rdparty/attracta/scripts/ensure_site_links.pl' );
    waitpid( $pid, 0 );
}
else {
    print "Unable to link server: $partner_id\n";
}
