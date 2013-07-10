#	Cpanel::ThirdParty::Attracta::Validation.pm
#	Created by Attracta Online Services, Inc. http://attracta.com
#	Copyright (c) 2013 Attracta. All rights reserved. Copying is prohibited
#	The following code is subject to the General Embedded License Agreement for Use With Attracta
#	This license can be found at /usr/local/cpanel/3rdparty/attracta/LICENSE
#	Unauthorized use is prohibited

package Cpanel::ThirdParty::Attracta::Validation;

use strict;
use Cpanel::Logger                       ();
use Cpanel::AccessIds::ReducedPrivileges ();
use Cpanel::FileUtils::TouchFile         ();
use Cpanel::SafeDir::MK                  ();
use Cpanel::Validate::EmailRFC           ();

my $logger = Cpanel::Logger->new();

#checks to make sure user.onfig info is valid and safe
sub check_user_config_data {
    my $configData = $_[0];

    my $valid = 1;

    unless ( Cpanel::ThirdParty::Attracta::Validation::isInt( $configData->{companyId} ) ) {
        $logger->warn('ATTRACTA-SEO: Invalid company id');
        $valid = 0;
    }
    unless ( Cpanel::ThirdParty::Attracta::Validation::isInt( $configData->{userId} ) ) {
        $logger->warn('ATTRACTA-SEO: Invalid user id');
        $valid = 0;
    }
    unless ( Cpanel::ThirdParty::Attracta::Validation::isKey( $configData->{key} ) ) {
        $logger->warn('ATTRACTA-SEO: Invalid key');
        $valid = 0;
    }
    unless ( Cpanel::ThirdParty::Attracta::Validation::isUsername( $configData->{username} ) ) {
        $logger->warn('ATTRACTA-SEO: Invalid username');
        $valid = 0;
    }

    return $valid;
}

sub existsDir {    #check if directory exists, create if not
    if ( Cpanel::ThirdParty::Attracta::Validation::isDir( $_[0] ) ) {
        return 1;
    }
    else {
        my $result = 0;

        # make sure to create the directory as the right user. aka, if in WHM
        #  don't let the reseller create root owned resources
        if (   $< == 0
            && defined $ENV{'REMOTE_USER'}
            && $ENV{'REMOTE_USER'} ne 'root' ) {

            $result = Cpanel::SafeDir::MK::safemkdir_as_user( $ENV{'REMOTE_USER'}, $_[0], '0700' );
        }
        else {
            $result = Cpanel::SafeDir::MK::safemkdir( $_[0], '0700' );
        }

        if ( !$result ) {
            my $logger ||= Cpanel::Logger->new();
            $logger->warn("Unable to create directory '$_[0]' for user '$ENV{'REMOTE_USER'}.");
        }
        return $result;
    }
}

sub isAlpha {
    unless ( $_[0] ) { return 0; }
    return $_[0] =~ /^[a-zA-Z0-9]+$/ ? 1 : 0;    #alpha-numeric
}

sub isBuyPath {
    unless ( $_[0] ) { return 0; }
    return $_[0] =~ /^[a-z]+\:[a-z0-9A-Z]+$/ ? 1 : 0;    #alpha-numeric
}

sub isCompanyName {
    unless ( $_[0] ) { return 0; }
    return $_[0] =~ /^[a-zA-Z0-9\-\_\.\&\(\)\+\=\,\' ]+$/
      ? 1
      : 0;                                               #prevent non perl safe chars in company names
}

sub isCpanelUsername {
    unless ( $_[0] ) { return 0; }
    return $_[0] =~ /^[a-zA-Z][a-zA-Z0-9\-]{0,7}$/
      ? 1
      : 0;                                               #alpha-numeric + dashes. starts with letter
}

sub isEthDevice {                                        #alpha-numeric, dash, colon
    unless ( $_[0] ) { return 0; }
    return $_[0] =~ /^[0-9a-zA-Z\-\:]+$/ ? 1 : 0;
}

sub isDir {
    unless ( $_[0] ) { return 0; }
    return -d $_[0] ? 1 : 0;                             #is a directory on the system
}

sub isDomain {
    unless ( $_[0] ) { return 0; }
    return $_[0] =~ /^([a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,6}$/
      ? 1
      : 0;
}

sub isEmail {
    unless ( $_[0] ) { return 0; }
    return Cpanel::Validate::EmailRFC::is_valid( $_[0] ) ? 1 : 0;
}

sub isFile {
    unless ( $_[0] ) { return 0; }
    return -f $_[0] ? 1 : 0;    #is a file on the system
}

sub isInt {
    return $_[0] =~ /^[\d]+$/ ? 1 : 0;
}

sub isIPCSV {
    unless ( $_[0] ) { return 0; }
    return $_[0] =~ /^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?),?)+$/ ? 1 : 0;    #CSV of IPs
}

sub isKey {
    unless ( $_[0] ) { return 0; }
    return $_[0] =~ /^[a-zA-Z0-9]+$/ ? 1 : 0;                                                                                                                                                           #alpha-numeric
}

sub isMacAddress {
    unless ( $_[0] ) { return 0; }
    return $_[0] =~ /^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$/ ? 1 : 0;
}

sub isPhone {
    unless ( $_[0] ) { return 0; }
    return $_[0] =~ /^(\(?\+?[0-9]*\)?)?[0-9_\- \(\)]*$/ ? 1 : 0;
}

