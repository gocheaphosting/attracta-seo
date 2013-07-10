#	Cpanel::ThirdParty::Attracta::Jobs::FastInclude.pm
#	Created by David Koston (david@attracta.com) for Attracta (attracta.com)
#	Copyright (c) 2013 Attracta. All rights reserved. Copying is prohibited
#	The following code is subject to the General Embedded License Agreement for Use With Attracta
#	This license can be found at /usr/local/cpanel/3rdparty/attracta/LICENSE
#	Unauthorized use is prohibited

package Cpanel::ThirdParty::Attracta::Jobs::FastInclude;

use strict;
use Cpanel::AccessIds                             ();
use Cpanel::AcctUtils::DomainOwner                ();
use Cpanel::Config::userdata::Cache               ();
use Cpanel::FileUtils::Link                       ();
use Cpanel::Logger                                ();
use Cpanel::PwCache                               ();
use Cpanel::ThirdParty::Attracta::Cpanel::DocRoot ();
use Cpanel::ThirdParty::Attracta::Cpanel::Owner   ();
use Cpanel::ThirdParty::Attracta::Validation      ();
use Fcntl                                         ();
use Net::SSLeay                                   ();

my $logger = Cpanel::Logger->new();

sub getIncludeContent {
    my $include_url = shift;

    my ( $server, $uri ) = Cpanel::ThirdParty::Attracta::Jobs::FastInclude::splitIncludeURL($include_url);
    my ( $page, $result );

    if ( $include_url =~ /^https/ ) {
        ( $page, $result ) = Net::SSLeay::get_https( $server, '443', $uri );
    }
    elsif ( $include_url =~ /^http/ ) {
        ( $page, $result ) = Net::SSLeay::get_http( $server, '80', $uri );
    }
    if ( $result =~ /HTTP\/1.(0|1) 200 OK/ ) {
        return ( 1, $page );
    }
    return ( 0, '' );
}

sub getIncludeFile {
    my $site_url   = Cpanel::ThirdParty::Attracta::Validation::isURL( $_[0] )            ? $_[0] : '';
    my $site_owner = Cpanel::ThirdParty::Attracta::Validation::isCpanelUsername( $_[1] ) ? $_[1] : '';

    if ($site_url) {
        my $docroot = Cpanel::ThirdParty::Attracta::Cpanel::DocRoot::get( $site_url, $site_owner );

        if ( Cpanel::ThirdParty::Attracta::Validation::isInt($docroot) ) {
            return $docroot;    #Response code from DocRoot:get to be sent to job-result
        }
        else {
            return $docroot . '/.fastinclude';
        }

    }
    else {
        return 400;             #Invalid content
    }
}

sub splitIncludeURL {
    my $url = shift;
    if ( $url =~ /(^(http|https):\/\/)([a-z\-\.]+.com)(\/.+)/ ) {
        return ( $3, $4 );      #return servername and uri
    }
}

sub update {
    my $site_url    = Cpanel::ThirdParty::Attracta::Validation::isURL( $_[0] )            ? $_[0] : '';
    my $content_url = Cpanel::ThirdParty::Attracta::Validation::isSiteIncludeURL( $_[1] ) ? $_[1] : '';

    my $actioned = 0;

    unless ( $site_url && $content_url ) {
        $logger->warn('ATTRACTA-SEO: FastInclude changes requested for invalid site.');
        return 400;             #invalid site or content from job data
    }

    my ( $include_status, $include_content ) = Cpanel::ThirdParty::Attracta::Jobs::FastInclude::getIncludeContent($content_url);

    if ($include_status) {
        my $site_owner = Cpanel::ThirdParty::Attracta::Cpanel::Owner::get($site_url);
        if ( Cpanel::ThirdParty::Attracta::Validation::isInt($site_owner) ) {
            return $site_owner;    #if this is a status code, return it to job-result
        }

        my $include_file = Cpanel::ThirdParty::Attracta::Jobs::FastInclude::getIncludeFile( $site_url, $site_owner );
        if ( Cpanel::ThirdParty::Attracta::Validation::isInt($include_file) ) {
            return $include_file;    #if this is a status code, return it to job-result
        }

        #delete any old include content
        if ( -f $include_file && Cpanel::ThirdParty::Attracta::Validation::isCpanelUsername($site_owner) ) {
            Cpanel::AccessIds::do_as_user(
                $site_owner,
                sub {
                    Cpanel::FileUtils::Link::safeunlink($include_file);
                }
            );
            $actioned = 1;
        }

        if ($include_content && $include_content !~ /^\s$/ ) {
        	my ($write_result) = _write_include( { file => $include_file, content => $include_content, user => $site_owner } );
        	return $write_result;
        }
        else {
            if ($actioned) {

                #return success on a delete
                return 200;
            }
            else {
                return 500;
            }
        }
    }
    else {
        return 204;
        $logger->warn("ATTRACTA-SEO: Unable to install SEO App. Could not get SEO App code.");
    }

    return 500;
}

sub _write_include {
    my ($options) = @_;

    Cpanel::AccessIds::do_as_user(
        $options->{user},
        sub {
            my $write_include_result = Cpanel::ThirdParty::Attracta::Jobs::FastInclude::writeInclude( $options->{file}, $options->{content} );
            return ($write_include_result);
        }
    );
}

sub writeInclude {
    my $include_file    = $_[0];
    my $include_content = $_[1];

    my $wrote = 500;

    #write or include file by opening for write, creating if it doesn't exist and do not follow symbolic links
    if (
        sysopen(
            my $include_fh,
            $include_file,
            &Fcntl::O_CREAT | &Fcntl::O_RDWR | &Fcntl::O_NOFOLLOW, 0644
        )
      ) {
        flock( $include_fh, &Fcntl::LOCK_EX )
          || $logger->warn("ATTRACTA-SEO: Unable to add SEO App. Could not lock .fastinclude file at $include_file");    #lock our file to prevent alterations
        {
            print $include_fh $include_content
              || $logger->warn("ATTRACTA-SEO: Unable toadd SEO App. Could not write .fastinclude file at $include_file");
        }
        $wrote = 200;
        flock( $include_fh, &Fcntl::LOCK_UN )
          || $logger->warn("ATTRACTA-SEO: Unable to unlock $include_file.");
    }
    else {
		$wrote = 506;
        $logger->warn("ATTRACTA-SEO: Unable to add SEO App. Could not create .fastinclude file at $include_file");
    }
    return $wrote;
}

1;
