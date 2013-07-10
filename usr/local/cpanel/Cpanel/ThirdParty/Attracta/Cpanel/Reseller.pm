#	Cpanel::ThirdParty::Attracta::Cpanel::Reseller.pm
#	Created by Attracta Online Services, Inc. http://attracta.com
#	Copyright (c) 2013 Attracta. All rights reserved. Copying is prohibited
#	The following code is subject to the General Embedded License Agreement for Use With Attracta
#	This license can be found at /usr/local/cpanel/3rdparty/attracta/LICENSE
#	Unauthorized use is prohibited

package Cpanel::ThirdParty::Attracta::Cpanel::Reseller;

use strict;
use Cpanel::AcctUtils::Owner                 ();
use Cpanel::AdminBin                         ();
use Cpanel::Config::LoadWwwAcctConf          ();
use Cpanel::ContactInfo::Email               ();
use Cpanel::Logger                           ();
use Cpanel::ThirdParty::Attracta::Validation ();
use Digest::MD5                              ();

my $logger = Cpanel::Logger->new();

sub getResellerEmailHash {
    my $reseller = $_[0];

    my $email;

    if ( $reseller eq 'root' ) {
        my $wwwacctRef = Cpanel::Config::LoadWwwAcctConf::loadwwwacctconf();
        $email = $wwwacctRef->{'CONTACTEMAIL'};
    }
    elsif ( Cpanel::ThirdParty::Attracta::Validation::isCpanelUsername($reseller) ) {
        $email = Cpanel::ContactInfo::Email::getcontactemail($reseller);
    }

    return Digest::MD5::md5_hex($email);
}

sub getName {
    my $user = $_[0] || $ENV{'REMOTE_USER'};
    return Cpanel::AcctUtils::Owner::getowner($user);
}

sub getResellerInfo {
    my $wrap_result = Cpanel::AdminBin::adminfetchnocache(
        'attracta', '', 'GETRESELLERINFO',
        'storable', ''
    );

    if ( ref $wrap_result eq 'ARRAY' ) {
        return $wrap_result->[0]->{data};
    }
    else {
        $logger->warn('ATTRACTA-SEO: Could not get reseller / root link information. Please contact Attracta support at http://support.attracta.com/.');
        return 0;
    }
}

1;
