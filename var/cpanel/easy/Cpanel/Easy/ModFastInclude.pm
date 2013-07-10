package Cpanel::Easy::ModFastInclude;


our $easyconfig = {
    'version'    => '$Rev: 1.4 $',
    'name'       => 'Fast Include',
    'note'       => 'Required for Attracta SEO Tools',
	'desc'		 => 'mod_fastinclude allows for the inclusion of content into text/html Apache responses. This allows you to enable features requiring content addtitions to customer web pages.',
    'url'        => 'http://www.attracta.com',
    'src_cd2'    => 'mod_fastinclude',
	'verify_off' => 'If you turn off mod_fastinclude, Attracta SEO Tools may not work properly. Are you sure you wish to turn off mod_fastinclude?',
    'hastargz'   => 1,
	'skip' 	     => 0,
    'step'       => {
        '0' => {
            'name'    => 'Compiling, installing, and activating',
            'command' => sub {
                my ($self) = @_;

                my ($rc, @msg) = $self->run_system_cmd_returnable( [ $self->_get_main_apxs_bin(), qw(-i -a -c fastinclude mod_fastinclude.c)] );
                
                if (!$rc) {
                    $self->print_alert_color('blue', q{apxs failed, you will need to install mod_fastinclude manually});            
                }

                return ($rc, @msg);
            },            
        },
    },    
};

1;
