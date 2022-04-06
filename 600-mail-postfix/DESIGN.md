Dependencies:
  proxy_interfaces
  relayhost
    defer_transport
    mydestination
    domain DNS has no MX record
  disable_dns_lookup



default-ssl-wide-settings {
    smtp_tls_connection_reuse = no
    smtp_tls_dane_insecure_mx_policy = dane
    smtp_starttls_timeout = 300s
    smtp_tls_block_early_mail_reply = no
    smtp_tls_enforce_peername = yes
    smtp_tls_force_insecure_host_tlsa_lookup = no

    # Request  that  the Postfix SMTP client connects using the legacy
    #           SMTPS protocol instead of using the STARTTLS command.
    smtp_tls_note_starttls_offer = yes

    smtp_tls_scert_verifydepth = 9
    smtp_tls_secure_cert_match = nexthop, dot-nexthop
}

Do you generate email?
if not-generate-email
  exit
fi

Accept mail from the network?
if smtp-inbound-supported == no then
  inet_interfaces = loopback-only
fi

if $mydomain has no MX record (DNS) then
  relayhost = $my_actual_hostname
fi

if smtp-inbound-supported == yes then
  if this-hostname is a primary OR a secondary DNX MX record then
    relay_domains += this-hostname   # note this '+='
    smtpd_relay_restrictions += permit_mynetworks_reject_unauth_destination 
    smtpd_recipient_restrictions += permit_mynetworks_reject_unauth_destination 

    Ask for external IP address of SMTP-capable Proxy
    Is there a NAT/proxy involved with your SMTP/email protocol?
    if nat-proxy-involved then
      proxy_interfaces = <external_smtp_proxy_ip_address>
    fi

    if this-hostname is a secondary DNX MX record OR strong-security then
      Are you willing to manually map every users ALSO at the secondary MX server?
      if mx-secondary-separate-user-address-list then
        # Define the list of valid addresses in the "the.backed-up.domain.tld" 
        # domain. This prevents your mail queue from filling up with 
        # undeliverable MAILER-DAEMON messages. 
        relay_recipient_maps = hash:/etc/postfix/relay_recipients
        ### # File:/etc/postfix/relay_recipients
        ### user1@the.backed-up.mx2.domain.tld   x
        ### user2@the.backed-up.mx2.domain.tld   x
      else
        Wildcard email address on this secondary MX server?
        if smtp-network-mx-secondary then
          # If you can't maintain a list of valid recipients 
          # then you must specify "relay_recipient_maps =" (that 
          # is, an empty value), 
          relay_recipients_maps = <null>
        else
          # or you must specify an "@the.backed-up.domain.tld x" 
          # wild-card in the relay_recipients table. 
          relay_recipient_maps = hash:/etc/postfix/relay_recipients
          ### # File:/etc/postfix/relay_recipients
          ### user1@the.backed-up.mx2.domain.tld   x
          ### user2@the.backed-up.mx2.domain.tld   x
        fi
      fi
    fi
  fi
  if this-hostname is primary DNX MX record then
    transport_maps = hash:/etc/postfix/transport
    ### # File: /etc/postfix/transport:
    ### the.backed-up.mx2.domain.tld       relay:[their.mail.host.tld]
  fi

fi


Types of Postfix configuration
* Postfix on a stand-alone Internet host (default config)
* A null client is a machine that can only send mail. It receives no mail from the network, and it does not deliver any mail locally. A null client typically uses POP, IMAP or NFS for mailbox access.
* Postfix on a local network
* Postfix email firewall/gateway
* Running Postfix behind a firewall (in the DMZ)
* Postfix on a dialup machine
* Postfix on hosts without a real Internet hostname

basic setup
if host hostname is not a fully-qualified domain name then
  WARNING: need to set hostname to FQDN
  exit
fi
if domain name part of the hostname is not a fully-qualified domain name then
  WARNING: need to set domain part of hostname to FQDN
  exit
fi

if host-inet-dev-multiple == yes then
  if inet-interfaces-multi-homed == yes then
    smtp_bind_address = 0.0.0.0
    smtp_bind_address6 = [::]
    # use inet-specific in /etc/master.cf
  else
    smtp_bind_address_enforce = yes
    smtp6_bind_address_enforce = yes
    master# smtp ... smtp -o smtp_bind_address=9.10.11.12
    master# smtp ... smtp -o smtp_bind_address6=1:2:3:4:5:6:7:8
  fi
fi


# Mobile connection
Does this host have the "same" DHCP server or a fixed static IP address over anything Fiber/WiFi/LAN/WiMAX/PAN?
if host-mode == stationary then
  
else
  Does this host have different WiFi/DHCP server?
  if host-mode == wanderer then
  
  fi
fi

if have-internet-access == yes then
  if have-outbound-smtpd == yes then
    Does this host IP address have a resolvable DNS name?
    if host-ip-addr-has-resolvable-dns == no then
      smtp_generic_map = hash:/etc/postfix/generic
      # /etc/postfix/generic
      #   his@localdomain.local  hisaccount@mydomain.com
      #   her@localdomain.local  heraccount@mydomain.com
      #   @localdomain.local     hisaccount+local@mydomain.com
    fi
  fi
fi

