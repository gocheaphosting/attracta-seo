#	Cpanel::ThirdParty::Attracta::Cpanel::AdminBin.pm
#	Created by Attracta Online Services, Inc. http://attracta.com
#	Copyright (c) 2013 Attracta. All rights reserved. Copying is prohibited
#	The following code is subject to the General Embedded License Agreement for Use With Attracta
#	This license can be found at /usr/local/cpanel/3rdparty/attracta/LICENSE
#	Unauthorized use is prohibited

package Cpanel::ThirdParty::Attracta::Cpanel::AdminBin;

use strict;

sub parseAdminBinOutput {
    my $output = shift;
    $output =~ s/[\r\n]+//g;    #Remove \n from AdminBin output
    $output =~ s/^.//;          #Remove . from AdminBin output
    return $output;
}

1;
