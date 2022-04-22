
# Trust Anchors in ISC Bind9

To generate a new DNSKEY RDATA in base64 format for the `trust-anchor`
clause settings, execute:

```bash
dnssec-keygen -T DNSKEY \
    -K /var/lib/named/keys/ \
    -n ZONE \
    -p 3 \
    -a ECDSAP384SHA384 \
    -L 86400 \
    -v 2 \
    localhost
```
And insert the base64 content into the `trust-anchors` DNSKEY RDATA part (near the end of `trust-anchors` block.

```
; public-key are copies of DNSKEY RRs for zones.
trust-anchors { "localhost." 
                initial-key 
; 
; Flags, 16-bits, and its values are 256 and 257 above. 
; Bits 0–6 and 8–14 are reserved and should be zero. 
; So only bit 7 and 15 can be one, and possible 
; values are only 0, 256 (bit-7 is set) and 257 (both 
; bit-7 and bit-15 is set). If the bit 7 is 1 (value 
; 256 or 257), DNSKEY holds a DNS zone key; if it 
; is 0 (value 0), it holds another type of key. So 
; both of these hold a DNS zone key. Bit 15 (value 257) 
; indicates a Secure Entry Point. Only DNSKEYs marked 
; as zone keys can sign the DNS records.
                257 
; 
;  The following values of the Protocol Octet are reserved as indicated:
;
;       VALUE   Protocol
;         0      -reserved
;         1     TLS
;         2     email
;         3     dnssec
;         4     IPSEC
;     5-254      - available for assignment by IANA
;       255     All
; RFC2535 lists the protocol ID of DNSKEY.  We use 3 for DNSSEC.

                3 // DNSSEC
; Algorithm, 8-bits, the public key’s cryptographic 
; algorithm, it is 8 above. 8 means RSA/SHA-256. 
; For this algorithm, the key size must be between 
; 512-bits and 4096-bits (according to RFC 5702).

                8 // RSASHA256

    Last field is DNSKEY RDATA in Base64 encoding, the format of public key in the record depends on the algorithm, in this case it contains the size of the exponent, the public exponent and the modulus (according to RFC 5702 and RFC 3110). 

                "ZrBiH/jUnZoKSLMuVh3Ek+AepknhwpTLbvs8Eny1x/4="
    };

```
