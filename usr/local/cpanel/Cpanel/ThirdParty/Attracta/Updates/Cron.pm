##	Cpanel::ThirdParty::Attracta::Updates::Cron.pm
#	Created by Attracta Online Services, Inc. http://attracta.com
#	Copyright (c) 2013 Attracta. All rights reserved. Copying is prohibited
#	The following code is subject to the General Embedded License Agreement for Use With Attracta
#	This license can be found at /usr/local/cpanel/3rdparty/attracta/LICENSE
#	Unauthorized use is prohibited

package Cpanel::ThirdParty::Attracta::Updates::Cron;

use strict;
use Cpanel::Logger ();

my $logger    = Cpanel::Logger->new();
my $root_cron = '/var/spool/cron/root';

sub add {
    #Random minute and hour offset
    my $minute = _get_random_minute();
	my $hour = _get_random_hour();

    # check if Attracta update cron task is already installed
    if ( open( my $cron_fh, '<', $root_cron ) ) {
        while ( my $line = <$cron_fh> ) {
            if ( $line =~ m/attracta\/scripts\/update\-attracta/ ) {
                close($cron_fh);
                return;
            }
        }
        close($cron_fh);
    }
    else {
        $logger->die("ATTRACTA-SEO: Could not load root crontab. Updates could not be enabled");
    }

    #Append our event to the crontab

    if ( open( my $cron_fh, '>>', $root_cron ) ) {
        print $cron_fh "$minute $hour * * * /usr/local/cpanel/3rdparty/attracta/scripts/update-attracta --from-cron > /dev/null 2>&1\n";
        close($cron_fh);
    }

}

sub remove {

    # load existing crontab
    my @cron_data;
    if ( open( my $cron_fh, '<', $root_cron ) ) {
        while ( my $line = <$cron_fh> ) {
            push( @cron_data, $line );
        }
        close($cron_fh);
    }
    else {
        $logger->die("ATTRACTA-SEO: Could not load root crontab.");
    }

    # remove Attracta cron
    if ( open( my $cron_fh, '>', $root_cron ) ) {
        foreach my $line (@cron_data) {
            if ( $line =~ m/attracta\/scripts\/update\-attracta/ ) {
                next;
            }
            else {
                print {$cron_fh} $line;
            }
        }
        close($cron_fh);
    }

}

sub _get_random_hour {
    return int( rand(24) );
}

sub _get_random_minute {
	return int( rand(60) );
}

1;
