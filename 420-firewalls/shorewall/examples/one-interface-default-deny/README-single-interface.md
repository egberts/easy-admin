
This set of one-interface Default-Deny firewall which should cover about
99.9% of your home traffic comprises of web browsing, NTP, DHCP, and DNS.

Does not cover (but not limited to): Home assistant devices (Siri, Alexa,
Cortana), gaming platform/server 

Everything that is "unknown" gets logged, which you then do the additions of FW
rules.

Filename is <tcp_state>-<destination-zonename>-<source-zonename>

Choices of `tcp_state` are 'new', 'established', 'related', 'invalid', 'untracked'
