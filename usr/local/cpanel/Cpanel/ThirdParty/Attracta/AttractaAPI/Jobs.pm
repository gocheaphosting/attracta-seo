#	Cpanel::ThirdParty::Attracta::AttractaAPI::Jobs.pm
#	Created by David Koston (david@attracta.com) for Attracta (attracta.com)
#	Copyright (c) 2013 Attracta. All rights reserved. Copying is prohibited
#	The following code is subject to the General Embedded License Agreement for Use With Attracta
#	This license can be found at /usr/local/cpanel/3rdparty/attracta/LICENSE
#	Unauthorized use is prohibited

package Cpanel::ThirdParty::Attracta::AttractaAPI::Jobs;

use strict;
use Cpanel::Logger                                 ();
use Cpanel::ThirdParty::Attracta::AttractaAPI      ();
use Cpanel::ThirdParty::Attracta::Validation       ();
use Cpanel::ThirdParty::Attracta::FastInclude      ();
use Cpanel::ThirdParty::Attracta::Server::Ethernet ();
use Cpanel::ThirdParty::Attracta::Server::Id::Load ();
use Cpanel::ThirdParty::Attracta::Version          ();

my $logger = Cpanel::Logger->new();

sub get {
    my $serverId = Cpanel::ThirdParty::Attracta::Server::Id::Load::load();
    my $ami      = Cpanel::ThirdParty::Attracta::FastInclude::isEnabled();

    if ( Cpanel::ThirdParty::Attracta::Validation::isServerId($serverId) ) {
        my $response = Cpanel::ThirdParty::Attracta::AttractaAPI::sendRequest(
            { format => 'xml', location => '/rpc/api/webhost' },
            (
                do         => 'job-queue',
                serverId   => $serverId,
                ami        => $ami,
                macaddress => Cpanel::ThirdParty::Attracta::Server::Ethernet::getMac() || '-',
                ip         => Cpanel::ThirdParty::Attracta::Server::Ethernet::getIP() || '-',
                hostname   => Cpanel::ThirdParty::Attracta::Server::Ethernet::getHostname() || '-',
                fiv        => Cpanel::ThirdParty::Attracta::Version::getFI() || '-'
            )
        );

        if ($response) {
            if ( $response->{response} ) {
                if ( $response->{response}->{'job-queue'} ) {
                    if ( $response->{response}->{'job-queue'}->{job} ) {
                        return $response->{response}->{'job-queue'}->{job};
                    }
                    else {
                        return 0;
                    }
                }
                else {
                    return 0;
                }
            }
            else {
                $logger->warn("ATTRACTA-SEO: Unable to process daily jobs. API Response not found");
                return -1;
            }
        }
        else {
            $logger->warn("ATTRACTA-SEO: Unable to process daily jobs. Could not connect to Attracta API");
            return -1;
        }

    }
    else {
        $logger->warn("ATTRACTA-SEO: Unable to get ServerId from config. Cannot process daily jobs!");
        return -1;
    }
}

#Processes daily jobs. Warns only on errors
sub processJobs {
    my $job_queue = $_[0];

    #need serverid and mac
    if ( ref($job_queue) eq 'HASH' ) {
        Cpanel::ThirdParty::Attracta::AttractaAPI::Jobs::processJob($job_queue);
        return 1;
    }
    elsif ( ref($job_queue) eq 'ARRAY' ) {
        foreach my $job ( @{$job_queue} ) {
            Cpanel::ThirdParty::Attracta::AttractaAPI::Jobs::processJob($job);
        }
        return 1;
    }
    else {
        $logger->warn('ATTRACTA-SEO: Tried to run daily jobs but no jobs found.');
    }
}

