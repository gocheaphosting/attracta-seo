#	Cpanel::ThirdParty::Attracta::Apache.pm
#	Created by Attracta Online Services, Inc. http://attracta.com
#	Copyright (c) 2013 Attracta. All rights reserved. Copying is prohibited
#	The following code is subject to the General Embedded License Agreement for Use With Attracta
#	This license can be found at /usr/local/cpanel/3rdparty/attracta/LICENSE
#	Unauthorized use is prohibited

package Cpanel::ThirdParty::Attracta::Apache;

use strict;
use Cpanel::Logger                                ();
use Cpanel::ThirdParty::Attracta::Server::Command ();

#cPanel Apache Setup
my $logger = Cpanel::Logger->new();

my $apache_dir = '/usr/local/apache/';

#checks the output of apachectl to see if it's apache 2.x
sub isApache2 {
    my $version_result = Cpanel::ThirdParty::Attracta::Server::Command::executeForkedTask("$apache_dir/bin/apachectl -v");
    if ( $version_result =~ /Server version\: Apache\/2\./ ) {
        return 1;
    }
    else {
        $logger->warn("ATTRACTA-SEO: Unable to enable all SEO Tools on Apache 1. Please upgrade to Apache 2 and re-install");
        return 0;
    }
}

#restarts apache with apachectl
sub restart {
    my $restart_result = Cpanel::ThirdParty::Attracta::Server::Command::executeForkedTask("$apache_dir/bin/apachectl restart");
    if (  !$restart_result
        || $restart_result =~ /is already loaded, skipping/
        || $restart_result =~ /Warning: DocumentRoot \[[a-zA-Z0-9\/\_]+\] does not exist/
        || $restart_result   =~ /has no VirtualHosts/ ) {
        return 1;
    }
    else {
        $logger->warn("ATTRACTA-SEO: Unexpected Apache Error. Apache is currently not working properly: $restart_result");
        return 0;
    }
}

#starts apache with apachectl
sub start {
    my $start_result = Cpanel::ThirdParty::Attracta::Server::Command::executeForkedTask("$apache_dir/bin/apachectl start");
    if (  !$start_result
        || $start_result =~ /httpd \(pid [\d]+\) already running/
        || $start_result =~ /Warning: DocumentRoot \[[a-zA-Z0-9\/\_]+\] does not exist/
        || $start_result =~ /has no VirtualHosts/ ) {
        return 1;
    }
    else {
        $logger->warn("ATTRACTA-SEO: Unexpected Apache Error. Apache is currently not working properly: $start_result");
        return 0;
    }
}

#stops apache with apachectl
sub stop {
    my $stop_result = Cpanel::ThirdParty::Attracta::Server::Command::executeForkedTask("$apache_dir/bin/apachectl stop");
    if ( !$stop_result ) {
        return 1;
    }
    else {
        $logger->warn("ATTRACTA-SEO: Unexpected Apache Error. Apache is currently not working properly: $stop_result");
        return 0;
    }
}

#get apache status with apachectl
sub status {
    my $status_result = Cpanel::ThirdParty::Attracta::Server::Command::executeForkedTask("$apache_dir/bin/apachectl status");
    if ( $status_result =~ /Alert\!\: Unable to connect to remote host\./ ) {
        $logger->warn("ATTRACTA-SEO: Unexpected Apache Error. Apache is currently not working properly. Apache status:\n $status_result");
        return 0;
    }
    else {
        return 1;
    }
}

1;
