#!/usr/bin/perl
#	daily_jobs.pl
#	Created by David Koston (david@attracta.com) for Attracta (attracta.com)
#	Copyright (c) 2013 Attracta. All rights reserved. Copying is prohibited
#	The following code is subject to the General Embedded License Agreement for Use With Attracta
#	This license can be found at /usr/local/cpanel/3rdparty/attracta/LICENSE
#	Unauthorized use is prohibited
BEGIN { unshift( @INC, '/usr/local/cpanel' ); }
use strict;

my $lock_file = '/var/cpanel/attracta/job_lock';

#if lock file exists and is less than 30 minutes old, jobs are considered running, check again later
if ( -f $lock_file && time() - ( stat($lock_file) )[9] < 1800 ) {
    exit;
}
elsif ( -f $lock_file ) {
    unlink('/var/cpanel/attracta/job_lock');
}

#tests to make sure required modules are still installed and fail gracefully if not
eval "require Cpanel::FileUtils::TouchFile; 1;";
if ( !$INC{'Cpanel/FileUtils/TouchFile.pm'} ) {
    exit();
}
eval "require Cpanel::ThirdParty::Attracta::Server::Ethernet; 1;";
if ( !$INC{'Cpanel/ThirdParty/Attracta/Server/Ethernet.pm'} ) {
    exit();
}
eval "require Cpanel::ThirdParty::Attracta::AttractaAPI; 1;";
if ( !$INC{'Cpanel/ThirdParty/Attracta/AttractaAPI.pm'} ) {
    exit();
}
eval "require Cpanel::ThirdParty::Attracta::Server::Id::Load; 1;";
if ( !$INC{'Cpanel/ThirdParty/Attracta/Server/Id/Load.pm'} ) {
    exit();
}
eval "require IPC::Open3; 1;";
if ( !$INC{'IPC/Open3.pm'} ) {
    exit();
}
eval "require Net::SSLeay; 1;";
if ( !$INC{'Net/SSLeay.pm'} ) {
    exit();
}

my $serverId   = Cpanel::ThirdParty::Attracta::Server::Id::Load::load()   || '-',;
my $macaddress = Cpanel::ThirdParty::Attracta::Server::Ethernet::getMac() || '-';
my $host       = Cpanel::ThirdParty::Attracta::AttractaAPI::getHost();
my ( $page, $response, %headers ) = Net::SSLeay::get_https( $host, 443, '/rpc/api/webhost?do=job-check&serverId=' . $serverId . '&macaddress=' . $macaddress );

if ( exists $headers{'JOBAVAILABLE'} ) {
    if ( $headers{'JOBAVAILABLE'} eq '1' ) {
        Cpanel::FileUtils::TouchFile::touchfile( $lock_file, 0600 );
        my $pid = IPC::Open3::open3( my $wh, my $rh, my $eh, '/usr/local/cpanel/3rdparty/attracta/scripts/get_jobs.pl' );
        waitpid( $pid, 0 );
        if ( -f $lock_file ) {
            unlink($lock_file);
        }
    }
    elsif ( $headers{'JOBAVAILABLE'} =~ /^\d+$/o && $headers{'JOBAVAILABLE'} ne '0' ) {

        #if a number is returned, back off for X minutes (x minutes from now() - 30 minutes)
        Cpanel::FileUtils::TouchFile::touchfile( $lock_file, 0600 );
        my $lock_time = time() + ( $headers{'JOBAVAILABLE'} * 60 ) - 1800;
        utime( $lock_time, $lock_time, $lock_file );
    }
}