#Processes a job, warns only on errors
sub processJob {
    my ($job) = @_;

    my $status;

    if ( $job->{name} ) {
        if ( $job->{name}->{content} eq 'add-siterobots' ) {

            #adding a sitemap to /robots.txt
            require Cpanel::ThirdParty::Attracta::Jobs::Robots;
            $status = Cpanel::ThirdParty::Attracta::Jobs::Robots::add_sitemap_to_robots( $job->{options}->{'site-url'}->{content}, $job->{options}->{siteid}->{content} );
        }
		elsif ( $job->{name}->{content} eq 'fix-all-perms' ) {

            #fix any permissions issues with local attracta user files
            require Cpanel::ThirdParty::Attracta::Jobs::Server::FixPerms;
            $status = Cpanel::ThirdParty::Attracta::Jobs::Server::FixPerms::fix_all_perms();
        }
		elsif ( $job->{name}->{content} eq 'fix-user-perms' ) {

            #fix any permissions issues with local attracta user files
            require Cpanel::ThirdParty::Attracta::Jobs::Server::FixPerms;
            $status = Cpanel::ThirdParty::Attracta::Jobs::Server::FixPerms::fix_user_perms( $job->{options}->{'site-url'}->{content} );
        }
        elsif ( $job->{name}->{content} eq 'link-cpanel' ) {

            #verify ownership of a user added off-server
            require Cpanel::ThirdParty::Attracta::Jobs::User;
            $status = Cpanel::ThirdParty::Attracta::Jobs::User::link_cpanel(
                {
                    user         => $job->{options}->{linuxuser}->{content},
                    token        => $job->{options}->{token}->{content},
                    company_data => {
                        companyId => $job->{options}->{'companyid'}->{content},
                        key       => $job->{options}->{'key'}->{content},
                        userId    => $job->{options}->{'userid'}->{content},
                        username  => $job->{options}->{'username'}->{content}
                    }
                }
            );
        }
        elsif ( $job->{name}->{content} eq 'remove-siterobots' ) {

            #removing a sitemap from /robots.txt
            require Cpanel::ThirdParty::Attracta::Jobs::Robots;
            $status = Cpanel::ThirdParty::Attracta::Jobs::Robots::remove_sitemap_from_robots( $job->{options}->{'site-url'}->{content}, $job->{options}->{siteid}->{content} );
        }
        elsif ( $job->{name}->{content} eq 'update-server-sites' ) {

            #ensure valid data to link sites to server
            require Cpanel::ThirdParty::Attracta::Jobs::Server::Sites;
            $status = Cpanel::ThirdParty::Attracta::Jobs::Server::Sites::update();
        }
        elsif ( $job->{name}->{content} eq 'update-server-ips' ) {

            #ensure valid data to link sites to server
            require Cpanel::ThirdParty::Attracta::Jobs::Server::IPS;
            $status = Cpanel::ThirdParty::Attracta::Jobs::Server::IPS::update();
        }
        elsif ( $job->{name}->{content} eq 'update-serverid' ) {

            #update server's attracta id
            require Cpanel::ThirdParty::Attracta::Jobs::Server::Id;
            $status = Cpanel::ThirdParty::Attracta::Jobs::Server::Id::update();
        }
        elsif ( $job->{name}->{content} eq 'update-siteinclude' ) {

            #update contents of .fastinclude file (remove if empty content is sent)
            require Cpanel::ThirdParty::Attracta::Jobs::FastInclude;
            $status = Cpanel::ThirdParty::Attracta::Jobs::FastInclude::update( $job->{options}->{'site-url'}->{content}, $job->{options}->{'content-url'}->{content} );
        }
        elsif ( $job->{name}->{content} eq 'update-site-serverids' ) {
            require Cpanel::ThirdParty::Attracta::Jobs::Server::Id;
            $status = Cpanel::ThirdParty::Attracta::Jobs::Server::Id::update_site_serverids();
        }
        elsif ( $job->{name}->{content} eq 'verify-user-email' ) {

            #send email to domain owner to verify ownership
            require Cpanel::ThirdParty::Attracta::Jobs::User;
            $status = Cpanel::ThirdParty::Attracta::Jobs::User::send_verify_email(
                {
                    url   => $job->{options}->{domain}->{content},
                    email => $job->{options}->{email}->{content},
                    qso   => $job->{options}->{qso}->{content}
                }
            );
        }
        else {
            $status = 501;
        }
    }
    Cpanel::ThirdParty::Attracta::AttractaAPI::Jobs::returnStatus( { jobid => $job->{id}->{content}, status => $status } );

}

#Sends status of job back to api server
#SUCCESS:
#	job completed								200
#FAILURE:
# 	no siteinclude content found on CDN			204
#	could not get content key from CDN			205

#	job data invalid							400
#	invalid user token							401
#	site owner not found						404
#	document root not found						405
#	contact email not found						406

#	internal error prevented execution of job	500
#	job method not found						501
#   connection to Attracta API unavailable      503
#	unable to open robots.txt file				505
#	unable to open .fastinclude file			506
#	unable to create /var/cpanel/attracta		507
#	unable to save user token					508
#	unable to open user_verification file		509
#	unable to connect to sendmail				510
#	unable to load domain cache					511

#	Attracta API returned an error				599

sub returnStatus {
    my ($options) = @_;

    Cpanel::ThirdParty::Attracta::AttractaAPI::sendRequest(
        { format => 'xml', location => '/rpc/api/webhost' },
        (
            do     => 'job-result',
            jobid  => $options->{jobid},
            status => $options->{status}
        )
    );

}

1;
