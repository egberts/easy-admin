#!/bin/bash
# File: 605-mail-mbox-maildir-add-user.sh
# Title: Add Maildir to a user


sudo cp -r /etc/skel/Maildir /home/$USER/
sudo chown -R $USER:$USER /home/$USER/Maildir
sudo chmod -R 700 /home/$USER/Maildir
sudo adduser $USER mail

echo 'export MAIL=~/Maildir' | sudo tee -a $HOME/bash.bashrc | sudo tee -a $HOME/profile.d/mail.sh

