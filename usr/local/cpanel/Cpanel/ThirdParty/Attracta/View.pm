#	Cpanel::ThirdParty::Attracta::View.pm
#	Created by Attracta Online Services, Inc. http://www.attracta.com
#	Copyright (c) 2013 Attracta. All rights reserved. Copying is prohibited
#	The following code is subject to the General Embedded License Agreement for Use With Attracta
#	This license can be found at /usr/local/cpanel/3rdparty/attracta/LICENSE
#	Unauthorized use is prohibited

package Cpanel::ThirdParty::Attracta::View;

use strict;
use Class::Std::Utils;
{
    use Cpanel::Config::LoadCpUserFile                 ();
    use Cpanel::LiveAPI                                ();
    use Cpanel::Logger                                 ();
    use Cpanel::ThirdParty::Attracta::AttractaAPI      ();
    use Cpanel::ThirdParty::Attracta::Validation       ();
    use Template                                       ();

    my $logger = Cpanel::Logger->new();

    my %campaign_of;        #UI campaign
    my %display_vars_of;    #variables passed to template
    my %language_of;        #language to display content in
    my %live_api_of;        #live api object
    my %theme_of;           #cPanel theme
    my %user_of;            #cPanel User

    sub new {
        my ( $class, $options ) = @_;

        my $new_object = bless anon_scalar(), $class;

        if ( $options->{email_only} ) {
            $user_of{ ident $new_object} = $options->{user};
        }
        else {
            $user_of{ ident $new_object}     = $ENV{'REMOTE_USER'};
            $live_api_of{ ident $new_object} = Cpanel::LiveAPI->new();
            $new_object->_set_cpanel_vars();
        }

        return $new_object;
    }

    #build view object
    sub get_live_api {
        my ($self) = @_;

        return $live_api_of{ ident $self};
    }

    sub _get_cpanel_settings {
        my ($self) = @_;

        my $default_settings = {
            RS     => 'x3',
            LOCALE => 'en'
        };

        my $cpanel_settings = Cpanel::Config::LoadCpUserFile::loadcpuserfile( $self->_get_user() );
        if ( ref($cpanel_settings) eq 'HASH' ) {
            $default_settings->{RS}     = $cpanel_settings->{RS}     if Cpanel::ThirdParty::Attracta::Validation::isAlpha( $cpanel_settings->{RS} );
            $default_settings->{LOCALE} = $cpanel_settings->{LOCALE} if Cpanel::ThirdParty::Attracta::Validation::isAlpha( $cpanel_settings->{LOCALE} );

        }
        return $default_settings;
    }

    sub _get_user {
        my ($self) = @_;

        if ( !exists $user_of{ ident $self} ) {
            $user_of{ ident $self} = $ENV{'REMOTE_USER'};
        }

        return $user_of{ ident $self};
    }

    sub _set_cpanel_vars {
        my ($self) = @_;

        my $cpanel_settings = $self->_get_cpanel_settings();

        $language_of{ ident $self} = $cpanel_settings->{LOCALE};
        $theme_of{ ident $self}    = $cpanel_settings->{RS};

        return;
    }

    sub _get_theme {
        my ($self) = @_;
        return $theme_of{ ident $self};
    }

    sub _get_language {
        my ($self) = @_;
        return $language_of{ ident $self};
    }

    sub _get_template_dir {
        my ($self) = @_;
        return '/usr/local/cpanel/base/3rdparty/attracta/templates';
    }

    sub display_template {
        my ( $self, $options, $display_vars ) = @_;

        $display_vars->{lang}   = $self->_get_language();

        my ( $header, $footer ) = $self->_get_cpanel_theme_wrapper();

        $options->{file} .= '_local.tt';	#use local template files

        my $template = Template->new( { INCLUDE_PATH => $self->_get_template_dir() } );

        print "Content-type: text/html\nCache-control: no-cache\r\n\r\n";
        print $header;
        $template->process( $options->{file}, $display_vars ) || $logger->warn( 'ATTRACTA-SEO: Template Error: ' . $template->error() . "\n" );
        print $footer;
        exit;
    }

    sub parse_template {
        my ( $self, $options, $display_vars ) = @_;

        require Template::Service;
        my $template = Template::Service->new( { INCLUDE_PATH => $self->_get_template_dir() } );
        my $parsed_template = $template->process( $options->{file}, $display_vars ) || die $template->error(), "\n";

        return $parsed_template;
    }

    sub get_domain {
        my ($self) = @_;
        require Cpanel::AcctUtils::Domain;
        return Cpanel::AcctUtils::Domain::getdomain( $self->_get_user() );
    }

    #get cPanel header and footer
    sub _get_cpanel_theme_wrapper {
        my ($self) = @_;

        my $theme    = $self->_get_theme();
        my $live_api = $self->get_live_api();

        # /ulc/base/3rdparty/attracta/ down two dirs and into theme dir
        $live_api->api1( 'setvar', '', ("dprefix=../../frontend/$theme/") );

        my $header = $live_api->api1( 'Branding', 'include', ('stdheader.html') );
        my $footer = $live_api->api1( 'Branding', 'include', ('stdfooter.html') );

        return ( $header->{cpanelresult}->{data}->{result}, $footer->{cpanelresult}->{data}->{result} );
    }

    #For tracking remote content and click through
    sub _get_campaign {
        my ($self) = @_;
        return $campaign_of{ ident $self} || '0';
    }

    sub set_campaign {
        my ( $self, $campaign ) = @_;
        $campaign_of{ ident $self} = $campaign;
    } 
    
}
1;
