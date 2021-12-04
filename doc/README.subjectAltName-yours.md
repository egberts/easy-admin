To generate a sufficient coverage of your certificate by LetsEncrypt
for a small-medium business or public-facing homelab:

SAN (subjectAltName) must ensure that the following domain names is including 
into LetsEncrypt's subjectAltName (SAN) line/prompt:


SAN (subjectAltName) Domain Names needed are:


    ns1.example.net      ; needed for DANE, RFC 6698, RFC7671, RFC7672
                         ; MUST BE mapped as well for reverse IP DNS


For IMAP4/POP3 support,
=================

    imap.example.net     ;
    imaps.example.net     ;
    pop3.example.net     ;
    pop3s.example.net     ;


For SMTP suupport,
=================

    smtp.example.net     ; needed for DKIM

                        ; The recipient mail server supports STARTTLS 
                        ; and offers a PKIX-based TLS certificate, 
                        ; during TLS handshake, which is valid for
                        ; that host
    mx1.example.net      ; STARTTLS



For SMTP-TLS support
=====================

    mta-sts.example.net  ; MTA-STS, RFC 8461

