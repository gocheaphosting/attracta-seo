#	Cpanel::ThirdParty::Attracta::Version.pm
#	Created by Attracta Online Services, Inc. http://attracta.com
#	Copyright (c) 2013 Attracta. All rights reserved. Copying is prohibited
#	The following code is subject to the General Embedded License Agreement for Use With Attracta
#	This license can be found at /usr/local/cpanel/3rdparty/attracta/LICENSE
#	Unauthorized use is prohibited

package Cpanel::ThirdParty::Attracta::Version;

use strict;
use Cpanel::LoadFile                              ();
use Cpanel::Logger                                ();
use Cpanel::SafeFile                              ();
use Cpanel::ThirdParty::Attracta::Version::Plugin ();

my $logger = Cpanel::Logger->new();

#returns our current version
*get = \&Cpanel::ThirdParty::Attracta::Version::Plugin::get;

#returns current mod_fastinclude version
sub getFI {
    my $line = `grep '#define MYVERSION' /usr/local/cpanel/3rdparty/attracta/mod_fastinclude/mod_fastinclude.c`;
    $line =~ s/\#define MYVERSION//g;
    $line =~ s/["\s]+//g;
    return $line;
}

#checks to see if an update is in progess
sub isUpdating {
    return -f '/var/cpanel/attracta/updating' ? 1 : 0;
}

#gets the latest installed version
sub load {
    my $version = Cpanel::LoadFile::loadfile('/var/cpanel/attracta/version');
    $version =~ m/(\d+\.\d+)(cp\d+)?/;
    return $1;
}

#gets the latest installed version
sub load_full_version {
    return Cpanel::LoadFile::loadfile('/var/cpanel/attracta/version');
}

#gets latest installed mod_fastinclude version
sub loadFI {
    return Cpanel::LoadFile::loadfile('/var/cpanel/attracta/fiversion');
}

sub set {
    my $version = shift;

    my $rlock = Cpanel::SafeFile::safeopen( \*VERSION, '>', '/var/cpanel/attracta/version' );
    if ( !$rlock ) {
        $logger->warn("ATTRACTA SEO: Could not write Attracta version to '/var/cpanel/attracta/version'");
        return 0;
    }
    print VERSION $version;
    Cpanel::SafeFile::safeclose( \*VERSION, $rlock );
}

sub setFI {
    my $version = shift;

    my $rlock = Cpanel::SafeFile::safeopen( \*FIVERSION, '>', '/var/cpanel/attracta/fiversion' );
    if ( !$rlock ) {
        $logger->warn("ATTRACTA SEO: Could not write FastInclude version to '/var/cpanel/attracta/fiversion'");
        return 0;
    }
    print FIVERSION $version;
    Cpanel::SafeFile::safeclose( \*FIVERSION, $rlock );
}

1;
