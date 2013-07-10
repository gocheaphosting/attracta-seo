#	Cpanel::ThirdParty::Attracta::AttractaAPI.pm
#	Created by Attracta Online Services, Inc. http://attracta.com
#	Copyright (c) 2013 Attracta. All rights reserved. Copying is prohibited
#	The following code is subject to the General Embedded License Agreement for Use With Attracta
#	This license can be found at /usr/local/cpanel/3rdparty/attracta/LICENSE
#	Unauthorized use is prohibited

package Cpanel::ThirdParty::Attracta::AttractaAPI;

use strict;
use Cpanel::Alarm                                       ();
use Cpanel::Logger                                      ();
use Cpanel::ThirdParty::Attracta::Validation            ();
use Cpanel::ThirdParty::Attracta::AttractaAPI::Response ();
use Cpanel::ThirdParty::Attracta::Version               ();
use Net::SSLeay                                         ();
use POSIX                                               ();

my $logger = Cpanel::Logger->new();

#Set to 0 for live api, 1 for development api
our $development_mode = 0;

sub sendRequest {
    my ( $options, @form ) = @_;

    #TODO: change that to a reference so it won't get logged during failure
    my $v = Cpanel::ThirdParty::Attracta::Version::get();

    @form = ( @form, ( v => $v ) );

    my $host = Cpanel::ThirdParty::Attracta::AttractaAPI::getHost();

    my ( $page, $response, %reply_headers, $alarm_msg );

    if ($development_mode) {
        print_to_request_log( 'API Request: ' . 'https://' . $host . $options->{location} . '?' . Net::SSLeay::make_form(@form) );
    }

    eval {
        my $alarm = Cpanel::Alarm->new(
            15,
            sub { $alarm_msg = "Unable to connect to Attracta API"; die $alarm_msg; }
        );
        ( $page, $response, %reply_headers ) = Net::SSLeay::post_https(
            $host, 443, $options->{location}, '',
            Net::SSLeay::make_form(@form)
        );
        1;
    } or do {

        if ($alarm_msg) {
            $logger->warn("$alarm_msg");
            return 0;
        }
        else {
            $logger->warn( "Error making Attracta API request: " . $@ );
            die($@);
        }
    };

    if ($development_mode) {
        print_to_request_log( 'API Response: ' . $response );
        print_to_request_log( 'API Data: ' . $page );
    }

    if ( $response =~ /HTTP\/1.[0|1] 200 OK/ ) {
        return Cpanel::ThirdParty::Attracta::AttractaAPI::Response->new(
            {
                format => $options->{format},
                content => $page
            }
        );
    }
    else {
        return 0;
    }
}

sub check_api {
    my $api_host = Cpanel::ThirdParty::Attracta::AttractaAPI::getHost();

    my ( $page, $response, %reply_headers ) = Net::SSLeay::get_https( $api_host, 443, '/rpc/api/webhost' );

    if ( $response =~ /HTTP\/1.[0|1] 200 OK/ ) {
        my $xml = Cpanel::ThirdParty::Attracta::AttractaAPI::Response->new({ format => 'xml', content => $page});
        if ( Cpanel::ThirdParty::Attracta::Validation::isTimestamp( $xml->{response}->{timestamp}->{content} ) ) {
            return 1;
        }
        else {
            return 0;
        }
    }
    else {
        return 0;
    }
}

sub getHost {
    return $development_mode
      ? 'www-test.attracta.com'
      : 'api-cpanel.attracta.com';
}

sub print_to_request_log {
    my ($data) = @_;

    my $date = '[' . POSIX::strftime( "%Y-%m-%d %H:%M:%S\n", localtime( time() ) ) . ']: ';
    $date =~ s/\n//g;


    my $development_log = '/usr/local/cpanel/logs/attracta_request_log';
	chmod(0777, $development_log);
	open( my $fh, '>>', $development_log ) || $logger->warn('ATTRACTA SEO: Unable to write request log: ' . $development_log);
    print $fh $date . $data . "\n";
    close($fh);
}

1;
