File: 701-lighttpd-config.sh

Title: Configure LigHTTPd Web Server

# DESIGN:
   Ask for configuration file location (provide default)
Determine root document directory and 
*       its file permission
*       group/user permission
*       group/user permission
Determine IP address and port number to use
*       Manual input? Or
*       Cycle thru each subnet used on this system
Firewall check
Module choices
*       mod_indexfile
*       mod_dirlisting
*       mod_staticfile
*       mod_accesslog
Determine if HTTPS is desired, create any PEM certificates
Check that no other web server conflicts with these settings
Use Case:
*       Static Content Only
*       PHP processing
*       URL rewriting
*       Authentication
*       Dynamic Content (FastCGI)
*           php-cgi or php-fpm
*               Worker Processes
Default settings displayed
Display file locations used
*       lighttpd.conf
*       Helper Scripts
*       Modules locations
*       Available modules
*       Activated modules
*     - any duplicate interfaces mandates 'shared-network' group
For each subnet
*     Prompts for IP adddress range, start/end
*     Determine gateway IP
*     Prompt for log server IP (show nested-default)
*     Prompt for DNS nameservers (show nested-default)
*
Detect for esoteric settings
1. ?
*
*   Validate the whole shebang:
*       lighttpd -tt -f /etc/lighttpd/lighttpd.conf
*
Envvars
*   BUILDROOT - where to output the files into (default $PWD/build)
*   CHROOT_DIR - where to output files get installed into (default /)
*
System Files impacted:
*   Modified: none
*   Created: none

| Prefix pattern | Example filename                                  | Purpose                                            |
| -------------- | ------------------------------------------------- | -------------------------------------------------- |
| `00-` to `09-` | `00-global.conf`, `00-defaults.conf`              | Global or base directives (defaults, environment). |
| `10-` to `19-` | `10-accesslog.conf`, `10-dirlisting.conf`         | Core server features and logging.                  |
| `20-` to `39-` | `20-mod_access.conf`, `20-mod_rewrite.conf`       | Module enablement and configuration.               |
| `40-` to `59-` | `40-fastcgi.conf`, `40-php.conf`, `40-proxy.conf` | Dynamic content or upstream integration.           |
| `60-` to `79-` | `60-ssl.conf`, `60-tls.conf`                      | Encryption and certificate configuration.          |
| `80-` to `89-` | `80-vhosts.conf`, `80-alias.conf`                 | Virtual hosts, aliases, per-site settings.         |
| `90-` to `99-` | `90-custom.conf`, `99-local.conf`                 | Local overrides or site-specific tweaks.           |

```ini
# Default Configuration (Debian)
         
### Documentation
# https://wiki.lighttpd.net/
#
### Configuration Syntax
# https://wiki.lighttpd.net/Docs_Configuration
#
### Configuration Options
# https://wiki.lighttpd.net/Docs_ConfigurationOptions
#

### Debian lighttpd base configuration

server.modules = (
        "mod_indexfile",
        "mod_access",
        "mod_alias",
        "mod_redirect",
)

server.document-root        = "/var/www/html"
server.upload-dirs          = ( "/var/cache/lighttpd/uploads" )
server.errorlog             = "/var/log/lighttpd/error.log"
server.pid-file             = "/run/lighttpd.pid"
server.username             = "www-data"
server.groupname            = "www-data"
server.port                 = 80

# strict parsing and normalization of URL for consistency and security
# https://wiki.lighttpd.net/Server_http-parseoptsDetails
# (might need to explicitly set "url-path-2f-decode" = "disable"
#  if a specific application is encoding URLs inside url-path)
server.http-parseopts = (
  "header-strict"           => "enable",# default
  "host-strict"             => "enable",# default
  "host-normalize"          => "enable",# default
  "url-normalize-unreserved"=> "enable",# recommended highly
  "url-normalize-required"  => "enable",# recommended
  "url-ctrls-reject"        => "enable",# recommended
  "url-path-2f-decode"      => "enable",# recommended highly (unless breaks app)
 #"url-path-2f-reject"      => "enable",
  "url-path-dotseg-remove"  => "enable",# recommended highly (unless breaks app)
 #"url-path-dotseg-reject"  => "enable",
 #"url-query-20-plus"       => "enable",# consistency in query string
  "url-invalid-utf8-reject" => "enable",# recommended highly (unless breaks app)
)

index-file.names            = ( "index.php", "index.html" )
url.access-deny             = ( "~", ".inc" )
static-file.exclude-extensions = ( ".php", ".pl", ".fcgi" )

include_shell "/usr/share/lighttpd/create-mime.conf.pl"
include "/etc/lighttpd/conf-enabled/*.conf"

# default listening port for IPv6 is same as default IPv4 port
include_shell "/usr/share/lighttpd/use-ipv6.pl " + server.port

### Customizations
# customizations should generally be placed in separate files such as
#   /etc/lighttpd/conf-available/00_vars.conf    # override variables for *.conf
#   /etc/lighttpd/conf-available/99_custom.conf  # override *.conf settings
# and then enabled using lighty-enable-mod (1)
```