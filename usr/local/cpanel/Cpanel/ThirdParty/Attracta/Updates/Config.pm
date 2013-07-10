#	Cpanel::ThirdParty::Attracta::Updates::Config.pm
#	Created by Attracta Online Services, Inc. http://attracta.com
#	Copyright (c) 2013 Attracta. All rights reserved. Copying is prohibited
#	The following code is subject to the General Embedded License Agreement for Use With Attracta
#	This license can be found at /usr/local/cpanel/3rdparty/attracta/LICENSE
#	Unauthorized use is prohibited

package Cpanel::ThirdParty::Attracta::Updates::Config;

use strict;
use Cpanel::Config::FlushConfig                    ();
use Cpanel::Config::LoadConfig                     ();
use Cpanel::Logger                                 ();
use Cpanel::ThirdParty::Attracta::Validation ();
use Cpanel::ThirdParty::Attracta::FastInclude      ();

my $logger = Cpanel::Logger->new();

sub _config_file {
    return '/var/cpanel/attracta/updates.config';
}

sub _default_config {
    if ( Cpanel::ThirdParty::Attracta::FastInclude::isUpdateDisabled() ) {
        return {
            'PLUGIN'      => 'auto',
            'FASTINCLUDE' => 'none'
        };
    }

    return {
        'PLUGIN'      => 'auto',
        'FASTINCLUDE' => 'auto'
    };
}

#Get server's update configuration
sub load_config {
    my $default_conf_ref = _default_config();

    if ( !-e _config_file() ) {
        Cpanel::ThirdParty::Attracta::Updates::Config::save_config($default_conf_ref);
    }

    my $current_conf_ref = Cpanel::Config::LoadConfig::loadConfig( _config_file() );
    my $changed          = Cpanel::ThirdParty::Attracta::Updates::Config::sanitize_config($current_conf_ref);

    # Default any settings not present in the file.
    foreach my $key ( keys %{$default_conf_ref} ) {
        if ( !exists $current_conf_ref->{$key} ) {
            $changed++;
            $current_conf_ref->{$key} = $default_conf_ref->{$key};
        }
    }

    Cpanel::ThirdParty::Attracta::Updates::Config::save_config($current_conf_ref) if $changed;

    return $current_conf_ref;
}

sub get_update_values {
    my $update_config_ref = Cpanel::ThirdParty::Attracta::Updates::Config::load_config();

    my $plugin_updates      = Cpanel::ThirdParty::Attracta::Validation::isUpdateSetting( $update_config_ref->{PLUGIN} )      ? $update_config_ref->{PLUGIN}      : '-';
    my $fastinclude_updates = Cpanel::ThirdParty::Attracta::Validation::isUpdateSetting( $update_config_ref->{FASTINCLUDE} ) ? $update_config_ref->{FASTINCLUDE} : '-';

    return ( $plugin_updates, $fastinclude_updates );

}

sub sanitize_config {
    my $conf_ref = shift;
    return if ref $conf_ref ne 'HASH';

    my $changed = 0;

    foreach my $key ( keys %{$conf_ref} ) {
        my $value = $conf_ref->{$key};
        if ( !defined $value || $value =~ m/^\s+$/ ) {
            $value = '';
            $changed++;
        }
        else {
            $changed++ if ( $value =~ s/[\n\r]//g );
            $changed++ if ( $value =~ s/^\s+//g );
            $changed++ if ( $value =~ s/\s+$//g );
            $changed++ if ( $value =~ tr/A-Z/a-z/ );
        }
        $conf_ref->{$key} = $value;
    }
    return $changed;
}

sub save_config {
    my $conf_ref = shift;
    return if ref $conf_ref ne 'HASH';

    Cpanel::ThirdParty::Attracta::Updates::Config::sanitize_config($conf_ref);

    # Write config file
    return Cpanel::Config::FlushConfig::flushConfig( _config_file(), $conf_ref, '=', undef, { 'sort' => 1 } );
}

1;
