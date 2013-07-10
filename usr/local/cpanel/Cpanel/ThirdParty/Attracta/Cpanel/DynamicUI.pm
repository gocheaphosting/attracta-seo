#	Cpanel::ThirdParty::Attracta::Cpanel::DynamicUI.pm
#	Created by Attracta Online Services, Inc. http://attracta.com
#	Copyright (c) 2013 Attracta. All rights reserved. Copying is prohibited
#	The following code is subject to the General Embedded License Agreement for Use With cPanel
#	This license can be found at /usr/local/cpanel/3rdparty/attracta/LICENSE
#	Unauthorized use is prohibited

package Cpanel::ThirdParty::Attracta::Cpanel::DynamicUI;

use Cpanel::Config::Users   ();
use Cpanel::FileUtils::Link ();
use Cpanel::PwCache         ();
use Cpanel::SafeDir::Read   ();
use Cpanel::SafeFile        ();
use IO::Handle              ();

sub fix_group_orders {
    my $cpanel_users = Cpanel::Config::Users::getcpusers();

    foreach my $cpanel_user ( @{$cpanel_users} ) {
        my $homedir          = Cpanel::PwCache::gethomedir($cpanel_user);
        my $group_order_file = $homedir . '/.cpanel/nvdata/xmaingroupsorder';
        my $updated          = 0;

        if ( -f $group_order_file ) {
            $updated = Cpanel::ThirdParty::Attracta::Cpanel::DynamicUI::set_group_order($group_order_file);
        }

        if ($updated) {
            Cpanel::ThirdParty::Attracta::Cpanel::DynamicUI::remove_group_order_cache($homedir);
        }

    }
}

#nvdata group order related functions

sub load_group_order {
    my $file_name = $_[0];

    my $fh = IO::Handle->new();

    my $rlock = Cpanel::SafeFile::safeopen( $fh, '<', $file_name );
    if ( !$rlock ) { return 0; }
    my $group_order_string = do { local $/; readline($fh); };
    Cpanel::SafeFile::safeclose( $fh, $rlock );
    return $group_order_string;
}

sub save_group_order {
    my $file_name          = $_[0];
    my $group_order_string = $_[1];

    my $fh = IO::Handle->new();
    my $slock = Cpanel::SafeFile::safeopen( $fh, '>', $file_name );
    if ( !$slock ) { return 0; }
    seek $fh, 0, 0;
    print $fh $group_order_string;
    truncate( $fh, tell $fh );
    Cpanel::SafeFile::safeclose( $fh, $slock );

    return 1;
}

sub set_group_order {
    my $file_name = $_[0];

    my $group_order_string = Cpanel::ThirdParty::Attracta::Cpanel::DynamicUI::load_group_order($file_name);

    my ( $updated, $updated_string ) = Cpanel::ThirdParty::Attracta::Cpanel::DynamicUI::update_group_order($group_order_string);

    if ($updated) {
        my $response = Cpanel::ThirdParty::Attracta::Cpanel::DynamicUI::save_group_order( $file_name, $updated_string );
        if ($response) {
            return 1;
        }
    }
    return 0;
}

sub update_group_order {
    my $current_group_order_string = $_[0];

    my $attracta_index;
    my $updated_string;
    my $found_attracta = 0;
    my $spot_3         = 0;

    my @groups = split( /\|/, $current_group_order_string );

    for my $i ( 0 .. $#groups ) {
        if ( $groups[$i] eq 'Attracta_SEO' ) {
            $found_attracta = 1;
            if ( $i == 2 ) {
                return ( 0, '' );    #we're spot 3, no further work needed
            }
            else {
                $attracta_index = $i;
            }
            last;
        }
        elsif ( $groups[$i] =~ /Attracta/ ) {
            $found_attracta = 1;
            $groups[$i] = 'Attracta_SEO';
            if ( $i == 2 ) {
                $spot_3 = 1;
            }
            else {
                $attracta_index = $i;
            }
            last;
        }
    }

    if ( $spot_3 != 1 ) {
        if ($found_attracta) {

            #remove Attracta_SEO
            splice( @groups, $attracta_index, 1 );
        }
        my @part1 = splice( @groups, 0, 2 );
        @groups = ( @part1, ('Attracta_SEO'), @groups );
    }

    $updated_string = join( '|', @groups );

    return ( 1, $updated_string );
}

sub remove_group_order_cache {
    my $homedir = $_[0];

    my $caches_dir = $homedir . '/.cpanel/caches/dynamicui';

	if( -d $caches_dir ){
	    my $cache_files = Cpanel::SafeDir::Read::read_dir($caches_dir);

	    foreach my $cache_file ( @{$cache_files} ) {
	        my $full_path_cache_file = $homedir . '/.cpanel/caches/dynamicui/' . $cache_file;

	        Cpanel::FileUtils::Link::safeunlink($full_path_cache_file);
	    }
	}
}

1;
