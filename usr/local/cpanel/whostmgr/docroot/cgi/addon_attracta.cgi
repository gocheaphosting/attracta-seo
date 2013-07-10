#!/usr/bin/perl
#WHMADDON:attracta:Attracta SEO and Marketing Tools
#	addon_attracta.cgi
#	Created by Attracta Online Services, Inc. http://attracta.com
#	Copyright (c) 2013 Attracta. All rights reserved. Copying is prohibited
#	The following code is subject to the General Embedded License Agreement for Use With cPanel
#	This license can be found at /usr/local/cpanel/3rdparty/attracta/LICENSE
#	Unauthorized use is prohibited

BEGIN { unshift( @INC, '/usr/local/cpanel' ); }

use strict;
use Cpanel::Logger                                     ();
use Cpanel::MagicRevision                              ();
use Cpanel::ThirdParty::Attracta::Cpanel::ContactEmail ();
use Cpanel::ThirdParty::Attracta::Validation           ();
use Cpanel::ThirdParty::Attracta::FastInclude          ();
use Cpanel::ThirdParty::Attracta::Server::Id::Link     ();
use Cpanel::ThirdParty::Attracta::Version              ();
use Template                                           ();
use Whostmgr::HTMLInterface                            ();

Whostmgr::HTMLInterface::defheader(' ');

my $logger = Cpanel::Logger->new();

my $template = Template->new( { INCLUDE_PATH => '/usr/local/cpanel/whostmgr/docroot/cgi/attracta/templates' } );


if ( $ENV{'REMOTE_USER'} eq 'root' ) {
    my $vars = {
        ami             => Cpanel::ThirdParty::Attracta::FastInclude::isEnabled(),
        cpanel_local_js => Cpanel::MagicRevision::calculate_magic_url('/cjt/cpanel-all-min.js'),
        version         => Cpanel::ThirdParty::Attracta::Version::get()
    };

    my $partnerID = Cpanel::ThirdParty::Attracta::Server::Id::Link::load();
    if ( $partnerID && Cpanel::ThirdParty::Attracta::Validation::isInt($partnerID) ) {
        $vars->{'partnerID'} = $partnerID;
    }

    $template->process( 'index_root.tt', $vars ) || $logger->warn( 'cannot load template: ' . $template->error() );

}
else {
    my $vars = {
        cpanel_local_js => Cpanel::MagicRevision::calculate_magic_url('/cjt/cpanel-all-min.js'),
        version         => Cpanel::ThirdParty::Attracta::Version::get(),
        email           => Cpanel::ThirdParty::Attracta::Cpanel::ContactEmail::get()
    };
    $template->process( 'index_reseller.tt', $vars ) || $logger->warn( 'cannot load template: ' . $template->error() );
}
