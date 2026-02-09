#!/bin/bash

#Assign XDG standard directories if they don't exist
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

# Create XDG standard dirs
mkdir -p "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME" "$XDG_CACHE_HOME"

# Vim tmp data
mkdir -p "$XDG_STATE_HOME/vim"

# --- TOOLS ---

# Make sure .local/bin exists
LOCAL_BIN="$HOME/.local/bin"
mkdir -p "$LOCAL_BIN"

# Make sure make is installed
if ! command -v "make" &> /dev/null; then
	echo "\e[31mERROR: Make not installed\e[0m"
	exit 127
fi

# Function to install GNU Stow
install_stow() {
	echo "Installing GNU Stow to $LOCAL_BIN..."
	TEMP_DIR=$(mktemp -d)
	cd "$TEMP_DIR" || exit
	
	# Download Stow
	curl -LO https://ftp.gnu.org/gnu/stow/stow-latest.tar.gz
	tar -xzf stow-latest.tar.gz
	cd stow-*/

	# Configure to install in ~/.local
	./configure --prefix="$HOME/.local"
	make && make install
	
	cd "$HOME"
	rm -rf "$TEMP_DIR"
	echo "GNU Stow Installed"
}

# Function to install Starship
install_starship() {
	echo "Installing Starship to $LOCAL_BIN..."
    # -s -- -y skips confirmation
    # -b specifies the binary directory
    curl -sS https://starship.rs/install.sh | sh -s -- -y -b "$LOCAL_BIN"
	echo "Starship Installed"
}

# Function to install tmux
install_tmux() {
	echo "Installing tmux to $LOCAL_BIN..."

	# Set premissison
	chmod +x scripts/install_tmux.sh

	# Donwloads tmux and all its dependencies TODO:
	./scripts/install_tmux.sh

	echo "tmux Installed"
}

# Function to install nvim
install_nvim() {
	echo "Installing Neovim to $LOCAL_BIN..."

	# Download nvim version $ver
	curl -LO "https://github.com/neovim/neovim/releases/download/$1/nvim.appimage"

	# Move and set premissions
	chmod +x nvim.appimage
	mv nvim.appimage "$LOCAL_BIN/nvim"

	echo "Neovim Installed"
}

# Check for dependencies
nvim_ver_req="v0.11.5"
tools=("stow" "starship" "tmux" "nvim")
for tool in "${tools[@]}"; do
	if ! command -v "$tool" &> /dev/null; then
		echo "⚠️ $tool not found."
		if [ "$tool" == "stow" ]; then
			install_stow
		elif [ "$tool" == "starship" ]; then
			install_starship
		elif [ "$tool" == "tmux" ]; then
			install_tmux
		elif [ "$tool" == "nvim" ]; then
			install_nvim "$nvim_ver_req"
		fi
	else
		echo "✓ $tool is already installed."
	fi
done
