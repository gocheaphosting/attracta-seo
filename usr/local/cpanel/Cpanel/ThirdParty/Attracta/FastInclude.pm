#	Cpanel::ThirdParty::Attracta::FastInclude.pm
#	Created by David Koston (david@attracta.com) for Attracta (attracta.com)
#	Copyright (c) 2013 Attracta. All rights reserved. Copying is prohibited
#	The following code is subject to the General Embedded License Agreement for Use With Attracta
#	This license can be found at /usr/local/cpanel/3rdparty/attracta/LICENSE
#	Unauthorized use is prohibited

package Cpanel::ThirdParty::Attracta::FastInclude;

use strict;
use Cpanel::FileUtils::Link      ();
use Cpanel::FileUtils::TouchFile ();
use Cpanel::SafeRun::Simple      ();

sub disable {
    my $result;
    $result = Cpanel::FileUtils::TouchFile::touchfile('/var/cpanel/attracta/fastinclude_off');
    return $result;
}

sub enable {

    if ( !-e '/var/cpanel/attracta/fastinclude_off' ) {
        return 1;
    }

    my $result = 0;
    $result = Cpanel::FileUtils::Link::safeunlink('/var/cpanel/attracta/fastinclude_off');
    return $result;
}

sub isDisabled {
    return -f '/var/cpanel/attracta/fastinclude_off' ? 1 : 0;
}

sub isInstalled {
    if ( -f '/usr/local/apache/bin/apachectl' ) {
        my @commands = (
            '/usr/local/apache/bin/apachectl',
            '-t', '-D',
            'DUMP_MODULES'
        );
        my $result = Cpanel::SafeRun::Simple::_saferun_r( \@commands, 2 ) || '';

        if ( $$result =~ /fastinclude_module/ ) {
            return 1;
        }
    }
    return 0;
}

sub isEnabled {
    return ( isInstalled() && !isDisabled() ) ? 1 : 0;
}

sub isUpdateDisabled {
    return -f '/var/cpanel/attracta/no_fastinclude_up' ? 1 : 0;
}

sub disableUpdate {
    my $result;
    $result = Cpanel::FileUtils::TouchFile::touchfile('/var/cpanel/attracta/no_fastinclude_up');
    return $result;
}

sub enableUpdate {

    if ( !-e '/var/cpanel/attracta/no_fastinclude_upf' ) {
        return 1;
    }

    my $result = 0;
    $result = Cpanel::FileUtils::Link::safeunlink('/var/cpanel/attracta/no_fastinclude_up');
    return $result;
}

1;
