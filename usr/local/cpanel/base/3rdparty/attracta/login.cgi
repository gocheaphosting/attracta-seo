#!/usr/bin/perl
#	login.cgi
#	Created by Attracta Online Services, Inc. http://attracta.com
#	Copyright (c) 2013 Attracta. All rights reserved. Copying is prohibited
#	The following code is subject to the General Embedded License Agreement for Use With Attracta
#	This license can be found at /usr/local/cpanel/3rdparty/attracta/LICENSE
#	Unauthorized use is prohibited

BEGIN { unshift( @INC, '/usr/local/cpanel' ); }

use strict;
use warnings;
use CGI                                                ();
use Cpanel::Logger                                     ();
use Cpanel::ThirdParty::Attracta::AttractaAPI::Account ();
use Cpanel::ThirdParty::Attracta::Company              ();
use Cpanel::ThirdParty::Attracta::Validation           ();
use JSON::Syck ();

my $logger = Cpanel::Logger->new();

print "Content-type: text/plain\nCache-control: no-cache\r\n\r\n";

my $status  = 0;
my $message = '';

my $cgi = CGI->new();

my $user = Cpanel::ThirdParty::Attracta::Validation::isUsername( $cgi->param('username') ) ? $cgi->param('username') : '';
my $pass = $cgi->param('password');

if ( $user eq '' ) {
    $message .= "Invalid or missing username (email address)\n";
}

if ( $pass eq '' ) {
    $message .= "Invalid or missing password\n";
}

if ( $message eq '' ) {
    my $company = Cpanel::ThirdParty::Attracta::Company->new();
    my $companyInfo = Cpanel::ThirdParty::Attracta::AttractaAPI::Account::get( { username => $user, password => $pass } );

    if ( ref($companyInfo) eq 'HASH' ) {
        my $config = {
            companyId => $companyInfo->{company}->{companyid}->{content},
            userId    => $companyInfo->{user}->{userid}->{content},
            key       => $companyInfo->{user}->{key}->{content},
            username  => $companyInfo->{user}->{username}->{content}
        };
        $company->set_config( { config => $config, save => 1 } );

        $status  = 1;
        $message = 'Logged In';
    }
    else {
        $logger->warn("ATTRACTA-SEO: Account Login problem: $companyInfo \n");
        $message = $companyInfo || 'account login failure';
    }
}
else {
    $logger->warn("ATTRACTA-SEO: Account Login Issue: $message \n");
}

print JSON::Syck::Dump( { status => $status, message => $message } );
exit;
