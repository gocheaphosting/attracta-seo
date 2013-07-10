#!/usr/bin/perl
#	resetpass.cgi
#	Created by Attracta Online Services, Inc. http://attracta.com
#	Copyright (c) 2013 Attracta. All rights reserved. Copying is prohibited
#	The following code is subject to the General Embedded License Agreement for Use With Attracta
#	This license can be found at /usr/local/cpanel/3rdparty/attracta/LICENSE
#	Unauthorized use is prohibited

BEGIN { unshift( @INC, '/usr/local/cpanel' ); }

use strict;
use warnings;
use CGI                                                ();
use JSON::Syck                                       ();
use Cpanel::ThirdParty::Attracta::AttractaAPI::Account ();
use Cpanel::ThirdParty::Attracta::Validation           ();


print "Content-type: text/plain\nCache-control: no-cache\r\n\r\n";

my $status  = 0;
my $message = '';

my $cgi = CGI->new();

my $email = Cpanel::ThirdParty::Attracta::Validation::isEmail( $cgi->param('email') ) ? $cgi->param('email') : '';

if ( $email eq '' ) {
    $message .= "Invalid or missing email address\n";
}
else {
    Cpanel::ThirdParty::Attracta::AttractaAPI::Account::reset_pass($email);
    $status = 1;
}

print JSON::Syck::Dump( { status => $status, message => $message } );
exit;

