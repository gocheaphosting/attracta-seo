#	Cpanel::ThirdParty::Attracta::AttractaAPI::CMS.pm
#	Created by Attracta Online Services, Inc. http://attracta.com
#	Copyright (c) 2013 Attracta. All rights reserved. Copying is prohibited
#	The following code is subject to the General Embedded License Agreement for Use With Attracta
#	This license can be found at /usr/local/cpanel/3rdparty/attracta/LICENSE
#	Unauthorized use is prohibited

package Cpanel::ThirdParty::Attracta::AttractaAPI::CMS;

use strict;
use Cpanel::ThirdParty::Attracta::AttractaAPI ();

# sub get_cobrand{
# 	
# }
# 
# 
# sub get_alt_cobrands{
# 	
# }
# 
# 


sub get_multi {
    my ( $key_list, $lang ) = @_;

    my @params = (
        do     => 'cms-get',
        lang   => $lang,
        format => 'multi',
        key    => $key_list
    );

    my $response = Cpanel::ThirdParty::Attracta::AttractaAPI::sendRequest( { format => 'json', location => '/rpc/ajax' }, @params );

    if ( ref($response) eq 'Cpanel::ThirdParty::Attracta::AttractaAPI::Response' ) {
        if ( !$response->has_errored() ) {
            if ( $response->{response} ) {
                return $response->{response};
            }
        }else{
			return 599;
		}
    }
    return 503;
}

1;
