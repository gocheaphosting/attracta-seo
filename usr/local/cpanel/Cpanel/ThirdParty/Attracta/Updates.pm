#	Cpanel::ThirdParty::Attracta::Updates.pm
#	Created by Attracta Online Services, Inc. http://attracta.com
#	Copyright (c) 2013 Attracta. All rights reserved. Copying is prohibited
#	The following code is subject to the General Embedded License Agreement for Use With Attracta
#	This license can be found at /usr/local/cpanel/3rdparty/attracta/LICENSE
#	Unauthorized use is prohibited

package Cpanel::ThirdParty::Attracta::Updates;

use strict;
use Cpanel::Logger                                     ();
use Cpanel::LoadFile::Tiny                             ();
use Cpanel::SafeFile                                   ();
use Cpanel::ThirdParty::Attracta::AttractaAPI::Updates ();
use Cpanel::ThirdParty::Attracta::Validation           ();
use Crypt::OpenSSL::RSA                                ();
use Fcntl                                              ();
use Net::SSLeay                                        ();

my $logger = Cpanel::Logger->new();

sub _updates_dir {
    return '/var/cpanel/attracta/updates/';
}

sub update {
    my $verbose = $_[0];

    my ( $updates_available, $updates_message ) = Cpanel::ThirdParty::Attracta::AttractaAPI::Updates::check();

    if ( $updates_available == 1 ) {
        if ($verbose) {
            print "Updates available. Getting update information from Attracta\n";
        }
        my ( $download_status, $downloads ) = Cpanel::ThirdParty::Attracta::AttractaAPI::Updates::get();

        if ( $download_status == 1 ) {
            if ( ref($downloads) eq 'ARRAY' ) {
                if ($verbose) {
                    print "Updates found. Downloading updates.\n";
                }
                my @downloads = @{$downloads};

                foreach my $download (@downloads) {
                    if ($verbose) {
                        print "Updating Attracta Component. Check /usr/local/cpanel/logs/error_log for any errors\n";
                    }
                    if ( Cpanel::ThirdParty::Attracta::Updates::download_update($download) ) {
                        if ( Cpanel::ThirdParty::Attracta::Updates::verify_update($download) ) {
                            Cpanel::ThirdParty::Attracta::Updates::execute_update($download);
                        }
                    }

                }
            }
            else {
                if ($verbose) {
                    print "Updates available but we could not find the downloads. Please contact Attracta Support.\n";
                }
                $logger->warn("ATTRACTA SEO: Updates are available for your server but they could not be found from the API. Please contact Attracta Support.");
            }
        }
    }
    else {
        if ($verbose) {
            print "All components are up to date.\n";
        }
    }
}

sub download_update {
    my $download = shift;

    my $download_file      = Cpanel::ThirdParty::Attracta::Validation::isUpdateFile( $download->{loc} )      ? $download->{loc} : '';
    my $download_signature = Cpanel::ThirdParty::Attracta::Validation::isUpdateSignature( $download->{sig} ) ? $download->{sig} : '';

    unless ( $download_file && $download_signature ) {
        $logger->die('ATTRACTA SEO: Invalid Attracta download locations. Something malicious may be going on. Please check your DNS to make sure it is not hijacked');
    }

    unless ( Cpanel::ThirdParty::Attracta::Validation::existsDir( _updates_dir() ) ) {
        $logger->die('ATTRACTA SEO: Unable to create directory to hold Attracta SEO and Marketing Tools updates');
    }

    my $update_file_name           = _updates_dir() . $download_file;
    my $update_signature_file_name = _updates_dir() . $download_signature;

    my $archive_downloaded   = 0;
    my $signature_downloaded = 0;

    #download update .sea
    my ( $sea_contents, $sea_result ) = Net::SSLeay::get_https( _update_host(), 443, '/static/download/' . $download_file );
    if ( $sea_result =~ /HTTP\/1.[0|1] 200 OK/ ) {
        $archive_downloaded = _write_update( $update_file_name, $sea_contents );
    }

    #download update signature
    my ( $asc_contents, $asc_result ) = Net::SSLeay::get_https( _update_host(), 443, '/static/download/' . $download_signature );
    if ( $asc_result =~ /HTTP\/1.[0|1] 200 OK/ ) {
        $signature_downloaded = _write_update( $update_signature_file_name, $asc_contents );
    }

    if ( $signature_downloaded && $archive_downloaded ) {
        return 1;
    }
    else {
        Cpanel::FileUtils::Link::safeunlink($update_signature_file_name);
        Cpanel::FileUtils::Link::safeunlink($update_file_name);
        $logger->warn('ATTRACTA SEO: Unable to download both an update and its signature. Will try again later');
        $logger->warn("ATTRACTA-SEO: update: $archive_downloaded sig: $signature_downloaded");
    }

    return 0;
}

