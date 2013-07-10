#	Cpanel::ThirdParty::Attracta::AttractaAPI::Verify.pm
#	Created by Attracta Online Services, Inc. http://attracta.com
#	Copyright (c) 2013 Attracta. All rights reserved. Copying is prohibited
#	The following code is subject to the General Embedded License Agreement for Use With Attracta
#	This license can be found at /usr/local/cpanel/3rdparty/attracta/LICENSE
#	Unauthorized use is prohibited

package Cpanel::ThirdParty::Attracta::AttractaAPI::Verify;

use strict;
use Cpanel::Logger                            ();
use Cpanel::ThirdParty::Attracta::AttractaAPI ();
use Cpanel::ThirdParty::Attracta::Validation  ();

my $logger = Cpanel::Logger->new();

sub verify_company {
    my ($options) = @_;

    unless ( Cpanel::ThirdParty::Attracta::Validation::isURL( $options->{domain} ) ) {
        return 400;
    }
    unless ( Cpanel::ThirdParty::Attracta::Validation::isEmail( $options->{email} ) ) {
        return 400;
    }

    my $email = _stars( $options->{email} );

    if ($email) {
        my $response = Cpanel::ThirdParty::Attracta::AttractaAPI::sendRequest(
            { format => 'xml', location => '/rpc/api/webhost' },
            (
                do     => 'update-company-email',
                domain => $options->{domain},
                email  => $email
            )
        );
    }

}

sub _stars {
    my $email = $_[0];

    if ( $email =~ /^(.+)(\@.+\.[a-zA-Z]{2,6})$/ ) {
        my $first  = $1;
        my $second = $2;
        $first =~ s/./*/g;
        return $first . $second;
    }
    return 0;
}

1;
