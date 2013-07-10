/*	mod_fastinclude.c
 *  Copyright (c) 2013 Attracta. All rights reserved. Copying is prohibited
 *	The following code is subject to the Apache Module Embedded License Agreement for Use With cPanel
 *	This license agreement can be found at /usr/local/cpanel/3rdparty/attracta/mod_fastinclude/COPYING
 *	Unauthorized use is prohibited.
 */
#define MYNAME     "FastInclude"
#define MYVERSION  "1.4"


#include "apr_strings.h"
#include "apr_strmatch.h"
#include "apr_file_io.h"
#include "apr_tables.h"

#define CORE_PRIVATE
#include "httpd.h"
#include "http_config.h"
#include "http_log.h" /* error logging api and piped logs */
#include "http_core.h" /* accessor for request_rec, core_dir_config and misc APIs */
#include "string.h"
#include "util_filter.h"

module AP_MODULE_DECLARE_DATA fastinclude_module;

typedef struct {
  	apr_bucket *content;
} fastinclude_data;

typedef struct {
	int devel_mode; /* whether or not to print devel / troubleshooting messages to error_log */
} fastinclude_config;

typedef struct {
	int module_off; /* turns module off */
} fastinclude_perdir_config;

typedef struct {
	int matched;
} fastinclude_ctx_t;


/* Prototypes for strict C90 mode */
const char * fastinclude_file_location(fastinclude_config *conf, request_rec *r);
const int fastinclude_status_ok(fastinclude_config *conf, request_rec *r);
const int fastinclude_content_type_ok(fastinclude_config *conf, request_rec *r);

/* Create per-server configuration */
static void *fastinclude_create_server_config(apr_pool_t *p, server_rec *s)
{
	fastinclude_config *conf;
	conf = (fastinclude_config *)apr_pcalloc(p, sizeof(fastinclude_config));
    conf->devel_mode = 0;
    return conf;
}

/* Create per-directory configuration */
static void *fastinclude_create_perdir_config(apr_pool_t *p, char *dummy)
{
    fastinclude_perdir_config *conf;
    conf = (fastinclude_perdir_config *)apr_pcalloc(p, sizeof(fastinclude_perdir_config));
	conf->module_off = 0;
    return conf;
}

/* Turn on development mode */
static const char *fastinclude_devel_on(cmd_parms *cmd, void *dummy, int arg)
{
	fastinclude_config *conf;
	conf = ap_get_module_config(cmd->server->module_config, &fastinclude_module);
    conf->devel_mode = arg;
    return NULL;
}

/* Turn off module */
static const char *fastinclude_module_off(cmd_parms *cmd, void *dirconf, int arg)
{
	fastinclude_perdir_config *conf;
	conf = dirconf;
    conf->module_off = arg;
    return NULL;
}

const char *fastinclude_file_location(fastinclude_config *conf, request_rec *r){	
	char *docroot;
	const char *fname;
		
	/* need to check and see if mod_userdir altered our request */
	const char *userdir_name = apr_pstrdup(r->pool, apr_table_get(r->notes, "mod_userdir_user"));

	if( userdir_name ){
		/* get the real URI from the userdir_name */
		int len_userdir_name = strlen(userdir_name) + 2;
		int len_uri = strlen(r->uri);
		int len = len_uri-len_userdir_name;		
        const char *uri = apr_pstrdup(r->pool, r->uri);
		const char *uri_name_real = &uri[len_uri-len];
        int len_uri_name_real, len_filename;
		
		if(conf->devel_mode == 1){
			ap_log_error(APLOG_MARK, APLOG_NOTICE | APLOG_NOERRNO, 0, r->server, "%s: Real URI: %s", MYNAME, uri_name_real);
			ap_log_error(APLOG_MARK, APLOG_NOTICE | APLOG_NOERRNO, 0, r->server, "%s: Filename: %s", MYNAME, r->filename);
		}
		
		/*remove URI from file name to get docroot */
        len_uri_name_real = strlen(uri_name_real);
        len_filename = strlen(r->filename);

		if( len_filename - len_uri_name_real > 0 ){
			docroot = apr_pstrndup(r->pool, r->filename, len_filename-len_uri_name_real);
		}else{
			return NULL;
		}
	}else{
		docroot = (char*)ap_document_root(r);	
	}
	
	if(conf->devel_mode == 1){
        	ap_log_error(APLOG_MARK, APLOG_NOTICE | APLOG_NOERRNO, 0, r->server, "%s: document root: %s", MYNAME, docroot);
  	}

	if( docroot ){
		fname = apr_pstrcat(r->pool, docroot, "/.fastinclude", NULL);
		if(conf->devel_mode == 1){
	        	ap_log_error(APLOG_MARK, APLOG_NOTICE | APLOG_NOERRNO, 0, r->server, "%s: fastinclude file location: %s", MYNAME, fname);
	  	}

		return fname;
	}
	
	return NULL;
}

