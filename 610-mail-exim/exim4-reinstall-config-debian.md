

You blew away the `/etc/exim4/conf.d` subdirectory because you had enjoyed the monolithe configuration scheme of Exim4 email package on Debian host system.

And now you have changed your mind and want to try out the split-configuration files scheme.

No worry, this is how to get that `conf.d` subdirectory  back:

```bash
sudo mv /etc/exim4 /etc/exim4-old
sudo apt-get -o Dpkg::Options::="--force-confmiss" install --reinstall exim4-config
sudo dpkg-reconfigure exim4-config
```

Your old Exim4 config files are now in `/etc/exim4-old`.
