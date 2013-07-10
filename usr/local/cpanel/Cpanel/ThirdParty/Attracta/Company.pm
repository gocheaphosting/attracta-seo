#	Cpanel::ThirdParty::Attracta::Company.pm
#	Created by Attracta Online Services, Inc. http://www.attracta.com
#	Copyright (c) 2013 Attracta. All rights reserved. Copying is prohibited
#	The following code is subject to the General Embedded License Agreement for Use With Attracta
#	This license can be found at /usr/local/cpanel/3rdparty/attracta/LICENSE
#	Unauthorized use is prohibited

package Cpanel::ThirdParty::Attracta::Company;

use strict;
use Class::Std::Utils;
{
    use Cpanel::CachedDataStore                             ();
    use Cpanel::Logger                                      ();
    use Cpanel::PwCache                                     ();
    use Cpanel::ThirdParty::Attracta::AttractaAPI::Campaign ();
    use Cpanel::ThirdParty::Attracta::AttractaAPI::Sites    ();
    use Cpanel::ThirdParty::Attracta::Cpanel::ContactEmail  ();
    use Cpanel::ThirdParty::Attracta::Cpanel::Sites         ();
    use Cpanel::ThirdParty::Attracta::Server                ();
    use Cpanel::ThirdParty::Attracta::Validation            ();

    my $logger = Cpanel::Logger->new();

    my %attracta_sites_of;    #attracta sites
    my %campaign_of;          #attracta ui campaign
    my %config_dir_of;        #directory where attracta user.config lives
    my %config_file_of;       #user.config filename
    my %config_of;            #user.config data
    my %cpanel_sites_of;      #cpanel websites
    my %email_of;             #user's email address
    my %errors_of;            #errors
    my %homedir_of;           #home directory
    my %matched_sites_of;     #Sites that are in both cPanel and Attracta
    my %primary_domain_of;    #primary cPanel domain
    my %redirects_of;         #cPanel websites that are redirected and cannot use Attracta
    my %sso_url_of;           #user's URL to SSO into Attracta
    my %user_of;              #linux user

    sub new {
        my ( $class, $options ) = @_;

        #$options->{user} = cPanel user to specifically use (rather than $ENV{'REMOTE_USER'})

        my $new_object = bless anon_scalar(), $class;

        $new_object->_set_user($options);
        $new_object->_set_homedir();
        $new_object->_set_config_file();
        $new_object->set_email();

        my @errors = ();
        $errors_of{ ident $new_object} = \@errors;

        return $new_object;
    }

    #---------------------------Linux User----------------------------------#
    sub get_user {
        my ($self) = @_;
        return $user_of{ ident $self};
    }

    sub _set_user {
        my ( $self, $options ) = @_;

        $user_of{ ident $self} = $options->{user} || $ENV{'REMOTE_USER'};
        return;
    }

    sub get_homedir {
        my ($self) = @_;

        if ( !exists $homedir_of{ ident $self} ) {
            $homedir_of{ ident $self} = $self->_set_homedir();
        }
        return $homedir_of{ ident $self};
    }

    sub _set_homedir {
        my ($self) = @_;

        my $homedir = Cpanel::PwCache::gethomedir( $self->get_user() );
        unless ($homedir) {
            $logger->die("ATTRACTA SEO:Unable to create company object. User has no homedir");
        }

        $homedir_of{ ident $self} = $homedir;
        return;
    }

    #---------------------------Attracta----------------------------------#
    sub create_account {
        my ( $self, $options ) = @_;

        my $account = {};
        my $status  = 0;
        my @errors  = ();

        #load up the Attracta Account API
        require Cpanel::ThirdParty::Attracta::AttractaAPI::Account;

        unless ( $options->{email} ) {
            $options->{email} = $self->get_email();

            unless ( $options->{email} ne '' ) {
                $logger->warn('ATTRACTA SEO: Cannot create account. No contact email provided');
                my @errors = ('No contact email provided');
                $self->set_errors( \@errors );
                return $status;
            }
        }

        ( $status, $account ) = Cpanel::ThirdParty::Attracta::AttractaAPI::Account::create( $self->get_user(), $options->{email} );

        if ( $status == 1 ) {
            $self->set_config( { config => $account, save => 1 } );

            if ( $options->{add_sites} ) {
                #don't return errors on failed sites as that will prevent SSO on first use which is worse than lack of site add
				$self->add_pending_sites();
            }
        }
        else {
            unless ( $status eq '3' ) {    #email already exists
                my @errors = ( $account || '' );
                $self->set_errors( \@errors );
            }
        }

        return $status;
    }

    sub get_config_dir {
        my ($self) = @_;
        return $config_dir_of{ ident $self};
    }

    sub _set_config_dir {
        my ( $self, $config_dir ) = @_;

        #create config dir as we'll cache their campaign no matter what
        Cpanel::ThirdParty::Attracta::Validation::existsDir($config_dir);

        $config_dir_of{ ident $self} = $config_dir;
        return;
    }

    sub get_config_file {
        my ($self) = @_;
        return $config_file_of{ ident $self};
    }

    sub _set_config_file {
        my ($self) = @_;

        my $config_dir = $self->get_homedir() . '/.attracta';

        $self->_set_config_dir($config_dir);

        $config_file_of{ ident $self} = $config_dir . '/user.config';
        return;
    }

    #user.config exists and is not 0 bytes
    sub has_config {
        my ($self) = @_;
        return -s $self->get_config_file() ? 1 : 0;
    }

    sub get_config {
        my ($self) = @_;

        if ( !exists $config_of{ ident $self} ) {
            $self->_load_config();
        }

        return $config_of{ ident $self};
    }

    sub set_config {
        my ( $self, $options ) = @_;

        unless ( Cpanel::ThirdParty::Attracta::Validation::check_user_config_data( $options->{config} ) ) {
            return 0;
        }

        $config_of{ ident $self} = $options->{config};

        if ( $options->{save} ) {
            return $self->_save_config( $options->{config} );
        }

        return 1;
    }

    #save userId, companyId, key and username returned by Attracta API (we should never be modifying this after initial creation)
    sub _save_config {
        my ( $self, $config_data ) = @_;

        if ( Cpanel::ThirdParty::Attracta::Validation::existsDir( $self->get_config_dir() ) ) {
            return Cpanel::CachedDataStore::savedatastore(
                $self->get_config_file(),
                { 'data' => $config_data }
            );
        }
        return 0;
    }

    sub _load_config {
        my ($self) = @_;

        my $config_file = $self->get_config_file();

        if ( -f $config_file ) {
            my $config_data = Cpanel::CachedDataStore::loaddatastore( $config_file, 0 );

            if ($config_data) {
                if ( $config_data->{data} ) {

                    #Convert any previous versions with lowercase info
                    if ( $config_data->{data}->{companyid} || $config_data->{data}->{userid} ) {
                        $self->_convert_old_config( $config_data->{data} );
                    }

                    return $self->set_config( { config => $config_data->{data} } );
                }
                else {
                    $logger->warn( 'ATTRACTA-SEO: We expected to get config data from ' . $config_file . ' but we got no data' );
                    return -1;
                }
            }
            else {
                $logger->warn( 'ATTRACTA-SEO: Could load data from ' . $config_file );
                return -1;
            }
        }
        else {
            return 0;
        }
    }

    sub _convert_old_config {
        my ( $self, $config_data ) = @_;

        $config_data->{companyId} = $config_data->{companyid};
        $config_data->{userId}    = $config_data->{userid};
        delete( $config_data->{companyid} );
        delete( $config_data->{userid} );

        return $self->set_config( { config => $config_data, save => 1 } );
    }

    #Campaign for this linux user. Cached at /$home/$user/.attracta/campaign
    sub get_campaign {
        my ($self) = @_;

        if ( !exists $campaign_of{ ident $self} ) {
            $campaign_of{ ident $self} = $self->_load_campaign();
        }

        return $campaign_of{ ident $self};
    }

    sub _load_campaign {
        my ($self) = @_;

        my $campaign;

        if ( -s $self->_get_campaign_file() ) {
            open( my $fh, '<', $self->_get_campaign_file() );
            $campaign = readline($fh);
            close($fh);
            chomp($campaign);
            $campaign = Cpanel::ThirdParty::Attracta::Validation::isInt($campaign) ? $campaign : '';
        }
        else {
            $campaign = Cpanel::ThirdParty::Attracta::AttractaAPI::Campaign::get( $self->get_user() );
            $self->_set_campaign($campaign);
        }

        return Cpanel::ThirdParty::Attracta::Validation::isInt($campaign) ? $campaign : 0;
    }

    sub _set_campaign {
        my ( $self, $campaign ) = @_;

        open( my $fh, '>', $self->_get_campaign_file() );
        print $fh $campaign;
        close($fh);
    }

    sub _get_campaign_file {
        my ($self) = @_;
        return $self->get_config_dir() . '/campaign';
    }

    #Attracta Sites
    sub get_attracta_sites {
        my ( $self, $options ) = @_;

        if ( $options->{no_cache} ) {
            $attracta_sites_of{ ident $self} = $self->_load_attracta_sites($options);
        }

        if ( !exists $attracta_sites_of{ ident $self} ) {
            $attracta_sites_of{ ident $self} = $self->_load_attracta_sites($options);
        }

        return $attracta_sites_of{ ident $self};
    }

    sub _load_attracta_sites {
        my ( $self, $options ) = @_;
        $options->{config} = $self->get_config();

        return Cpanel::ThirdParty::Attracta::AttractaAPI::Sites::get($options) || ();
    }

    sub add_site {
        my ( $self, $site ) = @_;

        return ( Cpanel::ThirdParty::Attracta::AttractaAPI::Sites::add( $self->get_config(), $site ) );
    }

    sub add_site_array {
        my ( $self, $sites ) = @_;

        my $overall_status = 1;
        my @errors         = ();

        unless ( ref($sites) eq 'ARRAY' ) {
            return 0;
        }

        foreach my $site ( @{$sites} ) {
            if ( Cpanel::ThirdParty::Attracta::Validation::isURL($site) ) {
                my ( $status, $response ) = $self->add_site($site);
                unless ($status) {
                    push( @errors, $response );
                    $overall_status = 0;
                }
            }
        }
        if ( scalar(@errors) ) {
            $self->set_errors( \@errors );
			return 4;	#Unable to add some sites
        }

        return $overall_status;
    }

    sub get_pending_sites {
        my ($self) = @_;

        my $attracta_sites = $self->get_attracta_sites( { no_cache => 1 } );

        if ( $attracta_sites eq '2' ) {
            return $attracta_sites;    #company is disabled
        }

        my $cpanel_sites = $self->get_cpanel_sites();

        my @pending_sites = ();

        foreach my $cpanel_site ( @{$cpanel_sites} ) {
            my $found = 0;
            foreach my $attracta_site ( @{$attracta_sites} ) {
                if ( $cpanel_site->{url} eq $attracta_site->{url}->{content} ) {
                    $found = 1;
                    last;
                }
            }
            unless ($found) {
                push( @pending_sites, $cpanel_site );
            }
        }

        return \@pending_sites;
    }

    sub no_pending_sites {
        my ($self) = @_;

        my $pending_sites = $self->get_pending_sites() || ();

		if( ref($pending_sites) ne 'ARRAY'){
			return $pending_sites;	#company is disabled
		}

        return scalar( @{$pending_sites} ) ? 0 : 1;
    }

    sub add_pending_sites {
        my ( $self, $options ) = @_;

        my @errors        = ();
        my $pending_sites = $self->get_pending_sites();

        unless ( ref($pending_sites) eq 'ARRAY' ) {
            return $pending_sites;
        }

        foreach my $site ( @{$pending_sites} ) {
            if ( Cpanel::ThirdParty::Attracta::Validation::isURL( $site->{url} ) ) {
                my ( $status, $response ) = Cpanel::ThirdParty::Attracta::AttractaAPI::Sites::add(
                    $self->get_config(),
                    $site->{url}
                );
                unless ($status) {
                    push( @errors, $response );
                }
            }
        }

        if ( scalar(@errors) ) {
            $self->set_errors( \@errors );
            return 4;
        }
        else {
            return 1;
        }

    }

    sub get_matched_sites {
        my ($self) = @_;

        my $attracta_sites = $self->get_attracta_sites( { no_cache => 1 } );
        if ( $attracta_sites eq '2' ) {
            return $attracta_sites;    #company is disabled
        }

        my $cpanel_sites = $self->get_cpanel_sites();

        my @matched_sites = ();
        foreach my $attracta_site ( @{$attracta_sites} ) {
            my $found = 0;
            foreach my $cpanel_site ( @{$cpanel_sites} ) {
                if ( $cpanel_site->{url} eq $attracta_site->{url}->{content} ) {
                    $found = 1;
                    last;
                }
            }
            if ($found) {
                push( @matched_sites, $attracta_site );
            }
        }

        return \@matched_sites;
    }

    sub get_sso_url {
        my ( $self, $id ) = @_;

        if ( !exists $sso_url_of{ ident $self} ) {
            $sso_url_of{ ident $self} = $self->_load_sso_url($id);
        }

        return $sso_url_of{ ident $self};
    }

    sub _load_sso_url {
        my ( $self, $id ) = @_;

        require Cpanel::ThirdParty::Attracta::AttractaAPI::SSO;

        return Cpanel::ThirdParty::Attracta::AttractaAPI::SSO::get_sso_url( $id, $self->get_config() );
    }

    #adds any cPanel sites not in Attracta, updates info for any sites in Attracta
    #used with ONBOARDED accounts
    sub update_all_sites {
        my ($self) = @_;

        my $attracta_sites = $self->get_attracta_sites( { no_cache => 1 } );

        if ( $attracta_sites eq '2' ) {
            return $attracta_sites;    #company is disabled
        }

        my $cpanel_sites = $self->get_cpanel_sites();
        my $server_id    = Cpanel::ThirdParty::Attracta::Server::getId();

        foreach my $cpanel_site ( @{$cpanel_sites} ) {
            my $found = 0;
            my $site_id;
            my $key;

            foreach my $attracta_site ( @{$attracta_sites} ) {
                if ( $cpanel_site->{url} eq $attracta_site->{url}->{content} ) {
                    $found   = 1;
                    $site_id = $attracta_site->{siteid}->{content};
                    $key     = $attracta_site->{asja}->{content};
                    last;
                }
            }

            if ($found) {

                #update site serverid
                Cpanel::ThirdParty::Attracta::AttractaAPI::Sites::update_site_serverid(
                    $site_id,
                    $key,
                    $server_id
                );
            }
            else {
                #add site to Attracta
                my ( $status, $response ) = Cpanel::ThirdParty::Attracta::AttractaAPI::Sites::add(
                    $self->get_config(),
                    $cpanel_site->{url}
                );
            }
        }

    }

    #---------------------------cPanel----------------------------------#
    sub set_email {
        my ( $self, $email ) = @_;

        my $status = 0;

        if ( Cpanel::ThirdParty::Attracta::Validation::isEmail($email) ) {
            $email_of{ ident $self } = $email;
            $status = 1;
        }
        return $status;
    }

    sub get_email {
        my ($self) = @_;

        if ( !exists $email_of{ ident $self} ) {
            $email_of{ ident $self} = Cpanel::ThirdParty::Attracta::Cpanel::ContactEmail::get();
        }

        return $email_of{ ident $self};
    }

    sub get_cpanel_sites {
        my ($self) = @_;

        if ( !exists $cpanel_sites_of{ ident $self} ) {
            $cpanel_sites_of{ ident $self} = $self->_load_cpanel_sites();
        }

        return $cpanel_sites_of{ ident $self};
    }

    sub _load_cpanel_sites {
        my ($self) = @_;

        return Cpanel::ThirdParty::Attracta::Cpanel::Sites::get( $self->get_user() ) || ();
    }

    sub get_primary_domain {
        my ($self) = @_;
        if ( !exists $primary_domain_of{ ident $self} ) {
            $primary_domain_of{ ident $self} = $self->_load_primary_domain();
        }

        return $primary_domain_of{ ident $self};
    }

    sub _load_primary_domain {
        my ($self) = @_;
        return Cpanel::ThirdParty::Attracta::Cpanel::Sites::get_primary_domain( $self->get_user() );
    }

    sub get_redirects {
        my ($self) = @_;

        if ( !exists $redirects_of{ ident $self} ) {
            $redirects_of{ ident $self} = $self->_load_redirects();
        }

        return $redirects_of{ ident $self};
    }

    sub _load_redirects {
        my ($self) = @_;
        my @redirects = Cpanel::ThirdParty::Attracta::Cpanel::Sites::getRedirects();
        return \@redirects;
    }

    #---------------------------General----------------------------------#
    sub get_errors {
        my ($self) = @_;
        return $errors_of{ ident $self};
    }

    sub set_errors {
        my ( $self, $new_errors ) = @_;

        my $current_errors = $self->get_errors();

        my @all_errors = ( @{$current_errors}, @{$new_errors} );
        $errors_of{ ident $self} = \@all_errors;

        return;
    }
}

1;
