#	Cpanel::ThirdParty::Attracta::Apache::Modules.pm
#	Created by David Koston (david@attracta.com) for Attracta (attracta.com)
#	Copyright (c) 2013 Attracta. All rights reserved. Copying is prohibited
#	The following code is subject to the General Embedded License Agreement for Use With Attracta
#	This license can be found at /usr/local/cpanel/3rdparty/attracta/LICENSE
#	Unauthorized use is prohibited

package Cpanel::ThirdParty::Attracta::Apache::Modules;

use strict;
use Cpanel::Logger                                ();
use Cpanel::ThirdParty::Attracta::Apache          ();
use Cpanel::ThirdParty::Attracta::Apache::Config  ();
use Cpanel::ThirdParty::Attracta::Server::Command ();
use Cpanel::FileUtils::Link                       ();

my $logger = Cpanel::Logger->new();

my $apache_dir = '/usr/local/apache/';

#adds a shared object to apache with apxs (and restarts ap)
# TODO: replace with SafeRun
sub buildSO {
    my ( $module_name, $module_dir ) = @_;
    if ( !$module_name || !$module_dir ) {
        $logger->warn("Invalid arguments");
        return 0;
    }
    my $install_result = Cpanel::ThirdParty::Attracta::Server::Command::executeForkedTask("$apache_dir/bin/apxs -i -a -c $module_name $module_dir/mod_$module_name.c");
    return ( $install_result =~ /\[activating module/ ) ? 1 : 0;
}

sub addSO {
    my $module_name = shift;
    my $module_dir  = shift;

    if ($module_name) {
        if ($module_dir) {
            if ( -f $module_dir . 'mod_' . $module_name . '.c' ) {
                my $install_result = Cpanel::ThirdParty::Attracta::Apache::Modules::buildSO( $module_name, $module_dir );
                if ($install_result) {
                    if ( Cpanel::ThirdParty::Attracta::Apache::status() ) {
                        Cpanel::ThirdParty::Attracta::Apache::stop();
                        if ( Cpanel::ThirdParty::Attracta::Apache::start() ) {
                            return Cpanel::ThirdParty::Attracta::Apache::Config::save();
                        }
                        else {
                            if ( Cpanel::ThirdParty::Attracta::Apache::restart() ) {
                                return Cpanel::ThirdParty::Attracta::Apache::Config::save();
                            }
                            else {
                                return 0;
                            }
                        }
                    }
                    else {
                        if ( Cpanel::ThirdParty::Attracta::Apache::start() ) {
                            return Cpanel::ThirdParty::Attracta::Apache::Config::save();
                        }
                        else {
                            Cpanel::ThirdParty::Attracta::Apache::Config::removeModule();
                            Cpanel::ThirdParty::Attracta::Apache::Config::save();
                            return 0;
                        }
                    }
                }
                else {
                    $logger->warn("ATTRACTA-SEO: Cannot install apache module. apxs failed");
                    Cpanel::ThirdParty::Attracta::Apache::Config::removeModule(1);
                    return 0;
                }
            }
            else {
                $logger->warn("ATTRACTA-SEO: Cannot install apache module $module_name. Could not find module source file");
                return 0;
            }
        }
        else {
            $logger->warn("ATTRACTA-SEO: Cannot install apache module. No module location provided");
            return 0;
        }
    }
    else {
        $logger->warn("ATTRACTA-SEO: Cannot install apache module. No name provided");
        return 0;
    }

}

#removes a shared object from apache's conf and module store (and restarts ap)
sub deleteSO {
    my $module_name = shift;
    if ($module_name) {
        my $status = ( Cpanel::ThirdParty::Attracta::Apache::Config::removeModule(1) );
        if ($status) {
            Cpanel::ThirdParty::Attracta::Apache::Config::save("Remove Mod_FastInclude");
            return Cpanel::FileUtils::Link::safeunlink("$apache_dir/modules/mod_$module_name.so");
        }
        else {
            return $status;
        }
    }
    else {
        $logger->warn("ATTRACTA-SEO: Cannot remove shared apache module. No name provided.");
        return 0;
    }
}

1;
