XDG_CONFIG_HOME ?= $(HOME)/.config
DOTFILES_HOME ?= $(HOME)/.dotfiles
DOTFILES_CONFIG_HOME := $(DOTFILES_HOME)/.config

.DEFAULT_GOAL := all

.PHONY: alacritty git hammerspoon karabiner nvim starship tmux yabai zsh all

alacritty:
	mkdir -p $(XDG_CONFIG_HOME)/alacritty
	ln -sf $(DOTFILES_CONFIG_HOME)/alacritty/alacritty.toml $(XDG_CONFIG_HOME)/alacritty/alacritty.toml
	ln -sfn $(DOTFILES_CONFIG_HOME)/alacritty/colors $(XDG_CONFIG_HOME)/alacritty/colors

git:
	mkdir -p $(XDG_CONFIG_HOME)/git
	ln -sf $(DOTFILES_CONFIG_HOME)/git/config $(XDG_CONFIG_HOME)/git/config
	touch $(XDG_CONFIG_HOME)/git/config.local
	ln -sf $(DOTFILES_CONFIG_HOME)/git/ignore $(XDG_CONFIG_HOME)/git/ignore

hammerspoon:
	mkdir -p $(XDG_CONFIG_HOME)/hammerspoon
	ln -sf $(DOTFILES_CONFIG_HOME)/hammerspoon/init.lua $(XDG_CONFIG_HOME)/hammerspoon/init.lua
	defaults write org.hammerspoon.Hammerspoon MJConfigFile "$(HOME)/.config/hammerspoon/init.lua"

karabiner:
	mkdir -p $(XDG_CONFIG_HOME)/karabiner
	ln -sf $(DOTFILES_CONFIG_HOME)/karabiner/karabiner.json $(XDG_CONFIG_HOME)/karabiner/karabiner.json

nvim:
	mkdir -p $(XDG_CONFIG_HOME)/nvim
	ln -sf $(DOTFILES_CONFIG_HOME)/nvim/init.lua $(XDG_CONFIG_HOME)/nvim/init.lua
	ln -sfn $(DOTFILES_CONFIG_HOME)/nvim/lua $(XDG_CONFIG_HOME)/nvim/lua
	ln -sf $(DOTFILES_CONFIG_HOME)/nvim/lazy-lock.json $(XDG_CONFIG_HOME)/nvim/lazy-lock.json

starship:
	mkdir -p $(XDG_CONFIG_HOME)/starship
	ln -sf $(DOTFILES_CONFIG_HOME)/starship/starship.toml $(XDG_CONFIG_HOME)/starship/starship.toml

tmux:
	mkdir -p $(XDG_CONFIG_HOME)/tmux
	ln -sf $(DOTFILES_CONFIG_HOME)/tmux/tmux.conf $(XDG_CONFIG_HOME)/tmux/tmux.conf
	ln -sf $(DOTFILES_CONFIG_HOME)/tmux/tmux-popup.conf $(XDG_CONFIG_HOME)/tmux/tmux-popup.conf

yabai:
	mkdir -p $(XDG_CONFIG_HOME)/yabai
	ln -sf $(DOTFILES_CONFIG_HOME)/yabai/yabairc $(XDG_CONFIG_HOME)/yabai/yabairc

zsh:
	mkdir -p $(XDG_CONFIG_HOME)/zsh
	ln -sf $(DOTFILES_HOME)/.zshenv $(HOME)/.zshenv
	ln -sf $(DOTFILES_CONFIG_HOME)/zsh/.zshenv $(XDG_CONFIG_HOME)/zsh/.zshenv
	ln -sf $(DOTFILES_CONFIG_HOME)/zsh/.zprofile $(XDG_CONFIG_HOME)/zsh/.zprofile
	ln -sf $(DOTFILES_CONFIG_HOME)/zsh/.zshrc $(XDG_CONFIG_HOME)/zsh/.zshrc
	if ! [ -e $(XDG_CONFIG_HOME)/zsh/.zshenv.local ]; then \
		touch $(XDG_CONFIG_HOME)/zsh/.zshenv.local; \
	fi
	if ! [ -e $(XDG_CONFIG_HOME)/zsh/.zprofile.local ]; then \
		touch $(XDG_CONFIG_HOME)/zsh/.zprofile.local;\
	fi
	if ! [ -e $(XDG_CONFIG_HOME)/zsh/.zshrc.local ]; then \
		touch $(XDG_CONFIG_HOME)/zsh/.zshrc.local; \
	fi

all: alacritty git hammerspoon karabiner nvim starship tmux yabai zsh
