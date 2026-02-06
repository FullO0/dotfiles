COLORS_SRC  = colors.toml
TMUX_COLORS = tmux/colors.tmux.conf
NVIM_COLORS = nvim/lua/generated_colors.lua

# Starship
STARSHIP_BASE   = starship/.config/starship_base.toml
STARSHIP_CONFIG = starship/.config/starship.toml

STOW = vim tmux starship nvim bash

.PHONY: all stow apply clean create $(STARSHIP_CONFIG)

all: apply stow

# Creates all needed paths for all configs to work
create:

# apply the new colorscheme to the whole enviroment
apply: $(STARSHIP_CONFIG) stow

$(STARSHIP_CONFIG): $(COLOR_SRC) $(STARSHIP_BASE)
	@echo "Generating Starship Colors..."
	@echo "palette = \"onedark_ansii\"\n" > $@
	@cat $(STARSHIP_BASE) >> $@
	@printf "\n" >> $@
	@cat $(COLORS_SRC) >> $@
	stow -R starship

$(TMUX_COLORS): $(COLORS_SRC)
	@echo "Generating Tmux colors..."

$(NVIM_COLORS): $(COLORS_SRC)
	@echo "Generating Neovim Lua colors..."

# stows everything
stow:
