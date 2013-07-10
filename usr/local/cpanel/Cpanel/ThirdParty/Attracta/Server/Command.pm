#	Cpanel::ThirdParty::Attracta::Server::Command.pm
#	Created by David Koston (david@attracta.com) for Attracta (attracta.com)
#	Copyright (c) 2013 Attracta. All rights reserved. Copying is prohibited
#	The following code is subject to the General Embedded License Agreement for Use With Attracta
#	This license can be found at /usr/local/cpanel/3rdparty/attracta/LICENSE
#	Unauthorized use is prohibited

package Cpanel::ThirdParty::Attracta::Server::Command;

use strict;
use Cpanel::Logger ();
use IPC::Open3     ();

my $logger = Cpanel::Logger->new();

sub executeForkedTask {
    my $command = shift;

    unless ($command) {
        $logger->warn("ATTRACTA-SEO: A command name must be passed with Attracta::Apache::executeForkedTask");
        return 0;
    }

    my ( $eh, $rh, $pid, $result, $wh );

    $pid = IPC::Open3::open3( $wh, $rh, $eh, $command );
    {
        local $/;
        $result = readline($rh);
        $result =~ s/[\n]+//g;
    }

    waitpid( $pid, 0 );

    return $result || '';
}

1;