sub _write_update {
    my ( $file_name, $file_contents ) = @_;

    if ( sysopen( my $fh, $file_name, &Fcntl::O_CREAT | &Fcntl::O_TRUNC | &Fcntl::O_WRONLY | &Fcntl::O_NOFOLLOW, 0600 ) ) {
        flock( $fh, &Fcntl::LOCK_EX );
        {
            print $fh $file_contents;
        }
        flock( $fh, &Fcntl::LOCK_UN );
        return 1;
    }
    return 0;
}

sub verify_update {
    my $download = shift;

    my $download_file      = Cpanel::ThirdParty::Attracta::Validation::isUpdateFile( $download->{loc} )      ? $download->{loc} : '';
    my $download_signature = Cpanel::ThirdParty::Attracta::Validation::isUpdateSignature( $download->{sig} ) ? $download->{sig} : '';

    unless ( $download_file && $download_signature ) {
        $logger->die('ATTRACTA SEO: Invalid Attracta download locations. Something malicious may be going on. Please check your DNS to make sure it is not hijacked');
    }

    my $update_file_name           = _updates_dir() . $download_file;
    my $update_signature_file_name = _updates_dir() . $download_signature;

    my $update_file_contents    = Cpanel::LoadFile::Tiny::loadfile($update_file_name);
    my $signature_file_contents = Cpanel::LoadFile::Tiny::loadfile($update_signature_file_name);
    my $public_key              = _public_key();

    my $rsa = Crypt::OpenSSL::RSA->new_public_key($public_key);

    my $result = $rsa->verify( $update_file_contents, $signature_file_contents );

    if ( $result == 1 ) {
        return 1;
    }

    $logger->warn("ATTRACTA SEO: Could not verify Attracta Update Signature. Removing Update Files as they may be malicious");
    Cpanel::FileUtils::Link::safeunlink($update_file_name);
    Cpanel::FileUtils::Link::safeunlink($update_signature_file_name);
    return 0;
}

sub execute_update {
    my $download = shift;

    my $download_file = Cpanel::ThirdParty::Attracta::Validation::isUpdateFile( $download->{loc} ) ? $download->{loc} : '';
    unless ($download_file) {
        $logger->die('ATTRACTA SEO: Invalid Attracta download locations. Something malicious may be going on. Please check your DNS to make sure it is not hijacked');
    }

    my $update_file_name = _updates_dir() . $download_file;
    chmod( 0700, $update_file_name );
    system("$update_file_name");
}

sub _public_key {
    my $key = << 'KEY';
-----BEGIN RSA PUBLIC KEY-----
MIIBCgKCAQEA5cCXpSPceWNQE4XGl7d0N1ktk4RlpnYtnDhZm+8Vkk4Lfl1VM4Cf
RAtH9IMlUy8SgBOkZo/82GRVSKPcX2DHop+hCcflY5vxi7EteS266WuI8kkJRN9F
+pKOnKqvEU6bCF8DoWf29yNRa2ATDqv2bs7+bbYfZTtkDIOMIinCQmJLphsyO+MW
risl99oQRieScTJNrPBZxaloO9GKbyZUKRksJjfnb9OUrhWf+d+L3L3SQFUfjZLC
XrJAEnZytIruVZbnG6c7kZkLKoNx2AqOKFVPCl92IYtTi6x+HZqvTfx00A7ee1lb
tkUs/u0K+pdWxoz0qLohE4ZpU2Zzy0QmOwIDAQAB
-----END RSA PUBLIC KEY-----
KEY

    return $key;
}

sub _update_host {
    return 'cdn.attracta.com';
}

1;
