#!/bin/bash

#-------------------------#
#---Stable version ML4W---#
#--------Installing-------#

sudo pacman -S git flatpak
flatpak install flathub com.ml4w.dotfilesinstaller
flatpak run com.ml4w.dotfilesinstaller

#Link Dot: https://raw.githubusercontent.com/mylinuxforwork/dotfiles/main/hyprland-dotfiles-stable.dotinst #