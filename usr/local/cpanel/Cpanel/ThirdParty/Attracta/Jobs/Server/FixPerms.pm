#	Cpanel::ThirdParty::Attracta::Jobs::Server::FixPerms.pm
#	Created by David Koston (david@attracta.com) for Attracta (attracta.com)
#	Copyright (c) 2013 Attracta. All rights reserved. Copying is prohibited
#	The following code is subject to the General Embedded License Agreement for Use With Attracta
#	This license can be found at /usr/local/cpanel/3rdparty/attracta/LICENSE
#	Unauthorized use is prohibited

package Cpanel::ThirdParty::Attracta::Jobs::Server::FixPerms;

use strict;
use Cpanel::Config::Users                    ();
use Cpanel::PwCache                          ();
use Cpanel::ThirdParty::Attracta::Validation ();

sub fix_all_perms {
    my $cpusers_ref = Cpanel::Config::Users::getcpusers();
    if ( ref($cpusers_ref) eq 'ARRAY' ) {
        foreach my $user ( @{$cpusers_ref} ) {

            #get home dir. check for attracta config file
            my $homedir   = Cpanel::PwCache::gethomedir($user);
            my $configdir = $homedir . '/.attracta';

            if ( -d $configdir ) {
                my ( $uid, $gid ) = ( getpwnam($user) )[ 2, 3 ];
                chown( $uid, $gid, ($configdir) );
            }
        }
    }
    return 200;
}

sub fix_user_perms {
    my ($site_url) = @_;

    my $site_owner = Cpanel::ThirdParty::Attracta::Cpanel::Owner::get($site_url);
    if ( Cpanel::ThirdParty::Attracta::Validation::isCpanelUsername($site_owner) ) {    #if we can find the domain owner
        my $homedir   = Cpanel::PwCache::gethomedir($site_owner);
        my $configdir = $homedir . '/.attracta';

        if ( -d $configdir ) {
            my ( $uid, $gid ) = ( getpwnam($site_owner) )[ 2, 3 ];
            chown( $uid, $gid, ($configdir) );
        }
        return 200;
    }
    else {
        return $site_owner;
    }
    return 500;
}

1;
