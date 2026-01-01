#!/bin/bash

#-----------------------------------------#
#-----Boot installing SYS on CachyOS------#
#-----------------------------------------#
sudo pacman -S git

git clone --depth=1 https://github.com/JaKooLit/Arch-Hyprland.git ~/Arch-Hyprland
cd ~/Arch-Hyprland
chmod +x install.sh
./install.sh