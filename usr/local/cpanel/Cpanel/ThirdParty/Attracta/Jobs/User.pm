#	Cpanel::ThirdParty::Attracta::Jobs::User.pm
#	Created by Attracta Online Services, Inc. http://attracta.com
#	Copyright (c) 2013 Attracta. All rights reserved. Copying is prohibited
#	The following code is subject to the General Embedded License Agreement for Use With Attracta
#	This license can be found at /usr/local/cpanel/3rdparty/attracta/LICENSE
#	Unauthorized use is prohibited

package Cpanel::ThirdParty::Attracta::Jobs::User;
##
##	This module contains automated site validation functionality
##	utilized by Attracta's Job infrastructure.
##
use strict;
use Cpanel::AccessIds                                  ();
use Cpanel::CachedDataStore                            ();
use Cpanel::DAV::UUID                                  ();
use Cpanel::FileUtils::TouchFile                       ();
use Cpanel::Logger                                     ();
use Cpanel::ThirdParty::Attracta::AttractaAPI::Verify  ();
use Cpanel::ThirdParty::Attracta::Company              ();
use Cpanel::ThirdParty::Attracta::Cpanel::ContactEmail ();
use Cpanel::ThirdParty::Attracta::Cpanel::Owner        ();
use Cpanel::ThirdParty::Attracta::Server::Id::Load     ();
use Cpanel::ThirdParty::Attracta::Server::Ethernet     ();
use Cpanel::ThirdParty::Attracta::Validation           ();
use Cpanel::ThirdParty::Attracta::View                 ();
use Digest::MD5                                        ();
use URI::Escape                                        ();

my $logger = Cpanel::Logger->new();

sub link_cpanel {
    my ($options) = @_;

    unless ( Cpanel::ThirdParty::Attracta::Validation::isCpanelUsername( $options->{user} ) ) {
        return 400;    #invalid job data for linuxuser
    }
    unless ( Cpanel::ThirdParty::Attracta::Validation::isUserToken( $options->{token} ) ) {
        return 400;    #invalid job data for token
    }

    my $link_result  = 500;
    my $token_status = _check_user_token($options);
    unless ( $token_status == 200 ) {
        my $contact_email = Cpanel::ThirdParty::Attracta::Cpanel::ContactEmail::get( $options->{user} );
        if ( Cpanel::ThirdParty::Attracta::Validation::isEmail($contact_email) ) {
            _send_email(
                {
                    file           => 'verify_error',
                    to             => $options->{company_data}->{username},
                    webhost_server => Cpanel::ThirdParty::Attracta::Server::Id::Load::load(),
                    cpanel_user    => $options->{user},
                    user_token     => $options->{token},
                    email          => $contact_email,
                    cms            => 1
                }
            );
        }
        return $token_status;
    }

    #user verified. Add all sites to account
    my ($save_result) = _create_config_and_add_sites($options);
    return $save_result;
}

sub send_verify_email {
    my ($options) = @_;

    my $site_url     = Cpanel::ThirdParty::Attracta::Validation::isURL( $options->{url} )     ? $options->{url}   : '';    #domain provided via signup form/link
    my $signup_email = Cpanel::ThirdParty::Attracta::Validation::isEmail( $options->{email} ) ? $options->{email} : '';    #email provided via signup form/link
    my $qso          = $options->{qso};

    unless ( $site_url && $signup_email && $qso ) {
        return 400;                                                                                                        #Invalid domain data or email data
    }

    my $email_options = _build_email_options($options);

    unless ( Cpanel::ThirdParty::Attracta::Validation::isInt($email_options) ) {
        Cpanel::ThirdParty::Attracta::AttractaAPI::Verify::verify_company( { domain => $site_url, email => $email_options->{to} } );
        return _send_email($email_options);
    }

    return $email_options;
}

sub _create_config_and_add_sites {
    my ($options) = @_;
    unless ( Cpanel::ThirdParty::Attracta::Validation::isCpanelUsername( $options->{user} ) ) {
        return 400;
    }
    if ( Cpanel::ThirdParty::Attracta::Validation::check_user_config_data( $options->{company_data} ) ) {
        my $result;
        Cpanel::AccessIds::do_as_user(
            $options->{user},
            sub {
                return _save_config_add_pending($options);

            }
        );
    }
    else {
        return 400;
    }

}

