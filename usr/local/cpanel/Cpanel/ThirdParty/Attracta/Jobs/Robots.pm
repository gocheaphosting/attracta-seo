#	Cpanel::ThirdParty::Attracta::Jobs::Robots.pm
#	Created by Attracta Online Services, Inc. http://attracta.com
#	Copyright (c) 2013 Attracta. All rights reserved. Copying is prohibited
#	The following code is subject to the General Embedded License Agreement for Use With Attracta
#	This license can be found at /usr/local/cpanel/3rdparty/attracta/LICENSE
#	Unauthorized use is prohibited

package Cpanel::ThirdParty::Attracta::Jobs::Robots;
##
##	This module contains automated robots.txt editing functionality
##	utilized by Attracta's Job infrastructure.
##

use strict;
use Cpanel::AccessIds                             ();
use Cpanel::LoadFile                              ();
use Cpanel::Logger                                ();
use Cpanel::SafeFile                              ();
use Cpanel::ThirdParty::Attracta::Cpanel::DocRoot ();
use Cpanel::ThirdParty::Attracta::Cpanel::Owner   ();
use Cpanel::ThirdParty::Attracta::Validation      ();
use Fcntl                                         ();

my $logger = Cpanel::Logger->new();

sub add_sitemap_to_robots {
    my $site_url = Cpanel::ThirdParty::Attracta::Validation::isURL( $_[0] ) ? $_[0] : '';
    my $site_id  = Cpanel::ThirdParty::Attracta::Validation::isInt( $_[1] ) ? $_[1] : '';

    unless ($site_url) {
        $logger->warn( 'ATTRACTA SEO: Unable to add sitemap for invalid site url: ' . $site_url );
    }
    unless ($site_id) {
        $logger->warn( 'ATTRACTA SEO: Unable to add sitemap for invalid site id: ' . $site_id );
    }
    unless ( $site_url && $site_id ) {
        return 400;    #job data invalid
    }

    my $site_owner = Cpanel::ThirdParty::Attracta::Cpanel::Owner::get($site_url);
    if ( Cpanel::ThirdParty::Attracta::Validation::isCpanelUsername($site_owner) ) {    #if we can find the domain owner
        my ($result) = _add_sitemap_as_user( $site_owner, $site_url, $site_id );
        return $result;
    }
    else {
        return $site_owner;
    }
    return 500;
}

sub _add_sitemap_as_user {
    my ( $site_owner, $site_url, $site_id ) = @_;
    Cpanel::AccessIds::do_as_user(
        $site_owner,
        sub {
            return Cpanel::ThirdParty::Attracta::Jobs::Robots::add_sitemap( $site_url, $site_id, $site_owner );
        }
    );
}

sub add_sitemap {
    my $site_url   = Cpanel::ThirdParty::Attracta::Validation::isURL( $_[0] )            ? $_[0] : '';
    my $site_id    = Cpanel::ThirdParty::Attracta::Validation::isInt( $_[1] )            ? $_[1] : '';
    my $site_owner = Cpanel::ThirdParty::Attracta::Validation::isCpanelUsername( $_[2] ) ? $_[2] : '';

    unless ( $site_url && $site_id && $site_owner ) {
        return 400;    #job data invalid
    }

    my $docroot = Cpanel::ThirdParty::Attracta::Cpanel::DocRoot::get( $site_url, $site_owner );

    if ( Cpanel::ThirdParty::Attracta::Validation::isInt($docroot) ) {
        return $docroot;    #Response code from DocRoot:get to be sent to job-result
    }
    else {
        return Cpanel::ThirdParty::Attracta::Jobs::Robots::install_sitemap( $docroot, $site_id );
    }

    return 500;
}

sub install_sitemap {
    my $docroot = $_[0];
    my $site_id = $_[1];

    my $robots_text = 'sitemap: http://cdn.attracta.com/sitemap/' . $site_id . '.xml.gz' . "\n";
    my $robots_file = $docroot . '/robots.txt';

    my $robots_file_contents = Cpanel::LoadFile::loadfileasarrayref($robots_file);

    my $found_robots_text = 0;

    foreach my $line ( @{$robots_file_contents} ) {
        if ( $line eq $robots_text ) {
            $found_robots_text++;
        }
    }

    my $update_status = 500;

    if ( $found_robots_text > 1 ) {
        $update_status = Cpanel::ThirdParty::Attracta::Jobs::Robots::cleanup_robots( $robots_file_contents, $robots_text, $robots_file );
    }
    elsif ( $found_robots_text == 1 ) {
        $update_status = 200;
    }
    else {
        my $rlock = Cpanel::SafeFile::safeopen( \*ROBOTS, '>>', $robots_file );
        if ($rlock) {
            print ROBOTS "\n#Begin Attracta SEO Tools Sitemap. Do not remove\n";
            print ROBOTS $robots_text;
            print ROBOTS "#End Attracta SEO Tools Sitemap. Do not remove\n";
            Cpanel::SafeFile::safeclose( \*ROBOTS, $rlock );
            $update_status = 200;
        }
        else {
            return 505;
        }
    }

    return $update_status;
}

