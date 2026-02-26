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

# Architecture for static binaries (musl is best for portability)
ARCH="x86_64-unknown-linux-musl"

# Make sure .local/bin exists
LOCAL_BIN="$HOME/.local/bin"
mkdir -p "$LOCAL_BIN"

# --- Function to Install Tools ---
STOW_VERSION="2.4.1"
TMUX_VERSION="3.3a" # Reliable version
RG_VERSION="15.1.0"
NVIM_VERSION="v0.11.5"
NODE_VERSION="v22.14.0" # for my nvim copilot.lua

# Function to install GNU Stow
install_stow() {
	echo "Installing GNU Stow (Static Script)..."

	rm -rf "$LOCAL_SHARE/stow-${STOW_VERSION}"

	# Download tarball
	cd "$LOCAL_SHARE" || exit
	curl -LO "https://ftp.gnu.org/gnu/stow/stow-${STOW_VERSION}.tar.gz"
	tar -xzf "stow-${STOW_VERSION}.tar.gz"
	rm "stow-${STOW_VERSION}.tar.gz"

	# Symlink the binary directly (Stow is just a Perl script, no compile needed)
	# We must link it so it finds its own library modules relative to the symlink
	ln -sf "$LOCAL_SHARE/stow-${STOW_VERSION}/bin/stow" "$LOCAL_BIN/stow"

	echo "GNU Stow installed"
}

# Function to install Starship
install_starship() {
	echo "Installing Starship to $LOCAL_BIN..."
	# -s -- -y skips confirmation
	# -b specifies the binary directory
	curl -sS https://starship.rs/install.sh | sh -s -- -y -b "$LOCAL_BIN"
	echo "Starship installed"
}

# Function to install tmux
install_tmux() {
	echo "Installing Tmux (Static AppImage)..."
	# We use the AppImage but extract it to avoid FUSE requirement on Uni computers

	rm -rf "$LOCAL_SHARE/tmux"

	mkdir -p "$LOCAL_SHARE/tmux"
	cd "$LOCAL_SHARE/tmux" || exit

	# Download AppImage
	curl -LO "https://github.com/nelsonenzo/tmux-appimage/releases/download/${TMUX_VERSION}/tmux.appimage"
	chmod +x tmux.appimage

	# Extract it (Bypasses FUSE requirement)
	./tmux.appimage --appimage-extract >/dev/null

	# Link the internal binary
	ln -sf "$LOCAL_SHARE/tmux/squashfs-root/AppRun" "$LOCAL_BIN/tmux"

	# Cleanup
	rm tmux.appimage

	echo "Tmux installed (Extracted AppImage)"
}

install_nvim() {
	echo "Installing Neovim (Binary Release)..."

	rm -rf "$LOCAL_SHARE/nvim-linux64"

	cd "$LOCAL_SHARE" || exit

	# Download Linux64 Tarball (Contains binary + runtime)
	curl -LO "https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}/nvim-linux64.tar.gz"

	# Extract
	tar -xzf nvim-linux64.tar.gz
	rm nvim-linux64.tar.gz

	# Symlink the binary
	ln -sf "$LOCAL_SHARE/nvim-linux64/bin/nvim" "$LOCAL_BIN/nvim"

	echo "Neovim installed"
}

# Function to install live-grep
install_ripgrep() {
	echo "Installing ripgrep (rg) to $LOCAL_BIN..."

	# Download ripgrep
	curl -LO "https://github.com/BurntSushi/ripgrep/releases/download/${RG_VERSION}/ripgrep-${RG_VERSION}-${ARCH}.tar.gz"
	# Extract specific binary to stdout and write to destination
	tar -xzf "ripgrep-${RG_VERSION}-${ARCH}.tar.gz" --strip-components=1 -C "$HOME/.local/bin" "ripgrep-${RG_VERSION}-${ARCH}/rg"
	chmod +x "$HOME/.local/bin/rg"
	# Cleanup
	rm "ripgrep-${RG_VERSION}-${ARCH}.tar.gz"

	echo "ripgrep installed"
}

install_fd_find() {
	echo "Installing fd_find (fd) to $LOCAL_BIN..."

	FD_VERSION="10.3.0"
	# Download fd
	curl -LO "https://github.com/sharkdp/fd/releases/download/v${FD_VERSION}/fd-v${FD_VERSION}-${ARCH}.tar.gz"
	# Extract specific binary
	tar -xzf "fd-v${FD_VERSION}-${ARCH}.tar.gz" --strip-components=1 -C "$HOME/.local/bin" "fd-v${FD_VERSION}-${ARCH}/fd"
	chmod +x "$HOME/.local/bin/fd"
	# Cleanup
	rm "fd-v${FD_VERSION}-${ARCH}.tar.gz"

	echo "fd_find installed"
}

install_node() {
	echo "Installing Node.js (LTS)..."
	NODE_DIST="node-${NODE_VERSION}-linux-x64"

	# 1. Clean up old install
	rm -rf "$LOCAL_SHARE/node-linux-x64"

	# 2. Download and Extract
	# Note: Node uses .tar.xz, which requires the 'J' flag or auto-detection
	cd "$LOCAL_SHARE" || exit
	curl -LO "https://nodejs.org/dist/${NODE_VERSION}/${NODE_DIST}.tar.xz"

	echo "   (Extracting... this might take a moment)"
	tar -xf "${NODE_DIST}.tar.xz"
	rm "${NODE_DIST}.tar.xz"

	# Rename to a generic folder so we don't have to update symlinks constantly
	mv "${NODE_DIST}" "node-linux-x64"

	# 3. Symlink binaries
	# We link individually so we don't pollute PATH with other junk
	ln -sf "$LOCAL_SHARE/node-linux-x64/bin/node" "$LOCAL_BIN/node"
	ln -sf "$LOCAL_SHARE/node-linux-x64/bin/npm" "$LOCAL_BIN/npm"
	ln -sf "$LOCAL_SHARE/node-linux-x64/bin/npx" "$LOCAL_BIN/npx"
	ln -sf "$LOCAL_SHARE/node-linux-x64/bin/corepack" "$LOCAL_BIN/corepack"

	echo "Node.js ${NODE_VERSION} installed"
}
# --- TOOLS ---

# Check for dependencies
tools=("stow" "starship" "tmux" "nvim" "fd_find" "ripgrep")
for tool in "${tools[@]}"; do
	if ! command -v "$tool" &>/dev/null; then
		echo "⚠️ $tool not found."
		if [ "$tool" == "stow" ]; then
			install_stow
		elif [ "$tool" == "starship" ]; then
			install_starship
		elif [ "$tool" == "tmux" ]; then
			install_tmux
		elif [ "$tool" == "nvim" ]; then
			install_nvim
		elif [ "$tool" == "fd_find" ]; then
			install_fd_find
		elif [ "$tool" == "ripgrep" ]; then
			install_ripgrep
		fi
	else
		echo "✓ $tool is already installed."
	fi
done
