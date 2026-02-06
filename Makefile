COLORS_SRC  = colors.toml
TMUX_COLORS = tmux/colors.tmux.conf
NVIM_COLORS = nvim/lua/generated_colors.lua

STOW = vim tmux starship nvim bash

.PHONY: all stow apply clean create starship

all: apply stow

# Creates all needed paths for all configs to work
create:

# apply the new colorscheme to the whole enviroment
apply: starship

starship:
	@echo "Generating Starship Colors..."
	@starship_colors.sh

$(TMUX_COLORS): $(COLORS_SRC)
	@echo "Generating Tmux colors..."

$(NVIM_COLORS): $(COLORS_SRC)
	@echo "Generating Neovim Lua colors..."

# stows everything
stow:
