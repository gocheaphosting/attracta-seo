#!/usr/bin/perl
#	get_jobs.cgi
#	Created by David Koston (david@attracta.com) for Attracta (attracta.com)
#	Copyright (c) 2013 Attracta. All rights reserved. Copying is prohibited
#	The following code is subject to the General Embedded License Agreement for Use With Attracta
#	This license can be found at /usr/local/cpanel/3rdparty/attracta/LICENSE
#	Unauthorized use is prohibited

BEGIN {
    unshift( @INC, '/usr/local/cpanel' );
    eval "require Cpanel::ThirdParty::Attracta::AttractaAPI; 1;";
    if ( !$INC{'Cpanel/ThirdParty/Attracta/AttractaAPI.pm'} ) {
        require Cpanel::Logger;
        my $logger = Cpanel::Logger->new();
        #tidyoff
        $logger->warn(
            'Attracta Perl modules are missing.  If Attracta has been manually'
          . " removed, then $0 should also be removed from root's cron jobs."
        );
        #tidyon
        exit();
    }
}

use strict;
use Cpanel::FileUtils::Link                         ();
use Cpanel::FileUtils::TouchFile                    ();
use Cpanel::ThirdParty::Attracta::AttractaAPI::Jobs ();

unless ( getpwuid($<) eq 'root' ) {
    print "This script may only be executed by root\n";
    exit;
}

my $lock_file = '/var/cpanel/attracta/job_lock';
unless ( -f $lock_file ) {
    Cpanel::FileUtils::TouchFile::touchfile( $lock_file, 0600 );
}

if ( Cpanel::ThirdParty::Attracta::AttractaAPI::check_api() ) {
    my $jobs = Cpanel::ThirdParty::Attracta::AttractaAPI::Jobs::get();

    if ( $jobs && ( $jobs != -1 ) ) {
        Cpanel::ThirdParty::Attracta::AttractaAPI::Jobs::processJobs($jobs);
    }
}

#Clean up job lock in case it got set by daily_jobs erlier in the hour
if ( -f '/var/cpanel/attracta/job_lock' ) {
    unlink('/var/cpanel/attracta/job_lock');
}

