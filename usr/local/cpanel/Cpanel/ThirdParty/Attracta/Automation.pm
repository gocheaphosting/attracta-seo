#	Cpanel::ThirdParty::Attracta::Automation.pm
#	Created by Attracta Online Services, Inc. http://attracta.com
#	Copyright (c) 2013 Attracta. All rights reserved. Copying is prohibited
#	The following code is subject to the General Embedded License Agreement for Use With Attracta
#	This license can be found at /usr/local/cpanel/3rdparty/attracta/LICENSE
#	Unauthorized use is prohibited

package Cpanel::ThirdParty::Attracta::Automation;

##	This module contains publicly usable automation routines:
##	linkacct - links an existing attracta account to a cPanel account
##

use strict;
use Cpanel::CachedDataStore                        ();
use Cpanel::Logger                                 ();
use Cpanel::PwCache                                ();
use Cpanel::ThirdParty::Attracta::Company::Update  ();
use Cpanel::ThirdParty::Attracta::Cpanel::Reseller ();
use Cpanel::ThirdParty::Attracta::Validation ();
use Cpanel::ThirdParty::Attracta::Server           ();

my $logger = Cpanel::Logger->new();

sub api2 {
    my $func = shift;
    my %API;

    $API{'linkacct'}{'func'}   = "api2_linkacct";
    $API{'linkacct'}{'engine'} = 'hasharray';

    return \%{ $API{$func} };
}

sub api2_linkacct {
    my $opts = @_;

    my $returnhash = {
        success => 0,
        message => ''
    };

    my $company_id = Cpanel::ThirdParty::Attracta::Validation::isInt( $opts->{companyId} )     ? $opts->{companyId} : '';
    my $user_id    = Cpanel::ThirdParty::Attracta::Validation::isInt( $opts->{userId} )        ? $opts->{userId}    : '';
    my $key        = Cpanel::ThirdParty::Attracta::Validation::isKey( $opts->{key} )           ? $opts->{key}       : '';
    my $username   = Cpanel::ThirdParty::Attracta::Validation::isUsername( $opts->{username} ) ? $opts->{username}  : '';

    unless ($company_id) {
        $returnhash->{message} .= 'No or invalid companyId argument passed to API call.';
    }
    unless ($user_id) {
        $returnhash->{message} .= 'No or invalid userId argument passed to API call.';
    }
    unless ($key) {
        $returnhash->{message} .= 'No or invalid key argument passed to API call.';
    }
    unless ( $company_id && $user_id && $key ) {
        return $returnhash;
    }

    my $account = {
        companyId => $company_id,
        user_id   => $user_id,
        key       => $key,
        username  => $username || ''
    };

    my $user = Cpanel::PwCache::getusername();

    my $save_response = _save_config( $user, $account );
    if ($save_response) {

        #update server id for all their sites at Attracta
        my $resellerInfo        = Cpanel::ThirdParty::Attracta::Cpanel::Reseller::getResellerInfo();
        my $server_id           = Cpanel::ThirdParty::Attracta::Server::getId() || '';
        my $reseller_email_hash = $resellerInfo->{email} || '';

        if ( $server_id && $reseller_email_hash ) {
            Cpanel::ThirdParty::Attracta::Company::Update::update_all_sites( $user, $reseller_email_hash, $server_id );
        }

        $returnhash->{success} = 1;
        $returnhash->{message} = 'cPanel account linked to Attracta account. All SEO Tools features enabled.';
    }
    else {
        $returnhash->{message} = 'Unable to save single sign on data in cPanel. Please contact Atttracta Support with USER ID: ' . $account->{userId};
    }

    return $returnhash;
}

sub _save_config {
    my $user    = shift;
    my $account = shift;

    my $homedir    = Cpanel::PwCache::gethomedir($user);
    my $configdir  = $homedir . '/.attracta';
    my $configfile = $homedir . '/.attracta/user.config';

    if ( Cpanel::ThirdParty::Attracta::Validation::existsDir($configdir) ) {

        Cpanel::CachedDataStore::savedatastore(
            $configfile,
            { 'data' => $account }
        );
        return 1;
    }
    return 0;
}

1;