sub cleanup_robots {
    my $robots_file_contents = $_[0];
    my $robots_text          = $_[1];
    my $robots_file          = $_[2];

    my @lines  = @{$robots_file_contents};
    my $edited = 0;

    #remove existing duplicate sitemaps
    for ( my $i = $#lines; $i >= 0; $i-- ) {
        if ( $lines[$i] eq $robots_text ) {
            splice( @lines, $i - 1, 3 );
            $edited = 1;
        }
    }

    #replace sitemap file contents
    if ($edited) {
        my $rlock = Cpanel::SafeFile::safeopen( \*ROBOTS, '>', $robots_file );
        if ( !$rlock ) {
            $logger->warn("Could not add sitemap to robots.txt at $robots_file");
            return 505;
        }
        foreach my $line (@lines) {
            print ROBOTS $line;
        }
        print ROBOTS "\n#Begin Attracta SEO Tools Sitemap. Do not remove\n";
        print ROBOTS $robots_text;
        print ROBOTS "#End Attracta SEO Tools Sitemap. Do not remove\n";
        Cpanel::SafeFile::safeclose( \*ROBOTS, $rlock );
        return 200;
    }
    else {
        return 200;
    }

}

sub remove_sitemap_from_robots {
    my $site_url = Cpanel::ThirdParty::Attracta::Validation::isURL( $_[0] ) ? $_[0] : '';
    my $site_id  = Cpanel::ThirdParty::Attracta::Validation::isInt( $_[1] ) ? $_[1] : '';

    unless ($site_url) {
        $logger->warn( 'ATTRACTA SEO: Unable to remove sitemap for invalid site url: ' . $site_url );
    }
    unless ($site_id) {
        $logger->warn( 'ATTRACTA SEO: Unable to remove sitemap for invalid site id: ' . $site_id );
    }
    unless ( $site_url && $site_id ) {
        return 400;
    }

    my $site_owner = Cpanel::ThirdParty::Attracta::Cpanel::Owner::get($site_url);
    if ( Cpanel::ThirdParty::Attracta::Validation::isCpanelUsername($site_owner) ) {    #if we can find the domain owner
        my ($result) = _remove_sitemap_as_user( $site_owner, $site_url, $site_id );
        return $result;
    }
    return $site_owner;
}

sub _remove_sitemap_as_user {
    my ( $site_owner, $site_url, $site_id ) = @_;
    Cpanel::AccessIds::do_as_user(
        $site_owner,
        sub {
            return Cpanel::ThirdParty::Attracta::Jobs::Robots::remove_sitemap( $site_url, $site_id, $site_owner );
        }
    );
}

sub remove_sitemap {
    my $site_url   = Cpanel::ThirdParty::Attracta::Validation::isURL( $_[0] )            ? $_[0] : '';
    my $site_id    = Cpanel::ThirdParty::Attracta::Validation::isInt( $_[1] )            ? $_[1] : '';
    my $site_owner = Cpanel::ThirdParty::Attracta::Validation::isCpanelUsername( $_[2] ) ? $_[2] : '';

    unless ( $site_url && $site_id && $site_owner ) {
        return 400;    #job data invalid
    }

    my $docroot = Cpanel::ThirdParty::Attracta::Cpanel::DocRoot::get( $site_url, $site_owner );

    if ( Cpanel::ThirdParty::Attracta::Validation::isInt($docroot) ) {
        return $docroot;    #Response code from DocRoot:get to be sent to job-result
    }
    else {
        return Cpanel::ThirdParty::Attracta::Jobs::Robots::delete_sitemap( $docroot, $site_id );
    }

    return 500;
}

sub delete_sitemap {
    my $docroot = $_[0];
    my $site_id = $_[1];

    my $robots_file          = $docroot . '/robots.txt';
    my $robots_file_contents = Cpanel::LoadFile::loadfileasarrayref($robots_file);

    my @lines               = @{$robots_file_contents};
    my @new_robots_contents = ();

    for ( my $i = 0; $i < scalar(@lines); $i++ ) {
        if ( $lines[$i] =~ /^sitemap: http:\/\/cdn\.attracta\.com\/sitemap\/$site_id\.xml\.gz$/ ) {
            if ( $new_robots_contents[-1] =~ /^\#Begin Attracta SEO Tools Sitemap\. Do not remove\n$/ ) {
                pop(@new_robots_contents);
            }
            if ( $lines[ $i + 1 ] =~ /^\#End Attracta SEO Tools Sitemap\. Do not remove\n$/ ) {
                $i++;
            }
        }
        else {
            push( @new_robots_contents, $lines[$i] );
        }
    }

    my $rlock = Cpanel::SafeFile::safeopen( \*ROBOTS, '>', $robots_file );
    if ( !$rlock ) {
        $logger->warn("ATTRACTA SEO: Could not remove Attracta Sitemap from robots.txt at $robots_file");
        return 505;
    }
    foreach my $line (@new_robots_contents) {
        print ROBOTS $line;
    }
    Cpanel::SafeFile::safeclose( \*ROBOTS, $rlock );
    return 200;
}

1;
