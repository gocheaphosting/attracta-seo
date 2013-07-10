#	Cpanel::ThirdParty::Attracta::Cpanel::EasyApache.pm
#	Created by Attracta Online Services, Inc. http://attracta.com
#	Copyright (c) 2013 Attracta. All rights reserved. Copying is prohibited
#	The following code is subject to the General Embedded License Agreement for Use With cPanel
#	This license can be found at /usr/local/cpanel/3rdparty/attracta/LICENSE
#	Unauthorized use is prohibited

package Cpanel::ThirdParty::Attracta::Cpanel::EasyApache;

use strict;
use Cpanel::DataStore ();
use Cpanel::Logger    ();
use File::Find        ();

my $logger = Cpanel::Logger->new();

my @easyApacheProfileDirs = (
    '/var/cpanel/easy/apache/profile',
    '/var/cpanel/easy/apache/profile/custom'
);

#Finds all Apache 2 EasyApache profiles and adds a custom module to them
sub addModuleEAProfiles {
    my $module_name = shift;

    if ($module_name) {
        File::Find::find(
            sub {
                Cpanel::ThirdParty::Attracta::Cpanel::EasyApache::addModuleEAProfile($module_name);
            },
            @easyApacheProfileDirs
        );
        return 1;
    }
    else {
        $logger->warn("ATTRACTA-SEO: Could not enable custom apache module to EA profiles. No module name passed");
        return 0;
    }
}

sub addModuleEAProfile {
    my $module_name = shift;

    if ( -f $File::Find::name && $File::Find::name =~ /\.yaml$/ ) {
        my $profileRef = Cpanel::DataStore::load_ref($File::Find::name);
        if ($profileRef) {
            if ( $profileRef->{Apache} ) {
                if ( $profileRef->{Apache}->{version} ) {

                    #only modify profiles using apache 2
                    if ( $profileRef->{Apache}->{version} =~ /^2/ ) {
                        unless ( $profileRef->{$module_name} ) {
                            $profileRef->{$module_name} = 1;
                            Cpanel::DataStore::store_ref(
                                $File::Find::name,
                                $profileRef
                            );
                        }
                    }
                }
            }
        }
    }
}

#Finds all Apache 2 EasyApache profiles and remove a custom module from them
sub removeModuleEAProfiles {
    my $module_name = shift;

    if ($module_name) {
        File::Find::find(
            sub {
                Cpanel::ThirdParty::Attracta::Cpanel::EasyApache::removeModuleEAProfile($module_name);
            },
            @easyApacheProfileDirs
        );
        return 1;
    }
    else {
        $logger->warn("ATTRACTA-SEO: Could not remove custom apache module from EA profiles. No module name passed");
        return 0;
    }
}

sub removeModuleEAProfile {
    my $module_name = shift;

    if ( -f $File::Find::name && $File::Find::name =~ /\.yaml$/ ) {
        my $profileRef = Cpanel::DataStore::load_ref($File::Find::name);
        if ($profileRef) {
            if ( $profileRef->{Apache} ) {
                if ( $profileRef->{Apache}->{version} ) {

                    #only modify profiles using apache 2
                    if ( $profileRef->{Apache}->{version} =~ /^2/ ) {
                        if ( exists( $profileRef->{$module_name} ) ) {
                            delete( $profileRef->{$module_name} );
                            Cpanel::DataStore::store_ref(
                                $File::Find::name,
                                $profileRef
                            );
                        }
                    }
                }
            }
        }
    }
}

1;
