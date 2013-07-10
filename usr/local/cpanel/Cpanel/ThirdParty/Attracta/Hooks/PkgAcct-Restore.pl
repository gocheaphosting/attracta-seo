#!/usr/bin/perl
#	PkgAcct-Restore.pl
#	Created by Attracta Online Services, Inc. http://attracta.com
#	Copyright (c) 2013 Attracta. All rights reserved. Copying is prohibited
#	The following code is subject to the General Embedded License Agreement for Use With cPanel
#	This license can be found at /usr/local/cpanel/3rdparty/attracta/LICENSE
#	Unauthorized use is prohibited

use strict;

print << "EOM";
	[
		{
			"namespace": "PkgAcct",
			"function": "Restore",
			"stage": "post",
			"hook": "/usr/local/cpanel/Cpanel/ThirdParty/Attracta/Hooks/pkgacct-restore"
		}
	]
EOM
