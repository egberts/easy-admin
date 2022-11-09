title: How to use '+' in Exim4/Dovecot
date: 2022-03-23 04:15
status: published
tags: Exim4, Dovcecot
category: HOWTO
summary: To leverage that symbol plus wildcard part of your email address (john+anythinggoeshere@example.com), the main part is this `local_part_suffix` setting for Exim4.
slug: exim4-subaddressing
lang: en
private: False

To leverage that symbol plus wildcard part of your email address (john+anythinggoeshere@example.com), the main part is this `local_part_suffix` setting for Exim4.

Exim4 Settings for Subaddressing
--------------------------------

I have identified the following as Exim4 subaddressing.

    local_part_suffix = +* : -* : _*
    local_part_suffix_optional

Nowhere could I find documentation on HOW TO USE this setting within Debian-config Exim4 framework.

So, I simply peruse the `/etc/exim4/conf.d/router` subdirectory.

Took a stab at any `local` or `part` or `subaddressing`-like in all the config files.

Found the `900-exim4_config_local_user` to be the logical candidate.

Rationale:
* the user should be able specify ANYTHING for the local_part after the plus + in all their outbound email.
* the real issue is getting back to the "original" name of the email user.  

So, it is about the 

* inbound email
* local email account (user) name

Dovcecot Settings for Subaddressing
-----------------------------------

Next, create the following file,

    /etc/dovecot/conf.d/subaddressing.conf

Add the following contents into the subaddressing.conf file,

    recipient_delimiter = +
    lmtp_save_to_detail_mailbox = yes
    lda_mailbox_autocreate = yes
    lda_mailbox_autosubscribe = yes

Note that if you wanted to support multiple characters for the delimiter, such as the plus sign, the hyphen, and the underscore, you could use this instead of the single recipient delimiter above,

    recipient_delimiter = +-_

Restart Dovecot,

    service dovecot restart