sub _save_config_add_pending {
    my ($options) = @_;

    my $company = Cpanel::ThirdParty::Attracta::Company->new( { user => $options->{user} } );
    my $save_result = $company->set_config( { config => $options->{company_data}, save => 1 } );
    my $add_pending_result;

    if ($save_result) {

        #add pending sites, update server ids on any sites that currently exist in account from this server
        $company->update_all_sites();

        #this is considered successful even if all sites cannot be added or updated as long as company info is saved
        return 200;
    }

    return 500;
}

sub _build_email_options {
    my ($options) = @_;

    #find linux user based on site
    my $site_owner = Cpanel::ThirdParty::Attracta::Cpanel::Owner::get( $options->{url} );
    unless ( Cpanel::ThirdParty::Attracta::Validation::isCpanelUsername($site_owner) ) {
        return $site_owner;    #if this is a status code, return it to job-result
    }

    $options->{user} = $site_owner;

    #see if contact email
    my $contact_email = Cpanel::ThirdParty::Attracta::Cpanel::ContactEmail::get($site_owner);
    unless ( Cpanel::ThirdParty::Attracta::Validation::isEmail($contact_email) ) {
        return $contact_email;    #if this is a status code, return it to job-result
    }

    $options->{contact_email} = $contact_email;

    my $user_token = _generate_user_token( $options->{user} );

    if ( Cpanel::ThirdParty::Attracta::Validation::isUserToken($user_token) ) {
        $options->{token} = $user_token;
        $options->{key}   = _generate_key($user_token);
        return {
            file        => 'verify',
            to          => $options->{contact_email},
            url         => _build_encoded_url($options),
            email       => $options->{email},
            cpanel_user => $options->{user},
            domain      => $options->{url},
            cms         => 1
        };
    }
    else {
        return $user_token;
    }
}

sub _build_encoded_url {
    my ($options) = @_;

    my $url = $options->{qso} . '/signup/activate/?do=validate&linuxuser=' . $options->{user} . '&email=' . URI::Escape::uri_escape( $options->{email} ) . '&domain=' . URI::Escape::uri_escape( $options->{url} ) . '&token=' . URI::Escape::uri_escape( $options->{token} ) . '&key=' . URI::Escape::uri_escape( $options->{key} );

    return $url;
}

sub _check_user_token {
    my ($options) = @_;

    my $status = 500;

    my $config_file = '/var/cpanel/attracta/user_verification';

    if ( Cpanel::ThirdParty::Attracta::Validation::isFile($config_file) ) {
        my $config_data = Cpanel::CachedDataStore::loaddatastore( $config_file, 0 );
        if ($config_data) {
            if ( $config_data->{data} ) {
                if ( $config_data->{data}->{ $options->{user} } ) {
                    if ( $config_data->{data}->{ $options->{user} } eq $options->{token} ) {
                        $status = 200;    #user token valid
                    }
                    else {
                        $status = 401;    #user token invalid
                    }
                }
            }
        }
        else {
            $status = 509;                #unable to load user_verification file
        }
    }

    #check token hash for linuxuser and token
    return $status;
}

sub _generate_user_token {
    my $linux_user = Cpanel::ThirdParty::Attracta::Validation::isCpanelUsername( $_[0] ) ? $_[0] : '';
    unless ($linux_user) {
        return 400;                       #Invalid data
    }

    my $user_token = Cpanel::DAV::UUID::generate() . '-' . time();

    my $result = _save_user_token( $linux_user, $user_token );

    if ( $result eq '200' ) {
        return $user_token;
    }
    return $result;
}

sub _generate_key {
    my ($user_token) = @_;

    my $key_string = _build_key_string($user_token);
    my $key        = Digest::MD5::md5_hex($key_string);

    return $key;
}

