#	Cpanel::ThirdParty::Attracta::AttractaAPI::Response.pm
#	Created by Attracta Online Services, Inc. http://attracta.com
#	Copyright (c) 2013 Attracta. All rights reserved. Copying is prohibited
#	The following code is subject to the General Embedded License Agreement for Use With Attracta
#	This license can be found at /usr/local/cpanel/3rdparty/attracta/LICENSE
#	Unauthorized use is prohibited

package Cpanel::ThirdParty::Attracta::AttractaAPI::Response;

use strict;
use JSON::Syck   ();
use Cpanel::Logger ();
use XML::Simple    ();

my $logger = Cpanel::Logger->new();

#Create a response object from an Attracta XML string
sub new {
    my ( $class, $options ) = @_;

    unless ( $options->{content} ) {
        $logger->warn('ATTRACTA SEO: No $option->{content} passed to AttractaAPI::Response');
		return 0;
    }

    unless ( $options->{format} ) {
        $options->{format} = 'xml';
    }

    my $response;

    if ( $options->{format} eq 'xml' ) {
        $response = Cpanel::ThirdParty::Attracta::AttractaAPI::Response::xml_to_hash( $options->{content} );

    }
    elsif ( $options->{format} eq 'json' ) {
        $response = JSON::Syck::Load( $options->{content} );
    }

    my $self = bless(
        { 'response' => $response },
        $class
    );

    return $self;
}

#See if the API sent an error with the response
sub has_errored {
    my $self     = shift;
    my $diderror = 0;

    if ( ref( $self->{'response'}->{'errors'} ) eq 'ARRAY' ) { $diderror = 1 }
    if ( ref( $self->{'response'}->{'errors'} ) eq 'HASH' )  { $diderror = 1 }

    return $diderror;
}

sub print_errors {
    my $self = shift;

    if ( ref( $self->{'response'}->{'errors'} ) eq 'ARRAY' ) {
        my @errors = @{ $self->{'response'}->{'errors'} };
        my $error_string;
        foreach my $error (@errors) {
            $error_string .= $error->{'message'}->{'content'} . '<br />';
        }
        return $error_string;
    }
    else {
        return $self->{'response'}->{'errors'}->{'error'}->{'message'}->{'content'} || '';
    }
    return '';
}

#translate the xml to a perl hash
sub xml_to_hash {
    my $xmlstring = shift;

    my $xmlref = XML::Simple::XMLin( $xmlstring, ForceContent => 1 );

    unless ( ref($xmlref) eq 'HASH' ) {
        $logger->warn('ATTRACTA-SEO: Unable to convert XML String to Response object');
        return 0;
    }

    return $xmlref;
}

1;
