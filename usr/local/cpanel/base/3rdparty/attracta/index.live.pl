#!/usr/bin/perl
#   index.live.pl
#   Created by Attracta Online Services, Inc. http://attracta.com
#	Copyright (c) 2013 Attracta. All rights reserved. Copying is prohibited
#   The following code is subject to the General Embedded License Agreement for Use With Attracta
#   This license can be found at /usr/local/cpanel/3rdparty/attracta/LICENSE
#   Unauthorized use is prohibited

BEGIN {
    unshift( @INC, '/usr/local/cpanel' );

    require Cpanel::Alarm;

    # Server's live socket will timeout at 5 secs.  Attempting to continue could
    #  have unexpected results, including 500 errors or content sent without
    #  proper headers.

    my $alarm = Cpanel::Alarm->new(
        4,
        sub {
            $alarm_msg = 'Attracta index.live.pl taking too long.';
            die $alarm_msg;
        }
    );

    require Cpanel::ThirdParty::Attracta::View;

    undef $alarm;
}

use strict;
use CGI                                       ();
use Cpanel::LoadFile                          ();
use Cpanel::Logger                            ();
use Cpanel::ThirdParty::Attracta::AttractaAPI ();
use Cpanel::ThirdParty::Attracta::Company     ();
use Cpanel::ThirdParty::Attracta::Validation  ();

my $logger = Cpanel::Logger->new();

# This alarm and eval can be removed when LiveAPI is not being used.
# NOTE: Also, exit() calls have been removed: Anecdotal observation saw the
# process end prior to the socket reading the shutdown for LiveAPI, generating
# log errors (and orphaned socket files).
eval {
    #Start output immediately
    $|++;

    # retrieve LiveAPI object so it stays in scope and we can set a reasonable
    #  alarm limit
    my $view = Cpanel::ThirdParty::Attracta::View->new();
    die 'Unable to load cPanel page' if !$view->get_live_api()->isa('Cpanel::LiveAPI');

    my $all_added = 0;                                                                                                 #Whether or not all cPanel sites are Attracta sites
    my $cgi       = CGI->new();
    my $action    = Cpanel::ThirdParty::Attracta::Validation::sanitize( $cgi->param('action') ) || '';
    #my $agree_tos = Cpanel::ThirdParty::Attracta::Validation::sanitize( $cgi->param('agreetos') ) || '';
    my $company   = Cpanel::ThirdParty::Attracta::Company->new();
    my @errors    = ();
    my $id        = Cpanel::ThirdParty::Attracta::Validation::isInt( $cgi->param('id') ) ? $cgi->param('id') : '31';

    # check to ensure Attracta API is working
    unless ( Cpanel::ThirdParty::Attracta::AttractaAPI::check_api() ) {

        #Show api error screen.
        $view->display_template(
            { file  => 'api_down' },
            { email => $company->get_email(), domain => $view->get_domain() }
        );
        exit(1);
    }

    my $company_status = $company->_load_config();    #Whether or not we have a valid config

    #Invalid user.config file
    if ( $company_status eq '-1' ) {
        push( @errors, 'Unable to Access SEO and Marketing Tools. Please contact support' );

        #Show error screen. No company info
        $view->display_template(
            { file  => 'contact_support' },
            { email => $company->get_email(), domain => $view->get_domain(), error => 'Invalid user.config file' }
        );
        exit(1);
    }

    #set the user's campaign
    $view->set_campaign( $company->get_campaign() );

    if ( $action eq 'sso' ) {
        $all_added = 1;
    }
    elsif ( $company_status eq '0' ) {
        if ( $cgi->param('emailaddress') ) {
            $company->set_email( $cgi->param('emailaddress') );
        }


		if ( $company->get_email() ) {
            $all_added = $company->create_account( { email => $company->get_email(), add_sites => 1 } );  
        }
    }
    elsif ( $action eq 'install' ) {
        my @sites_to_install = $cgi->param('toInstall');
        $all_added = $company->add_site_array( \@sites_to_install );
    }
    elsif ($company_status) {
        $all_added = $company->no_pending_sites();
    }

    #pull in any errors from company object
    @errors = ( @errors, @{ $company->get_errors() } );

    if ( $all_added eq '2' ) {

        #account disabled
        $view->display_template(
            { file   => 'disabled' },
            { config => $company->get_config(), email => $company->get_email() }
        );

    }
    elsif ( $all_added eq '1' ) {
		my $sso_url = $company->get_sso_url($id);
        if($sso_url){
			#sso
	        $view->display_template(
	            { file     => 'sso' },
	            { location => $sso_url }
	        );
		}else{
			$view->display_template(
	            { file  => 'contact_support' },
	            { email => $company->get_email(), domain => $view->get_domain(), error => 'Invalid user.config file. Unable to SSO' }
	        );
		}

    }
    elsif ( $all_added eq '3' ) {

        #email already exists, ask them to link tools
        $view->display_template(
            { file => 'login' },
            { id   => $id, email => $company->get_email(), errors => \@errors }
        );
    }
    elsif ( $all_added eq '4' ) {

        #some sites not able to be added
        my @site_list = ( @{ $company->get_pending_sites() }, @{ $company->get_redirects() } );
        $view->display_template(
            { file => 'cms_container' },
            { id   => $id, config => $company->get_config(), sites => \@site_list || (), errors => \@errors }
        );

    }
    else {
        if ($company_status) {

            my $pending_sites = $company->get_pending_sites();

            if ( $pending_sites eq '2' ) {

                #account disabled
                $view->display_template(
                    { file   => 'disabled' },
                    { config => $company->get_config(), email => $company->get_email() }
                );
            }
            else {
                #show list of pending sites and access tools button
                my @site_list = ( @{$pending_sites}, @{ $company->get_redirects() } );
                $view->display_template(
                    { file => 'cms_container' },
                    { id   => $id, config => $company->get_config(), sites => \@site_list || (), errors => \@errors }
                );
            }
        }
        else {
            #no config, show registration page
            $view->display_template(
                { file  => 'register' },
                { email => $company->get_email(), id => $id, errors => \@errors }
            );
        }
    }

    1;
} or do {

    # we should never be here
    if ($@) {
        $logger->warn($@);
    }
    else {
        $logger->warn("Unknown error while trying to process attracta/index.live.pl");
    }

    printGenericError();
    exit;

};

sub printGenericError {
    my $raw_contents = Cpanel::LoadFile::loadfile('/usr/local/cpanel/base/frontend/x3/error-500-generic.html');

    # remove doctype decl. since it's likely to have already been sent
    my @contents = split( /<html/, $raw_contents, 2 );
    print "<html $contents[1]";
}
