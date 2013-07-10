##	Cpanel::ThirdParty::Attracta::Cron.pm
#	Created by Attracta Online Services, Inc. http://attracta.com
#	Copyright (c) 2013 Attracta. All rights reserved. Copying is prohibited
#	The following code is subject to the General Embedded License Agreement for Use With Attracta
#	This license can be found at /usr/local/cpanel/3rdparty/attracta/LICENSE
#	Unauthorized use is prohibited

package Cpanel::ThirdParty::Attracta::Cron;

use strict;
use Cpanel::Logger ();

my $logger    = Cpanel::Logger->new();
my $root_cron = '/var/spool/cron/root';

sub addAttracta {
    Cpanel::ThirdParty::Attracta::Cron::addHourly();
    Cpanel::ThirdParty::Attracta::Cron::addRealTime();
}

sub removeAttracta {
    Cpanel::ThirdParty::Attracta::Cron::removeHourly();
    Cpanel::ThirdParty::Attracta::Cron::removeRealTime();
}

sub addHourly {

    #Random minute offset
    my $minute = int( rand(60) );

    # check if Attracta job is already installed
    if ( open( my $cron_fh, '<', $root_cron ) ) {
        while ( my $line = <$cron_fh> ) {
            if ( $line =~ m/attracta\/scripts\/get_jobs/ ) {
                close($cron_fh);
                return;
            }
        }
        close($cron_fh);
    }
    else {
        $logger->die("ATTRACTA-SEO: Could not load root crontab. Hourly jobs could not be enabled");
    }

    #Append our event to the crontab

    if ( open( my $cron_fh, '>>', $root_cron ) ) {
        print $cron_fh "$minute * * * * /usr/local/cpanel/3rdparty/attracta/scripts/get_jobs.pl > /dev/null 2>&1\n";
        close($cron_fh);
    }
}

sub removeHourly {

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
            if ( $line =~ m/attracta\/scripts\/get_jobs/ ) {
                next;
            }
            else {
                print {$cron_fh} $line;
            }
        }
        close($cron_fh);
    }

}

sub addRealTime {

    # check if Attracta job is already installed
    if ( open( my $cron_fh, '<', $root_cron ) ) {
        while ( my $line = <$cron_fh> ) {
            if ( $line =~ m/attracta\/scripts\/daily_jobs/ ) {
                close($cron_fh);
                return;
            }
        }
        close($cron_fh);
    }
    else {
        $logger->die("ATTRACTA-SEO: Could not load root crontab. Real time jobs could not be enabled");
    }

    #Append our event to the crontab

    if ( open( my $cron_fh, '>>', $root_cron ) ) {
        print $cron_fh "* * * * * /usr/local/cpanel/3rdparty/attracta/scripts/daily_jobs.pl > /dev/null 2>&1\n";
        close($cron_fh);
    }

}

sub removeRealTime {

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
            if ( $line =~ m/attracta\/scripts\/daily_jobs/ ) {
                next;
            }
            else {
                print {$cron_fh} $line;
            }
        }
        close($cron_fh);
    }

}

#remove cron entries from previous versions
sub removeOld {

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
            if ( $line =~ m/Attracta\/scripts\/daily_jobs/ || $line =~ m/Attracta\/Scripts\/daily_jobs/ ) {
                next;
            }
            else {
                print {$cron_fh} $line;
            }
        }
        close($cron_fh);
    }

}

1;