/* See if .fastinclude file exists and is not a symlink */
static int fastinclude_file_exists( fastinclude_config *conf, request_rec *r, const char *fname ){
	apr_finfo_t finfo;
	
	if ( apr_stat(&finfo, fname, APR_FINFO_SIZE|APR_FINFO_PROT|APR_FINFO_LINK|APR_FINFO_OWNER, r->pool) != APR_SUCCESS ) {
	  	return 0;
	}
	
	/* Symlink check */
	if( finfo.filetype == APR_LNK ){
		if(conf->devel_mode == 1){
	        ap_log_error(APLOG_MARK, APLOG_NOTICE | APLOG_NOERRNO, 0, r->server, "%s: Include file is a symbolic link: %s", MYNAME, fname);
			ap_log_error(APLOG_MARK, APLOG_NOTICE | APLOG_NOERRNO, 0, r->server, "%s: Symlinks not allowed. No FastInclude content added.", MYNAME);
	  	}
		return 0;
	}else{
		return 1;
	}
	
	return 0;
}

/* Create a bucket for the include file's contents */
static apr_bucket *fastinclude_file_bucket(fastinclude_config *conf, request_rec *r) {
	apr_bucket *filebucket;
	apr_file_t *file;
	apr_finfo_t finfo;
	const char *fname;
	
	fname = fastinclude_file_location(conf, r);
	
	if ( apr_stat(&finfo, fname, APR_FINFO_SIZE|APR_FINFO_PROT|APR_FINFO_LINK|APR_FINFO_OWNER, r->pool) != APR_SUCCESS ) {
	  	return NULL;
	}
	/* Symlink check */
	if( finfo.filetype == APR_LNK ){
		return NULL;
	}
	
	/* Get fastinclude file contents */
	if ( apr_file_open(&file, fname, APR_READ|APR_SHARELOCK|APR_SENDFILE_ENABLED, APR_OS_DEFAULT, r->pool ) == APR_SUCCESS ) {
		if(conf->devel_mode == 1){
	    	ap_log_error(APLOG_MARK, APLOG_NOTICE | APLOG_NOERRNO, 0, r->server, "%s: Include file opened: %s", MYNAME, fname);
	  	}
	}else{
		if(conf->devel_mode == 1){
	    	ap_log_error(APLOG_MARK, APLOG_NOTICE | APLOG_NOERRNO, 0, r->server, "%s: Could not open include file: %s", MYNAME, fname);
	  	}
	  	return NULL;
	}
	
	if ( file ) {
		if(conf->devel_mode == 1){
			ap_log_error(APLOG_MARK, APLOG_NOTICE | APLOG_NOERRNO, 0, r->server, "%s: File opened successfully: %s", MYNAME, fname);
		}
	}else{
		if(conf->devel_mode == 1){
			ap_log_error(APLOG_MARK, APLOG_NOTICE | APLOG_NOERRNO, 0, r->server, "%s: No file descriptor: %s", MYNAME, fname);
		}
		return NULL;
	}
	
	filebucket = apr_bucket_file_create(file, 0, finfo.size, r->pool, r->connection->bucket_alloc);
	
	if(filebucket){
		if(conf->devel_mode == 1){
		    ap_log_error(APLOG_MARK, APLOG_NOTICE | APLOG_NOERRNO, 0, r->server, "%s: File bucket created", MYNAME);	
		}
	}else{
		if(conf->devel_mode == 1){
			ap_log_error(APLOG_MARK, APLOG_NOTICE | APLOG_NOERRNO, 0, r->server, "%s: Unable to create bucket from file: %s", MYNAME, fname);
		}
	}	
	return filebucket;
}


