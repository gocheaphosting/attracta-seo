#!/bin/sh
STATUS=Updating

echo "$STATUS cPanel USER INTERFACE ICONS"
echo "    NOTE: This may take a minute or two"
echo ""
#install our dynamic ui files (defined by installer options)
echo "    $STATUS 'SEO and Marketing Tools' icon group"
/usr/local/cpanel/bin/register_cpanelplugin /usr/local/cpanel/Cpanel/ThirdParty/Attracta/PluginFiles/attracta_seo.cpanelplugin >/dev/null 2>&1
echo "    $STATUS 'SEO Tools' icon"
/usr/local/cpanel/bin/register_cpanelplugin /usr/local/cpanel/Cpanel/ThirdParty/Attracta/PluginFiles/attracta_seotools.cpanelplugin >/dev/null 2>&1
echo "    $STATUS 'Increase Website Traffic' icon"
/usr/local/cpanel/bin/register_cpanelplugin /usr/local/cpanel/Cpanel/ThirdParty/Attracta/PluginFiles/attracta_increasewebsitetraffic.cpanelplugin >/dev/null 2>&1
echo "    $STATUS 'Google Website Services' icon"
/usr/local/cpanel/bin/register_cpanelplugin /usr/local/cpanel/Cpanel/ThirdParty/Attracta/PluginFiles/attracta_googlewebsiteservices.cpanelplugin >/dev/null 2>&1
echo "    $STATUS 'Link Building' icon"
/usr/local/cpanel/bin/register_cpanelplugin /usr/local/cpanel/Cpanel/ThirdParty/Attracta/PluginFiles/attracta_linkbuilding.cpanelplugin >/dev/null 2>&1
echo "    $STATUS 'One-Click Sitemap' icon"
/usr/local/cpanel/bin/register_cpanelplugin /usr/local/cpanel/Cpanel/ThirdParty/Attracta/PluginFiles/attracta_one-clicksitemap.cpanelplugin >/dev/null 2>&1
echo "    $STATUS 'Get in Google' icon"
/usr/local/cpanel/bin/register_cpanelplugin /usr/local/cpanel/Cpanel/ThirdParty/Attracta/PluginFiles/attracta_getingoogle.cpanelplugin >/dev/null 2>&1
echo "    $STATUS 'SEO Tips' icon"
/usr/local/cpanel/bin/register_cpanelplugin /usr/local/cpanel/Cpanel/ThirdParty/Attracta/PluginFiles/attracta_seotips.cpanelplugin >/dev/null 2>&1	
echo "......done"