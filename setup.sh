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
STOW_VERSION="2.3.1"
TMUX_VERSION="3.3a" # Reliable version
RG_VERSION="15.1.0"
FD_VERSION="10.3.0"
NVIM_VERSION="v0.11.5"
NODE_VERSION="v22.14.0" # for my nvim copilot.lua
TREE_SITTER_VERSION="0.26.6"

# Function to install GNU Stow
install_stow() {
	echo "Installing GNU Stow (Static Script)..."

	rm -rf "$XDG_DATA_HOME/stow-${STOW_VERSION}"

	OLDPWD=$(pwd)
	cd "$XDG_DATA_HOME" || exit
	curl -LO "https://ftp.gnu.org/gnu/stow/stow-${STOW_VERSION}.tar.gz"
	tar -xzf "stow-${STOW_VERSION}.tar.gz"
	rm "stow-${STOW_VERSION}.tar.gz"
	cd "$OLDPWD" || exit

	# Symlink the binary so it finds its own library modules relative to the symlink
	ln -sf "$XDG_DATA_HOME/stow-${STOW_VERSION}/bin/stow" "$LOCAL_BIN/stow"

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
	rm -rf "$XDG_DATA_HOME/tmux"
	mkdir -p "$XDG_DATA_HOME/tmux"
	OLDPWD=$(pwd)
	cd "$XDG_DATA_HOME/tmux" || exit

	# Download AppImage
	curl -LO "https://github.com/nelsonenzo/tmux-appimage/releases/download/${TMUX_VERSION}/tmux.appimage"
	chmod +x tmux.appimage

	# Extract it (Bypasses FUSE requirement)
	./tmux.appimage --appimage-extract >/dev/null

	# Copy the binary to LOCAL_BIN
	cp "squashfs-root/AppRun" "$LOCAL_BIN/tmux"
	chmod +x "$LOCAL_BIN/tmux"

	# Cleanup
	rm tmux.appimage
	cd "$OLDPWD"
	rm -rf "$XDG_DATA_HOME/tmux"

	echo "Tmux installed (Extracted AppImage and cleaned up)"
}

install_nvim() {
	echo "Installing Neovim (Binary Release)..."
	rm -rf "$XDG_DATA_HOME/nvim-linux64"
	OLDPWD=$(pwd)
	cd "$XDG_DATA_HOME" || exit

	# Download Linux64 Tarball (Contains binary + runtime)
	curl -LO "https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}/nvim-linux64.tar.gz"

	# Extract
	tar -xzf nvim-linux64.tar.gz
	rm nvim-linux64.tar.gz

	# Copy the binary to LOCAL_BIN
	cp "nvim-linux64/bin/nvim" "$LOCAL_BIN/nvim"
	chmod +x "$LOCAL_BIN/nvim"

	# Cleanup extracted data
	rm -rf "$XDG_DATA_HOME/nvim-linux64"
	cd "$OLDPWD"

	echo "Neovim installed (binary copied and data cleaned up)"
}

# Function to install live-grep
install_ripgrep() {
	echo "Installing ripgrep (rg) to $LOCAL_BIN..."

	# Download ripgrep
	curl -LO "https://github.com/BurntSushi/ripgrep/releases/download/${RG_VERSION}/ripgrep-${RG_VERSION}-${ARCH}.tar.gz"
	# Extract specific binary to LOCAL_BIN
	mkdir -p "$XDG_DATA_HOME/rg-tmp"
	tar -xzf "ripgrep-${RG_VERSION}-${ARCH}.tar.gz" --strip-components=1 -C "$XDG_DATA_HOME/rg-tmp" "ripgrep-${RG_VERSION}-${ARCH}/rg"
	cp "$XDG_DATA_HOME/rg-tmp/rg" "$LOCAL_BIN/rg"
	chmod +x "$LOCAL_BIN/rg"
	# Cleanup
	rm "ripgrep-${RG_VERSION}-${ARCH}.tar.gz"
	rm -rf "$XDG_DATA_HOME/rg-tmp"

	echo "ripgrep installed (binary copied and data cleaned up)"
}

install_fd_find() {
	echo "Installing fd_find (fd) to $LOCAL_BIN..."

	FD_VERSION="10.3.0"
	# Download fd
	curl -LO "https://github.com/sharkdp/fd/releases/download/v${FD_VERSION}/fd-v${FD_VERSION}-${ARCH}.tar.gz"
	# Extract specific binary to temp dir
	mkdir -p "$XDG_DATA_HOME/fd-tmp"
	tar -xzf "fd-v${FD_VERSION}-${ARCH}.tar.gz" --strip-components=1 -C "$XDG_DATA_HOME/fd-tmp" "fd-v${FD_VERSION}-${ARCH}/fd"
	cp "$XDG_DATA_HOME/fd-tmp/fd" "$LOCAL_BIN/fd"
	chmod +x "$LOCAL_BIN/fd"
	# Cleanup
	rm "fd-v${FD_VERSION}-${ARCH}.tar.gz"
	rm -rf "$XDG_DATA_HOME/fd-tmp"

	echo "fd_find installed (binary copied and data cleaned up)"
}

