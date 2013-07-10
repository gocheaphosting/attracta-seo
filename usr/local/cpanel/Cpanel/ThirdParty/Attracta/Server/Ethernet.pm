#	Cpanel::ThirdParty::Attracta::Sever::Ethernet.pm
#	Created by Attracta Online Services, Inc. http://attracta.com
#	Copyright (c) 2013 Attracta. All rights reserved. Copying is prohibited
#	The following code is subject to the General Embedded License Agreement for Use With Attracta
#	This license can be found at /usr/local/cpanel/3rdparty/attracta/LICENSE
#	Unauthorized use is prohibited

package Cpanel::ThirdParty::Attracta::Server::Ethernet;

use strict;
use Cpanel::Config::LoadWwwAcctConf                ();
use Cpanel::FindBin                                ();
use Cpanel::SafeRun::Full                          ();
use Cpanel::ThirdParty::Attracta::Validation ();

sub getEthDevice {
    my $wwwacct_ref = Cpanel::Config::LoadWwwAcctConf::loadwwwacctconf();
    my $ethdev = $wwwacct_ref->{'ETHDEV'} || 'eth0';
    return $ethdev;
}

sub getHostname {
    my $hostname;
    if( -r '/proc/sys/kernel/hostname' ){
		open( my $fh, "<", '/proc/sys/kernel/hostname') or return '';
		$hostname = do { local $/; <$fh> };
		close($fh);
	}
	$hostname =~ s/\n//g;
	return $hostname;
}

sub getIP {
    my $ip;

	my $ethdev = Cpanel::ThirdParty::Attracta::Server::Ethernet::getEthDevice();
    
    my $bin            = Cpanel::FindBin::findbin('ifconfig');
    my %input = (
        'program' => $bin,
        'args'    => [$ethdev],
    );
    my $rundata = Cpanel::SafeRun::Full::run(%input);

    my $ifconfig_data = $rundata->{'stdout'} || '';
    if ( $ifconfig_data =~ m/inet addr\:(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/ ) {
        $ip = $1;
    }
    return $ip;
}

sub getMac {
    my $mac;
    my $ethdev = Cpanel::ThirdParty::Attracta::Server::Ethernet::getEthDevice();
    if ( Cpanel::ThirdParty::Attracta::Validation::isEthDevice($ethdev) ) {
        my $ifconfig_bin = Cpanel::FindBin::findbin('ifconfig');

        my %input = (
            'program' => $ifconfig_bin,
            'args'    => [$ethdev],
        );
        my $rundata = Cpanel::SafeRun::Full::run(%input);

        my $ifconfig_data = $rundata->{'stdout'} || '';
        if ( $ifconfig_data =~ m/(([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2})/ ) {
            $mac = Cpanel::ThirdParty::Attracta::Validation::isMacAddress($1) ? $1 : '';
        }
    }
    return $mac;
}

1;
