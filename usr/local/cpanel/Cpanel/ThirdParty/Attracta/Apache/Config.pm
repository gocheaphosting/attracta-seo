#	Cpanel::ThirdParty::Attracta::Apache::Config.pm
#	Created by Attracta Online Services, Inc. http://attracta.com
#	Copyright (c) 2013 Attracta. All rights reserved. Copying is prohibited
#	The following code is subject to the General Embedded License Agreement for Use With Attracta
#	This license can be found at /usr/local/cpanel/3rdparty/attracta/LICENSE
#	Unauthorized use is prohibited

package Cpanel::ThirdParty::Attracta::Apache::Config;

use strict;
use Cpanel::EditHttpdconf                         ();
use Cpanel::HttpUtils::ApRestart                  ();
use Cpanel::Logger                                ();
use Cpanel::RcsRecord                             ();
use Cpanel::SafeRun::Full                         ();
use Cpanel::ThirdParty::Attracta::Apache          ();
use Cpanel::ThirdParty::Attracta::Server::Command ();

my $logger = Cpanel::Logger->new();

my $apache_dir = '/usr/local/apache';

# Adds a LoadModule line in httpd.config
#  optionally restart apache
#
# this is a fairly simplistic way to inject the directive, but it should work
# without side effects
sub loadModule {
    my ($do_apache_restart) = @_;
    my $add_line_ref = sub {
        my ( $rw_fh, $safe_replace_content_coderef ) = @_;
        my @new_content;
        my $added_line;
        my $comment_line_count = scalar( split( /\n/, Cpanel::AdvConfig::apache::httpd_conf_header_comments('2') ) );
        my $line_nu = 0;

        # this loop depends on cPanel header and at least one load module;
        #  if those conditions aren't met, we should probably bail/not
        #  attempt any guesses
        while ( my $line = readline($rw_fh) ) {
            $line_nu++;
            chomp $line;

            if ($added_line) {

                # save line if it's not an additional/old, directive
                if ( $line !~ m/^\s*#?\s*LoadModule\s+fastinclude_module/ ) {
                    push @new_content, "$line\n";
                }
            }
            elsif ( $line_nu < $comment_line_count ) {

                # in comments, just save and goto next line
                push @new_content, "$line\n";
            }
            else {

                # inject directive after first LoadModule directive
                if ( $line =~ m/^\s*LoadModule/ ) {
                    push @new_content, "$line\nLoadModule fastinclude_module modules/mod_fastinclude.so\n";
                    $added_line = 1;
                }
                else {
                    push @new_content, "$line\n";
                }
            }
        }

        if ( $safe_replace_content_coderef->( $rw_fh, \@new_content ) ) {
            return '0E0';    #don't record new version of file; easier to reset if other ops fail later
        }
        return;
    };

    if ( !Cpanel::EditHttpdconf::edit_httpdconf($add_line_ref) ) {
        #tidyoff
        $logger->warn(
            "Failed to add LoadModule directive for mod_fastinclude in httpd.conf.\n"
          . "Leaving conf file in broke state for manual inspection."
        );
        #tidyon
        return;
    }
    elsif ( !Cpanel::ThirdParty::Attracta::Apache::Config::save("Added mod_fastinclude directive") ) {
        #tidyoff
        $logger->warn(
            "Failed to save httpd.conf after adding LoadModule directive for mod_fastinclude.\n"
          . "Leaving conf file in broke state for manual inspection."
        );
        #tidyon
        return;
    }

    if ( $do_apache_restart && !Cpanel::HttpUtils::ApRestart::safeaprestart( { 'force' => 1 } ) ) {
        $logger->warn("Failed to restart Apache after adding LoadModule directive for mod_fastinclude");
        return;
    }
    return 1;
}