sub _build_key_string {
    my ($site_token) = @_;

    my ( $day, $mon, $year ) = ( localtime() )[ 3 .. 5 ];
    my $date = sprintf( "%04d-%02d-%02d", $year + 1900, $mon + 1, $day );

    return $site_token . '-he' . '9#2h(' . '29h-' . $date;

}

sub _save_user_token {
    my ( $linux_user, $user_token ) = @_;

    unless ( Cpanel::ThirdParty::Attracta::Validation::isUserToken($user_token) ) {
        $logger->warn( 'ATTRACTA SEO: Unable to generate user verification token for ' . $linux_user );
        return 500;    #plugin error
    }

    my $config_path = '/var/cpanel/attracta/';
    my $config_file = $config_path . 'user_verification';

    if ( Cpanel::ThirdParty::Attracta::Validation::existsDir($config_path) ) {
        my $config_data;

        if ( -f $config_file ) {
            chmod( 0600, $config_file );
            $config_data = Cpanel::CachedDataStore::loaddatastore( $config_file, 0 );
            unless ($config_data) {
                $logger->warn( 'ATTRACTA SEO: Unable to load user verification file: ' . $config_file );
                return 509;    #plugin error, could not load verfication store
            }
        }
        else {
            Cpanel::FileUtils::TouchFile::touchfile( $config_file, 0600 );
        }

        $config_data->{data}->{$linux_user} = $user_token;

        my $result = Cpanel::CachedDataStore::savedatastore(
            $config_file,
            { 'data' => $config_data->{data} }
        );
        if ($result) {
            return 200;
        }
        else {
            return 508;    #failed to save user token
        }
    }
    else {
        return 507;        #failed to create config directory
    }
}

sub _get_root_email {
    my $root_mail = 'cpanel@' . Cpanel::ThirdParty::Attracta::Server::Ethernet::getHostname();
    my $conf      = Cpanel::Config::LoadWwwAcctConf::loadwwwacctconf();
    return $conf->{'CONTACTEMAIL'} || $root_mail;
}

sub _send_email {
    my ($options) = @_;

    my $view = Cpanel::ThirdParty::Attracta::View->new( { email_only => 1, user => $options->{cpanel_user} } );

    my ( $body, $subject );

    my $email_sent = '500';
    $options->{from} = 'Your SEO and Marketing Tools <' . _get_root_email() . '>';

   	#get email content
    $body = $view->parse_template( { file => $options->{file} }, $options );

    if ($body) {
        if ( $options->{file} eq 'verify' ) {
            $subject = 'Enable your SEO and Marketing Tools Enhanced Features';
        }
        elsif ( $options->{file} eq 'verify_error' ) {
            $subject = 'Unable to enable SEO and Marketing Tools Enhanced Features';
        }

        if ($subject) {
            $options->{subject} = $subject;
            $options->{body}    = $body;

            $email_sent = _fire_email($options);
        }
    }

    #send email, record response
    return $email_sent;
}

sub _fire_email {
    my ($options) = @_;

    require Email::MIME;

    my $email = Email::MIME->create(
        header_str => [
            From    => $options->{from},
            To      => $options->{to},
            Subject => $options->{subject},
        ],
        body_str   => $options->{body},
        attributes => {
            charset      => 'utf-8',
            encoding     => 'quoted-printable',
            content_type => 'text/html'
        }
    );

    open( my $eh, '|/usr/sbin/sendmail -t' ) or return 510;
    print {$eh} $email->as_string;
    close($eh);

    return 200;
}

sub _build_email_body {
    my ( $options, $content_keys ) = @_;

    my $body;

    if ( $options->{file} eq 'verify' ) {
        $body = $content_keys->{body0} . $options->{url} . $content_keys->{body1};
    }
    elsif ( $options->{file} eq 'verify_error' ) {
        $body = $content_keys->{body0} . $options->{email} . $content_keys->{body1} . $options->{webhost_server} . $content_keys->{body2} . $options->{cpanel_user} . $content_keys->{body3} . $options->{user_token} . $content_keys->{body4} . $options->{email} . $content_keys->{body5};
    }

    return $body;
}

1;
