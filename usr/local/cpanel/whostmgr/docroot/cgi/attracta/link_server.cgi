#!/usr/bin/perl
#	link_server.cgi
#	Created by Attracta Online Services, Inc. http://attracta.com
#	Copyright (c) 2013 Attracta. All rights reserved. Copying is prohibited
#	The following code is subject to the General Embedded License Agreement for Use With Attracta
#	This license can be found at /usr/local/cpanel/3rdparty/attracta/LICENSE
#	Unauthorized use is prohibited

BEGIN { unshift( @INC, '/usr/local/cpanel' ); }

use strict;
use warnings;
use CGI                                                   ();
use JSON::Syck                                          ();
use Cpanel::Logger                                        ();
use Cpanel::ThirdParty::Attracta::AttractaAPI::Server::Id ();
use Cpanel::ThirdParty::Attracta::Validation              ();
use Cpanel::ThirdParty::Attracta::Server::Id::Link        ();

my $logger = Cpanel::Logger->new();

print "Content-type: text/plain\nCache-control: no-cache\r\n\r\n";

my $status  = 0;
my $message = '';

if ( $ENV{'REMOTE_USER'} ne 'root' ) {
    print JSON::Syck::Dump( { status => 0, message => 'Not Authorized' } );
    exit;
}

my $cgi = CGI->new();

my $partnerID = Cpanel::ThirdParty::Attracta::Validation::isInt( $cgi->param('partnerid') ) ? $cgi->param('partnerid') : '';

if ( $partnerID eq '' ) {
    $message .= "Invalid or missing Attracta Partner ID\n";
}

if ( $message eq '' ) {

    #Link the server with Attracta
    my $partner_id = Cpanel::ThirdParty::Attracta::AttractaAPI::Server::Id::add( { partnerID => $partnerID } );

    if ( Cpanel::ThirdParty::Attracta::Validation::isInt($partner_id) ) {
        $status  = 1;
        $message = 'Server Linked with Attracta';

        #Save partner ID
        Cpanel::ThirdParty::Attracta::Server::Id::Link::save($partner_id);
    }
    else {
        $message = $partner_id;
    }
}
else {
    $logger->warn("ATTRACTA-SEO: Account Login Issue: $message \n");
}

print JSON::Syck::Dump( { status => $status, message => $message } );
exit;