install_node() {
	echo "Installing Node.js ${NODE_VERSION}..."

	# Define the final destination
	local NODE_DIR="$XDG_DATA_HOME/node-linux-x64"
	local DIST_NAME="node-${NODE_VERSION}-linux-x64"

	# 1. Clean up old install (Force remove)
	rm -rf "$NODE_DIR"

	# 2. Create a Temp Directory for download/extraction
	local TEMP_DIR=$(mktemp -d)

	echo "   Downloading to temp..."
	# Download tar.xz to temp
	curl -L "https://nodejs.org/dist/${NODE_VERSION}/${DIST_NAME}.tar.xz" -o "$TEMP_DIR/node.tar.xz"

	echo "   Extracting..."
	# Extract inside temp
	tar -xf "$TEMP_DIR/node.tar.xz" -C "$TEMP_DIR"

	echo "   Moving to $XDG_DATA_HOME..."
	# 3. Move the extracted folder to the final location
	# We move "$TEMP_DIR/node-v22..." to "$XDG_DATA_HOME/node-linux-x64"
	mv "$TEMP_DIR/$DIST_NAME" "$NODE_DIR"

	# 4. Create Symlinks
	ln -sf "$NODE_DIR/bin/node" "$LOCAL_BIN/node"
	ln -sf "$NODE_DIR/bin/npm" "$LOCAL_BIN/npm"
	ln -sf "$NODE_DIR/bin/npx" "$LOCAL_BIN/npx"

	# 5. Cleanup
	rm -rf "$TEMP_DIR"

	echo "Node.js installed to $NODE_DIR"
}

install_tree_sitter() {
	echo "Installing tree-sitter ${TREE_SITTER_VERSION}..."

	# Download gz to local bin
	curl -L "https://github.com/tree-sitter/tree-sitter/releases/download/v${TREE_SITTER_VERSION}/tree-sitter-linux-x64.gz" -o "$LOCAL_BIN/tree-sitter.gz"

	# extract in local bin
	gunzip -f "$LOCAL_BIN/tree-sitter.gz"

	# Make executable
	chmod +x "$LOCAL_BIN/tree-sitter"

	echo "tree-sitter Installed"
}

# --- TOOLS DETECTION ---
# Returns 0 (true) if current_ver < target_ver
is_version_older() {
	local current=$1
	local target=$2

	# If versions are equal, we don't need to update
	if [ "$current" == "$target" ]; then return 1; fi

	# sort -V sorts version numbers.
	# We list 'current' and 'target'. If 'current' is the first item
	# in the sorted list, it means it is the smaller (older) one.
	local lowest=$(printf '%s\n%s' "$current" "$target" | sort -V | head -n1)

	if [ "$lowest" == "$current" ]; then
		return 0 # True: Current is older
	else
		return 1 # False: Current is newer or same
	fi
}

echo "Checking tools..."
tools=("stow" "starship" "tmux" "nvim" "fd" "rg" "node" "tree-sitter")
for tool in "${tools[@]}"; do
	NEEDS_INSTALL=false

	# 1. Check if the tool exists at all
	if ! command -v "$tool" &>/dev/null; then
		echo "⚠️  $tool not found. Marking for install."
		NEEDS_INSTALL=true
	else
		# 2. Tool exists, check version
		CURRENT_VER=""
		TARGET_VER=""

		case "$tool" in
		node)
			# Node output: "v22.14.0" -> We keep the 'v' because TARGET has it
			CURRENT_VER=$(node -v)
			TARGET_VER="$NODE_VERSION"
			;;
		nvim)
			# Nvim output: "NVIM v0.11.5" -> Extract "v0.11.5"
			CURRENT_VER=$(nvim --version | head -n1 | grep -o "v[0-9].*")
			TARGET_VER="$NVIM_VERSION"
			;;
		tmux)
			# Tmux output: "tmux 3.3a" -> Extract "3.3a"
			CURRENT_VER=$(tmux -V | awk '{print $2}')
			TARGET_VER="$TMUX_VERSION"
			;;
		stow)
			# Stow output: "stow (GNU Stow) 2.3.1" -> Extract "2.3.1"
			CURRENT_VER=$(stow --version | awk '{print $NF}')
			TARGET_VER="$STOW_VERSION"
			;;
		rg)
			# rg output: "ripgrep 15.1.0" -> Extract "15.1.0"
			CURRENT_VER=$(rg --version | head -n1 | awk '{print $2}')
			TARGET_VER="$RG_VERSION"
			;;
		fd)
			# fd output: "fd 10.3.0" -> Extract "10.3.0"
			CURRENT_VER=$(fd --version | awk '{print $2}')
			TARGET_VER="$FD_VERSION"
			;;
		tree-sitter)
			# tree-sitter output: "tree-sitter 0.26.6" -> Extract "0.26.6"
			CURRENT_VER=$(tree-sitter --version | awk '{print $2}')
			TARGET_VER="$TREE_SITTER_VERSION"
			;;
		*)
			# Fallback for simple tools (starship)
			CURRENT_VER="unknown"
			;;
		esac

		# 3. Compare Logic
		if [ "$CURRENT_VER" != "unknown" ]; then
			if is_version_older "$CURRENT_VER" "$TARGET_VER"; then
				echo "⚠️  $tool is old ($CURRENT_VER < $TARGET_VER). Updating..."
				NEEDS_INSTALL=true
			else
				echo "✓ $tool is up to date ($CURRENT_VER)."
			fi
		fi
	fi

	# 4. Execute Install if needed
	if [ "$NEEDS_INSTALL" = true ]; then
		case "$tool" in
		stow) install_stow ;;
		starship) install_starship ;;
		tmux) install_tmux ;;
		nvim) install_nvim ;;
		fd) install_fd_find ;;
		rg) install_ripgrep ;;
		node) install_node ;;
		tree-sitter) install_tree_sitter ;;
		esac
	fi
done