sub isPersonName {
    unless ( $_[0] ) { return 0; }
    return $_[0] =~ /^[a-zA-Z\- ]+$/
      ? 1
      : 0;    #accepts last names with spaces and hypens
}

sub isServerId {
    unless ( $_[0] ) { return 0; }
    return isServerIdMD5( $_[0] ) || isServerIDUUID( $_[0] ) ? 1 : 0;    #UUID or 32 char hex
}

sub isServerIdMD5 {
    unless ( $_[0] ) { return 0; }
    return $_[0] =~ /^[0-9a-fA-F]{32}$/ ? 1 : 0;                         #32 char hexadecimal
}

sub isServerIDUUID {
    unless ( $_[0] ) { return 0; }
    return $_[0] =~ /^[0-9]{6}\-[0-9a-f]{8}\-[0-9a-f]{4}\-[0-9a-f]{4}\-[0-9a-f]{4}\-[0-9a-f]{12}\-([0-9]{13}|[0-9]{10})$/ ? 1 : 0;    #server ID
}

sub isSiteIncludeURL {
    unless ( $_[0] ) { return 0; }
    return $_[0] =~ /^https?\:\/\/(cdn|www\-test)\.attracta\.com\/sitemap\/[0-9]+\/siteinclude\.html\?key\=[0-9a-z]+(\&r\=[0-9]+)?$/
      ? 1
      : 0;
}

sub isSSOToken {
    return Cpanel::ThirdParty::Attracta::Validation::isKey( $_[0] );
}

sub isSSOURL {
    unless ( $_[0] ) { return 0; }

    my ( $uri, $query ) = split( /\?/, $_[0], 2 );
    return 0 if ( !$uri || !$query );

    my @uri_segments = split( /\//, $uri );
    return 0 if ( ( scalar @uri_segments ) < 5 );

    my $url = join( '/', (@uri_segments)[ 0 .. 2 ] ) . '/';
    return 0 if ( !Cpanel::ThirdParty::Attracta::Validation::isURL($url) );

    my %params = map { split( /=/, $_, 2 ) } split( /&/, $query );

    #tidyoff
    return 0
      if (
           ( !$params{'do'} || $params{'do'} ne 'sso-login' )
        || ( !$params{'re'} || $params{'re'} !~ m{/link} )
        || (   !$params{'id'}
            || !Cpanel::ThirdParty::Attracta::Validation::isSSOToken( $params{'id'} ) )
      );

    #tidyon
    return 1;
}

sub isTimestamp {
    unless ( $_[0] ) { return 0; }
    my $check  = $_[0] =~ /^[0-9]{10}$/ ? 1 : 0;
    my $check2 = $_[0] =~ /^[0-9]{13}$/ ? 1 : 0;
    return $check || $check2 ? 1 : 0;    #10 or 13 digit timestamp
}
#note: must retain format for backwards compatibility with older auto-update versions
sub isUpdateFile {
    unless ( $_[0] ) { return 0; }
    return $_[0] =~ /^[a-zA-Z0-9\-\_\.]+\.sea$/ ? 1 : 0;
}
#note: must retain format for backwards compatibility with older auto-update versions
sub isUpdateSetting {
    unless ( $_[0] ) { return 0; }
    my $check  = $_[0] =~ /^[0-9]{1,3}\.[0-9]{1,2}$/ ? 1 : 0;
    my $check2 = $_[0] =~ /^(auto|manual|none)$/     ? 1 : 0;
    return $check || $check2 ? 1 : 0;    #auto, manual, none or xxx.xx

}
#note: must retain format for backwards compatibility with older auto-update versions
sub isUpdateSignature {
    unless ( $_[0] ) { return 0; }
    return $_[0] =~ /^[a-zA-Z0-9\-\_\.]+\.sea\.asc$/ ? 1 : 0;
}

sub isURL {
    unless ( $_[0] ) { return 0; }
    return $_[0] =~ /^https?\:\/\/([a-zA-Z0-9\*]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,6}\/$/
      ? 1
      : 0;
}

sub isURLCSV {
    unless ( $_[0] ) { return 0; }
    return $_[0] =~ /^(https?\:\/\/([a-zA-Z0-9\*]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,6}\/,?)+$/    #CSV of domains
      ? 1
      : 0;
}

sub isUsername {                                                                                               #alpha-numeric + dashes  (or an email address)
    unless ( $_[0] ) { return 0; }
    my $check = $_[0] =~ /^[a-zA-Z0-9\-]+$/ ? 1 : 0;
    my $check2 = Cpanel::Validate::EmailRFC::is_valid( $_[0] );
    return $check || $check2 ? 1 : 0;
}

sub isUserToken {
    unless ( $_[0] ) { return 0; }
    return $_[0] =~ /^[0-9a-f]{8}\-[0-9a-f]{4}\-[0-9a-f]{4}\-[0-9a-f]{4}\-[0-9a-f]{12}\-([0-9]{13}|[0-9]{10})$/ ? 1 : 0;    #user validation token
}

sub parseSiteURL {
    my $url = shift;
    $url =~ s/^http:\/\///g;                                                                                                #remove leading http://
    $url =~ s/\/$//g;                                                                                                       #remove trailing /
    $url =~ s/^www.//g;                                                                                                     #remove leading www.
    return $url;
}

sub sanitize {                                                                                                              #Sanitize input field input
    my $text = shift;
    return '' if !$text;
    $text =~ s/([;<>\*\|`&\$!?#\(\)\[\]\{\}:'"\\])/\\$1/g;
    return $text;
}

1;