# Removes a LoadModule line from httpd.confg
#  optionally restart apache (if there were changes)
sub removeModule {
    my ($do_apache_restart) = @_;
    my $found               = 0;
    my $remove_line_ref     = sub {
        my ( $rw_fh, $safe_replace_content_coderef ) = @_;
        my @new_content;
        while ( my $line = readline($rw_fh) ) {
            chomp $line;
            if ( $line =~ m/^\s*#?\s*LoadModule\s+fastinclude_module\s+modules\/mod_fastinclude\.so\s*$/ ) {
                $found = 1;
            }
            else {
                push @new_content, "$line\n";
            }
        }

        return '0EO' if !$found;    #don't replace, nothing has changed.

        if ( $safe_replace_content_coderef->( $rw_fh, \@new_content ) ) {
            return '0E0';           #don't record new version of file; easier to reset if other ops fail later
        }
        return;
    };

    if ( !Cpanel::EditHttpdconf::edit_httpdconf($remove_line_ref) ) {
        #tidyoff
        $logger->warn(
            "Failed to remove LoadModule directive for mod_fastinclude in httpd.conf.\n"
          . "Leaving conf file in broke state for manual inspection."
        );
        #tidyon
        return;
    }

    return 1 if ( !$found );    # go head an exit, the directive wasn't found and nothing was changed

    if ( !Cpanel::ThirdParty::Attracta::Apache::Config::save("Removed mod_fastinclude directive") ) {
        #tidyoff
        $logger->warn(
            "Failed to save httpd.conf after removing LoadModule directive for mod_fastinclude.\n"
          . "Leaving conf file in broke state for manual inspection."
        );
        #tidyon
        return;
    }

    if ( $do_apache_restart && !Cpanel::HttpUtils::ApRestart::safeaprestart( { 'force' => 1 } ) ) {
        #tidyoff
        $logger->warn(
            "Failed to restart Apache after adding LoadModule directive for mod_fastinclude.\n"
          . "Leaving conf file in broke state for manual inspection."
        );
        #tidyon
        return;
    }
    return 1;
}

### NOTE: cPanel systems never use `co`...it for logging change only!
#rolls back httpd.conf to the latest rcs version
#sub rollback {
#
#    #wait for 5 seconds to make sure whatever we were doing previous completes
#    sleep 5;
#    my $checkout_result = Cpanel::ThirdParty::Attracta::Server::Command::executeForkedTask("co -f $apache_dir/conf/httpd.conf");
#    if ( $checkout_result =~ /done/ ) {
#        return Cpanel::HttpUtils::ApRestart::safeaprestart();
#    }
#    else {
#        $logger->warn("ATTRACTA-SEO: Unable to roll back to previous Apache version. Check httpd.conf");
#        return 0;
#    }
#}

# save apache configuration
#  TODO: review this with J.D.
sub save {
    my ($rcs_msg) = @_;

    # run distiller.  this will update /var/cpanel/conf/apache/main
    my %cmd = (
        'program' => '/usr/local/cpanel/bin/apache_conf_distiller',
        'args'    => [ '--update', '--main' ],
    );

    #tidyoff
    my $distiller = Cpanel::SafeRun::Full::run(%cmd);
    if ( ( !$distiller )
      || ( $distiller->{'stderr'} )
      || ( $distiller->{'status'} != 1 )
      || ( $distiller->{'stdout'} !~ /Distilled successfully/ )
      ) {
        my $msg = "Failed to distill Apache configuration";
        if ( ref $distiller eq 'HASH' ) {
            #tidyoff
            $msg .= " Internal Message: " . $distiller->{'message'} || "";
            $msg .= " Exit: " . $distiller->{'status'}              || "Unknown";
            $msg .= " STDERR: " . $distiller->{'stderr'}            || "";
            $msg .= " STDOUT: " . $distiller->{'stdout'}            || "";
            #tidyon
        }
        $logger->warn($msg);
        return;
    }

    #tidyon
    Cpanel::RcsRecord::rcsrecord( "$apache_dir/conf/httpd.conf", $rcs_msg );

    return 1;
}

1;
