#!/bin/bash

# This command will close all active conky
killall conky	
# Only the config listed below will be avtivated
# if you want to combine with another theme, write the command here
conky -c $HOME/.config/conky/Mimod-white/Mimod-white.conf &> /dev/null &

exit
