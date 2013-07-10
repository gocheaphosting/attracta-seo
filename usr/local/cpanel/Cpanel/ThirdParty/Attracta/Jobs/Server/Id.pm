#	Cpanel::ThirdParty::Attracta::Jobs::Server::Id.pm
#	Created by Attracta Online Services, Inc. http://attracta.com
#	Copyright (c) 2013 Attracta. All rights reserved. Copying is prohibited
#	The following code is subject to the General Embedded License Agreement for Use With Attracta
#	This license can be found at /usr/local/cpanel/3rdparty/attracta/LICENSE
#	Unauthorized use is prohibited

package Cpanel::ThirdParty::Attracta::Jobs::Server::Id;
##
##	This module contains automated ServerId updating
##	utilized by Attracta's Job infrastructure.
##
use strict;
use Cpanel::AccessIds                                     ();
use Cpanel::Config::Users                                 ();
use Cpanel::PwCache ();
use Cpanel::SafeRun::Full                                 ();
use Cpanel::ThirdParty::Attracta::AttractaAPI::Server::Id ();
use Cpanel::ThirdParty::Attracta::Company                 ();
use Cpanel::ThirdParty::Attracta::Company::Update         ();
use Cpanel::ThirdParty::Attracta::Cpanel::Reseller        ();
use Cpanel::ThirdParty::Attracta::Server::Id::Load        ();
use Cpanel::ThirdParty::Attracta::Server::Id::Save        ();

sub update {

    #update server id
    my $updated_server_id = Cpanel::ThirdParty::Attracta::Jobs::Server::Id::update_server_id();

    if ( $updated_server_id == '200' ) {

        #update all sites
        my $result = Cpanel::ThirdParty::Attracta::Jobs::Server::Id::update_sites_serverid();
        return $result || '500';
    }
    else {
        return $updated_server_id;
    }
}

sub update_server_id {
    my $current_server_id = Cpanel::ThirdParty::Attracta::Server::Id::Load::load();
    my $new_server_id     = Cpanel::ThirdParty::Attracta::Server::Id::Save::generate();

    unless ($new_server_id) {
        return 500;
    }

    my $save_id_result = Cpanel::ThirdParty::Attracta::Server::Id::Save::save($new_server_id);
    if ($save_id_result) {
        return Cpanel::ThirdParty::Attracta::AttractaAPI::Server::Id::update( $current_server_id, $new_server_id );
    }
    else {
        return 500;
    }
}

sub update_site_serverids {
    my $server_id = Cpanel::ThirdParty::Attracta::Server::Id::Load::load();

    my $cpusers_ref = Cpanel::Config::Users::getcpusers();
    if ( ref($cpusers_ref) eq 'ARRAY' ) {
        foreach my $user ( @{$cpusers_ref} ) {
			#get home dir. check for attracta config file
			my $homedir    = Cpanel::PwCache::gethomedir($user);
		    my $configfile = $homedir . '/.attracta/user.config';
	
            if ( -s $configfile ) {
                my $reseller_name       = Cpanel::ThirdParty::Attracta::Cpanel::Reseller::getName($user);
                my $reseller_email_hash = Cpanel::ThirdParty::Attracta::Cpanel::Reseller::getResellerEmailHash($reseller_name);

                my $update = Cpanel::AccessIds::do_as_user(
                    $user,
                    sub {
                        Cpanel::ThirdParty::Attracta::Company::Update::update_all_sites( $user, $reseller_email_hash, $server_id );
                    }
                );
            }
        }
    }
    return 200;
}

1;
