COLORS_SRC  = colors.toml

# tmux
TMUX_CONFIG_DIR = tmux/.config/tmux
TMUX_COLORS     = $(TMUX_CONFIG_DIR)/colors.tmux.conf

# Starship
STARSHIP_BASE   = starship/.config/starship_base.toml
STARSHIP_CONFIG = starship/.config/starship.toml

# nvim
NVIM_CONFIG_DIR = nvim/.config/nvim
NVIM_COLORS     = $(NVIM_CONFIG_DIR)/lua/custom/generated_colors.lua

# bash
BASH_CONFIG_DIR = bash/.config/bash
BASH_COLORS     = $(BASH_CONFIG_DIR)/bash_color.sh

# waybar
WAYBAR_CONFIG_DIR = waybar/.config/waybar
WAYBAR_COLORS     = $(WAYBAR_CONFIG_DIR)/colors.css

# alacritty
ALACRITTY_CONFIG_DIR = alacritty/.config/alacritty
ALACRITTY_COLORS     = $(ALACRITTY_CONFIG_DIR)/colors.toml

# fuzzel
FUZZEL_CONFIG_DIR = fuzzel/.config/fuzzel
FUZZEL_COLORS     = $(FUZZEL_CONFIG_DIR)/colors.ini

# hypr
HYPR_CONFIG_DIR = hypr/.config/hypr
HYPR_COLORS     = $(HYPR_CONFIG_DIR)/colors.lua

# sddm
SDDM_THEME_DIR  = sddm/themes/minimal-onedark
SDDM_COLORS     = $(SDDM_THEME_DIR)/theme.conf

STOW = vim tmux starship nvim bash git hypr waybar fuzzel alacritty

ALL_GENERATED_COLORS = $(BASH_COLORS) $(TMUX_COLORS) $(NVIM_COLORS) $(WAYBAR_COLORS) $(ALACRITTY_COLORS) $(FUZZEL_COLORS) $(HYPR_COLORS) $(SDDM_COLORS)

.PHONY: all stowall apply clean install install-sddm

all: install apply stowall

# Creates all needed paths for all configs to work
install: setup.sh
	@chmod +x ./setup.sh
	@./setup.sh

# apply the new colorscheme to the whole environment
apply: $(ALL_GENERATED_COLORS) $(STARSHIP_CONFIG)

$(ALL_GENERATED_COLORS): $(COLORS_SRC) scripts/color_file_gen.py
	@echo "Generating component colors from $(COLORS_SRC)..."
	@uv run scripts/color_file_gen.py -c $(COLORS_SRC) \
		nvim generated_colors lua $(NVIM_CONFIG_DIR)/lua/custom \
		tmux colors.tmux conf $(TMUX_CONFIG_DIR) \
		bash bash_color sh $(BASH_CONFIG_DIR) \
		waybar colors css $(WAYBAR_CONFIG_DIR) \
		alacritty colors toml $(ALACRITTY_CONFIG_DIR) \
		fuzzel colors ini $(FUZZEL_CONFIG_DIR) \
		hypr colors lua $(HYPR_CONFIG_DIR) \
		sddm theme conf $(SDDM_THEME_DIR)
	@tmux source-file $(TMUX_CONFIG_DIR)/tmux.conf 2>/dev/null || true

$(STARSHIP_CONFIG): $(COLORS_SRC) $(STARSHIP_BASE)
	@echo "Generating Starship colors..."
	@echo "palette = \"onedark_ansii\"" > $@
	@cat $(STARSHIP_BASE) >> $@
	@printf "\n" >> $@
	@cat $(COLORS_SRC) >> $@

clean:
	@echo "Cleaning generated color files..."
	@rm -f $(ALL_GENERATED_COLORS) $(STARSHIP_CONFIG)

# Installs SDDM theme and configuration into system directories
install-sddm: apply
	@echo "Installing SDDM theme and configuration into system paths..."
	@sudo mkdir -p /usr/share/sddm/themes/minimal-onedark
	@sudo cp -r $(SDDM_THEME_DIR)/* /usr/share/sddm/themes/minimal-onedark/
	@sudo mkdir -p /etc/sddm.conf.d
	@sudo cp sddm/sddm.conf.d/theme.conf /etc/sddm.conf.d/theme.conf
	@sudo cp sddm/scripts/Xsetup /usr/share/sddm/scripts/Xsetup
	@sudo chmod +x /usr/share/sddm/scripts/Xsetup
	@echo "SDDM theme installed! Test anytime with: sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/minimal-onedark"

# stows everything
stowall:
	stow -R $(foreach dir, $(STOW), $(dir))