const int fastinclude_status_ok(fastinclude_config *conf, request_rec *r){
	if(conf->devel_mode == 1){
		ap_log_error(APLOG_MARK, APLOG_NOTICE | APLOG_NOERRNO, 0, r->server, "%s: Status Code: %d.", MYNAME, r->status);
	}

	if( r->status == 200 || r->status == 302 || r->status == 304){
		return 1;
	}else{
		return 0;
	}
}

const int fastinclude_content_type_ok(fastinclude_config *conf, request_rec *r){
    /* Only register the filter if it matches one of our content types below */
	char *type;
	const char *cType;
	type = "text/html";
	
	/* Protect against NULL content types */
	if(r->content_type == NULL){ 
		return 0;
	}

	cType = apr_pstrndup(r->pool, r->content_type, strlen(type));
		
	if( apr_strnatcmp( cType, type ) == 0 ){
		if(conf->devel_mode == 1){
			ap_log_error(APLOG_MARK, APLOG_NOTICE | APLOG_NOERRNO, 0, r->server, "%s: Matched Content-Type: %s.", MYNAME, r->content_type);
		}
		return 1;
	}else{
		if(conf->devel_mode == 1){
			ap_log_error(APLOG_MARK, APLOG_NOTICE | APLOG_NOERRNO, 0, r->server, "%s: Content-Type: %s Ignored. No Fastinclude content added.", MYNAME, r->content_type);
		}
		return 0;
	}
}

static int fastinclude_request_ok(fastinclude_config *conf, request_rec *r){
	if( fastinclude_status_ok(conf, r) ){
		if( fastinclude_content_type_ok(conf, r) ){
			return 1;
		}else{
			return 0;
		}
	}else{
		return 0;
	}
}

static apr_status_t init_fastinclude_instance(ap_filter_t *f){
	fastinclude_ctx_t *ctx;
    f->ctx = ctx = apr_pcalloc(f->r->pool, sizeof(fastinclude_ctx_t));
	ctx->matched = 0;
	
	return APR_SUCCESS;
}

static apr_status_t add_fastinclude(ap_filter_t *f, apr_bucket_brigade *bb){
	
	apr_bucket *b;
	apr_status_t rv;
	const apr_strmatch_pattern* htmlpat;
	const char *matched;
	const char *html = "<html";
	fastinclude_config *conf;
	fastinclude_ctx_t *ctx = f->ctx;
    fastinclude_data *fidata;
	int read = 0;
	
	conf = ap_get_module_config(f->r->connection->base_server->module_config, &fastinclude_module); 
	fidata = apr_palloc(f->r->pool, sizeof(fastinclude_data));
	fidata->content = NULL;	
	
	if (!ctx) {
		if ((rv = init_fastinclude_instance(f)) != APR_SUCCESS) {
			ap_remove_output_filter(f);
			return ap_pass_brigade(f->next, bb);
		}
		ctx = f->ctx;
	}
	
	/* Make sure the content type we have here is approved and the status is OK*/
	if( fastinclude_request_ok(conf, f->r) == 1){
		/* Check response to see if it matches <html */
		if(conf->devel_mode == 1){
			ap_log_error(APLOG_MARK, APLOG_NOTICE | APLOG_NOERRNO, 0, f->r->server, "%s: Inspecting response to check for <html> tag", MYNAME);
		}
		for ( b = APR_BRIGADE_FIRST(bb); b != APR_BRIGADE_SENTINEL(bb); b = APR_BUCKET_NEXT(b) ) {	
			if( read != 1 ){
				/* Read in first text bucket and check for <html */
				const char *str;
		        apr_size_t str_len;

		        if (apr_bucket_read(b, &str, &str_len, APR_BLOCK_READ) == APR_SUCCESS) {
					if(conf->devel_mode == 1){
						ap_log_error(APLOG_MARK, APLOG_NOTICE | APLOG_NOERRNO, 0, f->r->server, "%s: bucket read: %s", MYNAME, str);
					}
					if( str != NULL){
						/* check for <html> */
						htmlpat = apr_strmatch_precompile(f->r->pool, html, 0);
						matched = apr_strmatch(htmlpat, str, str_len);
						if( matched != NULL ){
							if(conf->devel_mode == 1){
								ap_log_error(APLOG_MARK, APLOG_NOTICE | APLOG_NOERRNO, 0, f->r->server, "%s: Response contains <html> tag", MYNAME);
							}
							ctx->matched = 1;
						}
						read = 1;
					}
		        }else{
					if(conf->devel_mode == 1){
						ap_log_error(APLOG_MARK, APLOG_NOTICE | APLOG_NOERRNO, 0, f->r->server, "%s: Failed to read response bucket", MYNAME);
					}
				}
			}
			
			/* If we have <html, insert .fastinclude content before end of response */
			if ( APR_BUCKET_IS_EOS(b) ) {
				if(conf->devel_mode == 1){
					ap_log_error(APLOG_MARK, APLOG_NOTICE | APLOG_NOERRNO, 0, f->r->server, "%s: eos bucket found", MYNAME);
					ap_log_error(APLOG_MARK, APLOG_NOTICE | APLOG_NOERRNO, 0, f->r->server, "%s: have we matched <html: %d", MYNAME, ctx->matched);
				}
				
				if ( ctx->matched == 1 ){
					fidata->content = fastinclude_file_bucket(conf, f->r);
					if( fidata->content != NULL ){
						APR_BUCKET_INSERT_BEFORE(b, fidata->content);
						if(conf->devel_mode == 1){
	        				ap_log_error(APLOG_MARK, APLOG_NOTICE | APLOG_NOERRNO, 0, f->r->server, "%s: Fastinclude content inserted in bucket bridgade", MYNAME );
						}
					}
				}
		    }
	    }

		if(ctx->matched == 0){
			if( conf->devel_mode == 1){
				ap_log_error(APLOG_MARK, APLOG_NOTICE | APLOG_NOERRNO, 0, f->r->server, "%s: <html> tag not found in response", MYNAME);
			}
		}
	}
	
	ap_remove_output_filter(f);
    return ap_pass_brigade(f->next, bb);

}

static int fastinclude_method_handler(request_rec *r){
	const char *fname;
	fastinclude_config *conf;
	fastinclude_perdir_config *dirconf;
	int fiok;
	
	conf = ap_get_module_config(r->connection->base_server->module_config, &fastinclude_module);    
	
	if( r->per_dir_config != NULL ){
		dirconf = ap_get_module_config( r->per_dir_config, &fastinclude_module );
	
		if( conf->devel_mode == 1 ){
			ap_log_error(APLOG_MARK, APLOG_NOTICE | APLOG_NOERRNO, 0, r->server, "%s: FastInclude Turned Off in httpd.conf: %d.", MYNAME, dirconf->module_off);
		}

		if( dirconf->module_off == 1){
			return DECLINED;
		}
		
		/* check for existence of .fastinclude file */
		fname = fastinclude_file_location(conf, r);
		fiok = fastinclude_file_exists(conf, r, fname);
		
		if( conf->devel_mode == 1 ){
			ap_log_error(APLOG_MARK, APLOG_NOTICE | APLOG_NOERRNO, 0, r->server, "%s: FastInclude File Exists: %d.", MYNAME, fiok);
		}
		
		if( fiok != 1 ){
			return DECLINED;
		}
			
	}
	
	ap_add_output_filter("attracta-seo", NULL, r, r->connection);
	return DECLINED;
}

static void fastinclude_register_hooks(apr_pool_t *p){
    ap_register_output_filter("attracta-seo", add_fastinclude, NULL, AP_FTYPE_RESOURCE );
	ap_hook_handler(fastinclude_method_handler, NULL, NULL, APR_HOOK_FIRST);  
}

static const command_rec fastinclude_cmds[] =
{
    AP_INIT_FLAG("FastIncludeDevel", fastinclude_devel_on, NULL, RSRC_CONF, "Enable FastInclude Development Mode"),
	AP_INIT_FLAG("FastIncludeOff", fastinclude_module_off, NULL, OR_ALL, "Enable FastInclude Module"),
    { NULL }
};

module AP_MODULE_DECLARE_DATA fastinclude_module =
{
    STANDARD20_MODULE_STUFF,                
    fastinclude_create_perdir_config,             
    NULL,
    fastinclude_create_server_config,       
    NULL,     
    fastinclude_cmds,  
    fastinclude_register_hooks,                     
};