# Intermitting connection
Does this host have unreliable Internet connection, like hotspot, LTE cellular modem, dialup, or personal area network (PAN) such as IrDA, Wireless USB, Bluetooth or ZigBee.?
if network-connectivity == intermitting then
  # Route all outgoing mail to your network provider. 
  relayhost = [smtprelay.someprovider.com]
  Do you want email push out immediately as received using dialup?
  if network-intermitting-queue == hold then
    # Disable spontaneous SMTP mail delivery (if using on-demand dialup IP only).
    defer_transports = smtp (Only for on-demand dialup IP hosts)
      # WARNING: need to run the "sendmail -q" command every now and then 
  fi
  # Disable SMTP client DNS lookups (dialup LAN only).
  disable_dns_lookups = yes (Only for on-demand dialup IP hosts)
  # Flush the mail queue whenever the Internet link is established. 
  /usr/sbin/sendmail -q (whenever the Internet link is up)
fi

# local users
# Does this admin want user password stored in one or more places?

while no-more-smtp-password-store == no; do
  Where is the password stored at?
  switch sasl-password-store 
    case UNIX (dovecot/courier/sasld)
      my_sasl_password_store[idx] = sock:/var/spool/postfix/sasl.sock
    case file
      my_sasl_password_store[idx] = hash:/etc/postfix/passwd
    case network
      my_sasl_password_store[idx] = inet:my-big-sasl-passwd-server-ip-or-domain-name:port
  endswitch
  Is there another password storage that needs to be consulted next as well?
  if no-more-smtp-password-store = yes then break
endwhile
`smtp_sasl_password_maps = ${my_sasl_password_store[*]}`

# LSMTP
Does your email needs to be sent to a local user on this host?
if local-users-supported
  Do you need authentication from users trying to send local email?
  if local-user-auth-required then
    smtp_sasl_auth_enable = yes
    Do you need encryption support for users trying to send local email?
    if smtp-encryption-needed then
      smtp_use_tls = yes
      smtp_sasl_security_options = ??
      smtp_sasl_tls_security_options = $smtp_sasl_security_options
      Do you mandate local encryption for users trying to send email to within this host using IP?
      if lsmtp-encryption-required then
        smtp_enforce_tls = yes
        smtp_sasl_tls_security_options = ??
        smtp_sasl_tls_verified_security_options = $smtp_sasl_tls_security_options
      fi
    fi
  else
    # configure lsmtp wide-open.
    smtp_sasl_auth_enable = no
  fi


do you have a firewall on this host that blocks email?
if local-firewall-blocks-smtp then
  Can you change the firewall?
  if local-firewall-admin then
    open local-firewall to SMTP, SMTPS/SUBMISSIONS, and SUBMISSION
  else
    set up smart-host using non-SMTP-port
    request-remote-smart-host-port-custom=yes
  fi
fi


Do you have a email provider?


Do you have a domain name that you can administer for this email purposes?
if have-smtp-domain-admin then
  Does someone already handle emails for your own domain(s)?
  Do you wish to become an email provider?
else
fi


# LMTP
Does this host need to relay mail from clients within your local network?
if relay-network-localnet == yes then
    # mynetworks: type: non-mailhost/mailhost
    # list all `ip addr show`
    # All clients from with all subnets listed above?
    if lmtp-inbound-accept == all then
      mynetworks_style = class
    else
      # Specify the trusted networks. 
      mynetworks = <list_of_internal_subnet_class_prefix> # or
    fi

    # This host does not relay mail from untrusted networks. 
    # relay_domains: type: non-mailhost/mailhost
    relay_domains = <null>

    Do you allow user to send mail using 'user@hostname' and not 'user@domainname'?
    if domain-part-always then
      # myorigin: type: non-mailhost/mailhost
      myorigin = $mydomain
    fi
else
  Do you have mail server(s) deeper in your local network to connect and relay?
  if relay-have-localnet-smtp-server then
    mynetworks_style = <internal_mail_server_ip_hostname>
    if $mydomain has no MX record (DNS) then
      relayhost = $my_actual_hostname
    else
      relayhost = $mydomain
    fi
  else
    # do not relay any mail
    mynetworks_style = host
    relay_domains = <null>
  fi
fi

No mailboxes for users on this local host?
if lmtp-inbound-supported == no then
  # Disable local mail delivery. All mail goes to the mail server as specified in "relayhost="
  mydestination = <null>
else
  mydestination = $myhostname localhost.$mydomain localhost $mydomain
fi


do you have a firewall on your gateway that blocks email?
if remote-firewall-blocks-smtp then
  Can you change that gateway's firewall?
  if have-remote-firewall-admin then
    open remote-firewall to SMTP, SMTPS/SUBMISSIONS, and SUBMISSION
  else
    # unable to change firewall
    request-remote-smart-host-port-custom=yes
  fi
fi

if request-remote-smart-host-port-custom then
  # IMPORTANT: do not specify a relayhost

  # Request that intranet mail is delivered directly, and 
  # that external mail is given to a gateway. Obviously, 
  # this example assumes that the organization uses DNS MX 
  # records internally. The [] forces Postfix to do no 
  # MX lookup. 
  transport_maps = hash:/etc/postfix/transport

  ### # File: /etc/postfix/transport
  ### # Internal delivery
  ### example.com :
  ### .example.com :
  ### # External delivery
  ### *               smtp:[gateway.example.com]
  relayhost =

  # this prevents mail from being stuck in the queue 
  # when the machine is turned off. Postfix tries to 
  # deliver mail directly, and gives undeliverable mail 
  # to a gateway.  This is optional
  Does this host get suspended (lid)/powered-off (charger) or have intermitting network connection?
  if host-network-intermitting == yes OR network-disconnect-by-user == yes then
    failback_relay = [gateway.example.com]
  fi
fi

###########################################################
# Post integrity test
if this-hostname is a primary DNX MX record then
  Do not list the.backed-up.domain.tld in mydestination.
  Do not list the.backed-up.domain.tld in virtual_alias_domains.
  Do not list the.backed-up.domain.tld in virtual_mailbox_domains.
fi

