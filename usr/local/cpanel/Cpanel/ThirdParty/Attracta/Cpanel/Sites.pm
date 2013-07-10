#	Cpanel::ThirdParty::Attracta::Cpanel::Sites.pm
#	Created by Attracta Online Services, Inc. http://attracta.com
#	Copyright (c) 2013 Attracta. All rights reserved. Copying is prohibited
#	The following code is subject to the General Embedded License Agreement for Use With Attracta
#	This license can be found at /usr/local/cpanel/3rdparty/attracta/LICENSE
#	Unauthorized use is prohibited

package Cpanel::ThirdParty::Attracta::Cpanel::Sites;

use strict;
use Cpanel::AcctUtils::Domain   ();
use Cpanel::DomainLookup        ();
use Cpanel::HttpUtils::Htaccess ();
use Cpanel::Logger              ();

my $logger = Cpanel::Logger->new();

sub get {
    my ($user) = @_;

    my $mainDomain  = get_primary_domain($user);
    my @docRoots    = Cpanel::ThirdParty::Attracta::Cpanel::Sites::getDocroots();
    my @baseDomains = Cpanel::ThirdParty::Attracta::Cpanel::Sites::getBaseDomains( \@docRoots );

    #remove sub domains of addon domains and parked domains
    my @allSitesMinusAddonSubs = ();

    for my $i ( 0 .. $#docRoots ) {
	    my $addon = 0;

		#If the domain name is something.$mainDomain, it's either a sub or addon sub
		if( $docRoots[$i]->{domain} =~ /([a-zA-Z0-9\-]+)\.$mainDomain/){
			#now if the first part of the domain name is the same as the folder name, it's a subdomain, not an addon
			if( $docRoots[$i]->{docRoot} !~ /.+$1$/ ){
				$addon = 1;
			}
		}
	    unless ($addon) { push( @allSitesMinusAddonSubs, $docRoots[$i] ); }
	}

    #remove any redirected domains
    my @redirects                       = Cpanel::ThirdParty::Attracta::Cpanel::Sites::getRedirects();
    my @allSitesMinusAddonSubsRedirects = ();

    for my $i ( 0 .. $#allSitesMinusAddonSubs ) {
        my $redirect = 0;
        for my $r ( 0 .. $#redirects ) {
            if ( $redirects[$r]->{url} eq $allSitesMinusAddonSubs[$i]->{url} ) {
                $redirect = 1;
            }
        }
        unless ($redirect) { push( @allSitesMinusAddonSubsRedirects, $allSitesMinusAddonSubs[$i] ); }
    }

    return \@allSitesMinusAddonSubsRedirects;

}

sub get_primary_domain {
    my ($user) = @_;

    return Cpanel::AcctUtils::Domain::getdomain( $user || $ENV{'REMOTE_USER'} );
}

sub getDocroots {
    my $sitesRef = Cpanel::DomainLookup::getdocroots();

    my @docRoots = ();

    while ( my ( $key, $value ) = each %{$sitesRef} ) {
        if ( $key =~ /^\*\./ ) {
            delete( $sitesRef->{$key} );    #Skip *.domain.tld entries
        }
        else {
            push(
                @docRoots,
                { url => 'http://' . $key . '/', docRoot => $value, domain => $key }
            );
        }
    }

    return @docRoots;
}

sub getRedirects {
    my @prelim_redirects = Cpanel::HttpUtils::Htaccess::getredirects();
    my @redirects        = ();

    foreach my $redirect (@prelim_redirects) {
        my $target_url = $redirect->{targeturl};
        $target_url =~ s/http\:\/\///g;
        my $domain = $redirect->{domain};

        #wildcards can be used w/ Attracta
        next if ( $domain eq '.*' || $domain eq '*' );

        #if whole domain is not redirected, can be used w/ Attracta
        next if ( $redirect->{sourceurl} ne '/' );

        #if domain is redirected to self or subdomain of self, can be used w/ Attracta
        next if ( $target_url =~ /^(([a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9]))\.)?$domain\/?/ );

        $redirect->{url} = 'http://' . $domain . '/';
        push( @redirects, $redirect );
    }

    return @redirects;
}

sub getBaseDomains {
    my $docroots = $_[0];

    my $base_domains = Cpanel::DomainLookup::api2_getbasedomains();

    my @only_base_domains = ();

    foreach my $docroot ( @{$docroots} ) {
        foreach my $base_domain ( @{$base_domains} ) {
            if ( $docroot->{domain} eq $base_domain->{domain} ) {
                push( @only_base_domains, $docroot );
            }
        }
    }

    return @only_base_domains;

}

1;
