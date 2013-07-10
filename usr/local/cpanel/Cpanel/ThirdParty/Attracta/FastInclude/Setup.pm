#	Cpanel::ThirdParty::Attracta::FastInclude::Setup.pm
#	Created by David Koston (david@attracta.com) for Attracta (attracta.com)
#	Copyright (c) 2013 Attracta. All rights reserved. Copying is prohibited
#	The following code is subject to the General Embedded License Agreement for Use With Attracta
#	This license can be found at /usr/local/cpanel/3rdparty/attracta/LICENSE
#	Unauthorized use is prohibited

package Cpanel::ThirdParty::Attracta::FastInclude::Setup;

use strict;
use Cpanel::FileUtils::TouchFile                     ();
use Cpanel::Logger                                   ();
use Cpanel::ThirdParty::Attracta::Apache             ();
use Cpanel::ThirdParty::Attracta::Apache::Config     ();
use Cpanel::ThirdParty::Attracta::Apache::Modules    ();
use Cpanel::ThirdParty::Attracta::Cpanel::EasyApache ();
use Cpanel::ThirdParty::Attracta::Cron               ();
use Cpanel::ThirdParty::Attracta::Validation   ();

my $logger = Cpanel::Logger->new();

my $module_name      = 'fastinclude';
my $shared_mod_dir   = '/usr/local/cpanel/3rdparty/attracta/mod_fastinclude/';
my $shared_mod_file  = $shared_mod_dir . 'mod_' . $module_name . '.c';
my $module_perl_name = 'Cpanel::Easy::ModFastInclude';
my $apache_dir       = '/usr/local/apache';

sub install {
	unless( Cpanel::ThirdParty::Attracta::Apache::isApache2()){
		return 0;
	}
	
    if ( Cpanel::ThirdParty::Attracta::Validation::isFile($shared_mod_file) ) {
        if ( Cpanel::ThirdParty::Attracta::Validation::isDir( $apache_dir . '/bin' ) ) {
            if ( Cpanel::ThirdParty::Attracta::Apache::Modules::addSO( $module_name, $shared_mod_dir ) ) {

                #enable our cron to check for includes
                Cpanel::ThirdParty::Attracta::Cron::removeAttracta();    #Remove any old entries
                Cpanel::ThirdParty::Attracta::Cron::addAttracta();       #Add new cron task

                #Add module to EasyApache profiles
                Cpanel::ThirdParty::Attracta::Cpanel::EasyApache::addModuleEAProfiles($module_perl_name);

                return 1;
            }
            else {
                $logger->warn("ATTRACTA-SEO: Unable to install mod_fastinclude.");
                return 0;
            }
        }
        else {
            $logger->warn("ATTRACTA-SEO: Apache not found at $apache_dir. All features not enabled");
            return 0;
        }
    }
    else {
        $logger->warn("ATTRACTA-SEO: Cannot find Apache module file for mod_$module_name. All features not enabled.");
        return 0;
    }
}

sub remove {
    my $status = Cpanel::ThirdParty::Attracta::Apache::Modules::deleteSO($module_name);
    if ($status) {

        #remove module related cron job
        Cpanel::ThirdParty::Attracta::Cron::removeAttracta();    #Remove any old entries

        #remove module from EasyApache profiles
        Cpanel::ThirdParty::Attracta::Cpanel::EasyApache::removeModuleEAProfiles($module_perl_name);

        return 1;
    }
    else {
        return $status;
    }
}

1;
