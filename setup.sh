#!/bin/bash

# TODO: Download Submodule repos in the .dotfiles
# The path to submodules from this script running will always be
# -- ./nvim/.config/nvim/

# Stow all current configs direcotries
make stow

#Source current .bashrc in .dotfiles/bash/.bashrc
source ./bash/.bashrc

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
STOW_VERSION="2.4.1" # latest stable, unchanged since Sep 2024
TMUX_VERSION="3.5a"  # latest tag published by the nelsonenzo/tmux-appimage
# packager we use below. NOTE: that repo lags behind
# upstream tmux (currently 3.7b) -- it's the newest
# this specific install method can offer.
RG_VERSION="15.1.0"
FD_VERSION="10.3.0"
NVIM_VERSION="v0.12.4"  # latest official "stable" release tag
NODE_VERSION="v22.14.0" # for my nvim copilot.lua
TREE_SITTER_VERSION="0.26.6"
CURL_VERSION="8.21.0" # stunnel/static-curl (actively maintained fork of
# moparisthebest/static-curl)
CLANG_SERIES="20" # LLVM/clang series pulled from Ubuntu's own repos
# (see install_clang for why, not llvm.org)
CLANGD_VERSION="22.1.6" # clangd/clangd's own portable "stable" channel
RCLONE_VERSION="v1.74.4"
PIXI_VERSION="0.73.0"
UV_VERSION="0.11.29"
NERD_FONT="FiraCode" # goes through nerd-fonts' /releases/latest/
# redirect since font archives have no CLI
# --version to track/pin against anyway

# Function to install GNU Stow
install_stow() {
	echo "Installing GNU Stow (Static Script)..."

	# Work out of the /tmp directory to keep things clean
	cd /tmp || exit
	curl -LO "https://ftp.gnu.org/gnu/stow/stow-${STOW_VERSION}.tar.gz"
	tar -xzf "stow-${STOW_VERSION}.tar.gz"
	cd "stow-${STOW_VERSION}" || exit

	# Configure the build to install inside your ~/.local directory instead of /usr/local
	./configure --prefix="$HOME/.local"

	# Build and install
	make
	make install

	# Clean up the downloaded files
	cd /tmp || exit
	rm -rf "stow-${STOW_VERSION}" "stow-${STOW_VERSION}.tar.gz"

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

	# NOTE: AppRun resolves its own real path and execs
	# "<that dir>/usr/bin/tmux" (which in turn needs the bundled
	# libevent/ncurses/terminfo alongside it) -- so squashfs-root has to stay
	# on disk as a unit. Symlinking (not copying) AppRun into LOCAL_BIN keeps
	# that relative pathing intact, since readlink -f follows the symlink to
	# its real location before deriving sibling paths.
	rm tmux.appimage
	ln -sf "$XDG_DATA_HOME/tmux/squashfs-root/AppRun" "$LOCAL_BIN/tmux"
	cd "$OLDPWD"

	echo "Tmux installed (AppImage extracted to $XDG_DATA_HOME/tmux, symlinked into $LOCAL_BIN)"
}

install_nvim() {
	echo "Installing Neovim (Binary Release)..."
	rm -rf "$XDG_DATA_HOME/nvim-linux-x86_64"
	OLDPWD=$(pwd)
	cd "$XDG_DATA_HOME" || exit

	# Download Linux x86_64 Tarball (Contains binary + runtime).
	# NOTE: as of Neovim 0.10ish the asset was renamed from nvim-linux64.tar.gz
	# to nvim-linux-x86_64.tar.gz -- using the old name here would 404.
	curl -LO "https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}/nvim-linux-x86_64.tar.gz"

	# Extract
	tar -xzf nvim-linux-x86_64.tar.gz
	rm nvim-linux-x86_64.tar.gz

	# Copy the binary to LOCAL_BIN
	cp "nvim-linux-x86_64/bin/nvim" "$LOCAL_BIN/nvim"
	chmod +x "$LOCAL_BIN/nvim"

	# Cleanup extracted data
	rm -rf "$XDG_DATA_HOME/nvim-linux-x86_64"
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

# Function to install curl (static build, newer/more feature-complete than
# whatever curl your distro ships -- HTTP/3, latest TLS, etc). This only
# helps once $LOCAL_BIN is ahead of /usr/bin in PATH; your system curl is
# what bootstraps this script in the first place.
install_curl() {
	echo "Installing curl ${CURL_VERSION} (static build) to $LOCAL_BIN..."

	local TEMP_DIR
	TEMP_DIR=$(mktemp -d)

	# stunnel/static-curl's own arch naming ("x86_64-musl") is shorter than
	# the $ARCH triple used elsewhere in this script, so it's spelled out here.
	curl -L "https://github.com/stunnel/static-curl/releases/download/${CURL_VERSION}/curl-linux-x86_64-musl-${CURL_VERSION}.tar.xz" -o "$TEMP_DIR/curl.tar.xz"
	tar -xJf "$TEMP_DIR/curl.tar.xz" -C "$TEMP_DIR"

	cp "$TEMP_DIR/curl" "$LOCAL_BIN/curl"
	chmod +x "$LOCAL_BIN/curl"

	rm -rf "$TEMP_DIR"
	echo "curl installed"
}

# Function to install clang + clang-tidy.
#
# llvm.org's own GitHub releases explicitly disclaim reliability here --
# every recent release page says: "Volunteers make binaries for the LLVM
# project... They might not be available directly or not at all for each
# release. We suggest you use the binaries from your distribution." On top
# of that, when Linux x86_64 binaries *are* published they're built against
# an old Ubuntu baseline and link libtinfo.so.5, which no longer exists on
# current Ubuntu -- so the binary wouldn't even run. Ubuntu's own packages
# are the reliable choice, so this pulls those directly from
# archive.ubuntu.com and extracts them without installing anything
# system-wide (no apt/dpkg-as-root involved).
install_clang() {
	echo "Installing clang + clang-tidy (LLVM ${CLANG_SERIES}.x via Ubuntu's packages)..."

	local POOL_URL="http://archive.ubuntu.com/ubuntu/pool/universe/l/llvm-toolchain-${CLANG_SERIES}"
	local LISTING
	LISTING=$(curl -sL "$POOL_URL/")
	if [ -z "$LISTING" ]; then
		echo "Could not reach $POOL_URL"
		return 1
	fi

	# Resolve the exact current filenames instead of hardcoding a Debian
	# revision suffix (e.g. "-2ubuntu8"), since those bump with security
	# updates independently of the upstream clang version.
	local CLANG_DEB CLANG_TIDY_DEB LIBCLANGCPP_DEB
	CLANG_DEB=$(echo "$LISTING" | grep -oE "href=\"clang-${CLANG_SERIES}_[0-9][^\"]*_amd64\.deb\"" | sed 's/href="//;s/"$//' | sort -V | tail -1)
	CLANG_TIDY_DEB=$(echo "$LISTING" | grep -oE "href=\"clang-tidy-${CLANG_SERIES}_[0-9][^\"]*_amd64\.deb\"" | sed 's/href="//;s/"$//' | sort -V | tail -1)
	LIBCLANGCPP_DEB=$(echo "$LISTING" | grep -oE "href=\"libclang-cpp${CLANG_SERIES}_[0-9][^\"]*_amd64\.deb\"" | sed 's/href="//;s/"$//' | sort -V | tail -1)

	if [ -z "$CLANG_DEB" ] || [ -z "$CLANG_TIDY_DEB" ] || [ -z "$LIBCLANGCPP_DEB" ]; then
		echo "Could not find clang-${CLANG_SERIES} packages in Ubuntu's archive"
		return 1
	fi

	local TEMP_DIR
	TEMP_DIR=$(mktemp -d)
	local INSTALL_DIR="$XDG_DATA_HOME/llvm-${CLANG_SERIES}"
	rm -rf "$INSTALL_DIR"
	mkdir -p "$INSTALL_DIR"

	for deb in "$CLANG_DEB" "$CLANG_TIDY_DEB" "$LIBCLANGCPP_DEB"; do
		curl -sL -o "$TEMP_DIR/$deb" "$POOL_URL/$deb"
		dpkg-deb -x "$TEMP_DIR/$deb" "$INSTALL_DIR"
	done

	# clang/clang-tidy dynamically link libclang-cpp, which isn't on the
	# system's normal library path since we didn't install it system-wide --
	# so LOCAL_BIN gets a thin wrapper rather than the raw binary.
	local LLVM_BIN="$INSTALL_DIR/usr/lib/llvm-${CLANG_SERIES}/bin"
	local LLVM_LIB="$INSTALL_DIR/usr/lib/llvm-${CLANG_SERIES}/lib"
	for bin in clang clang-tidy; do
		cat >"$LOCAL_BIN/$bin" <<EOF
#!/bin/sh
exec env LD_LIBRARY_PATH="$LLVM_LIB:\$LD_LIBRARY_PATH" "$LLVM_BIN/$bin" "\$@"
EOF
		chmod +x "$LOCAL_BIN/$bin"
	done

	rm -rf "$TEMP_DIR"
	echo "clang + clang-tidy installed ($CLANG_DEB)"
}

# Function to install clangd. This deliberately does NOT reuse install_clang's
# Ubuntu packages: Ubuntu's clangd is built with remote-index/gRPC support,
# which pulls in gRPC + protobuf + abseil (dozens of extra shared libraries)
# just to run. clangd/clangd's own releases are purpose-built for exactly
# this drop-in-anywhere use case: a single statically-linked binary with the
# clang builtin headers bundled alongside it, zero extra dependencies.
install_clangd() {
	echo "Installing clangd ${CLANGD_VERSION} (portable static release)..."

	local TEMP_DIR
	TEMP_DIR=$(mktemp -d)
	curl -L "https://github.com/clangd/clangd/releases/download/${CLANGD_VERSION}/clangd-linux-${CLANGD_VERSION}.zip" -o "$TEMP_DIR/clangd.zip"
	unzip -q "$TEMP_DIR/clangd.zip" -d "$TEMP_DIR"

	local INSTALL_DIR="$XDG_DATA_HOME/clangd"
	rm -rf "$INSTALL_DIR"
	mv "$TEMP_DIR/clangd_${CLANGD_VERSION}" "$INSTALL_DIR"

	# Symlinked (not copied) so it can still find its sibling lib/clang
	# resource dir, same pattern as node/npm/npx above.
	ln -sf "$INSTALL_DIR/bin/clangd" "$LOCAL_BIN/clangd"

	rm -rf "$TEMP_DIR"
	echo "clangd installed"
}

# Function to install the FiraCode Mono Nerd Font
install_nerd_font() {
	echo "Installing $NERD_FONT Mono Nerd Font to $XDG_DATA_HOME/fonts..."

	local TEMP_DIR
	TEMP_DIR=$(mktemp -d)
	curl -sL "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${NERD_FONT}.zip" -o "$TEMP_DIR/${NERD_FONT}.zip"

	local FONT_DIR="$XDG_DATA_HOME/fonts"
	mkdir -p "$FONT_DIR"
	# Only pull the true monospace ("Mono") weights out of the family zip,
	# not the proportional/regular variants that ship alongside them.
	unzip -o -q "$TEMP_DIR/${NERD_FONT}.zip" "*Mono*.ttf" -d "$FONT_DIR"

	rm -rf "$TEMP_DIR"

	# Refresh the font cache if fontconfig is around to do it.
	if command -v fc-cache &>/dev/null; then
		fc-cache -f "$FONT_DIR" >/dev/null 2>&1
	fi

	echo "$NERD_FONT Mono Nerd Font installed"
}

# Function to install rclone
install_rclone() {
	echo "Installing rclone ${RCLONE_VERSION}..."

	local TEMP_DIR
	TEMP_DIR=$(mktemp -d)
	curl -L "https://github.com/rclone/rclone/releases/download/${RCLONE_VERSION}/rclone-${RCLONE_VERSION}-linux-amd64.zip" -o "$TEMP_DIR/rclone.zip"
	unzip -q "$TEMP_DIR/rclone.zip" -d "$TEMP_DIR"

	cp "$TEMP_DIR/rclone-${RCLONE_VERSION}-linux-amd64/rclone" "$LOCAL_BIN/rclone"
	chmod +x "$LOCAL_BIN/rclone"

	rm -rf "$TEMP_DIR"
	echo "rclone installed"
}

# Function to install the pixi env tool
install_pixi() {
	echo "Installing pixi ${PIXI_VERSION}..."

	local TEMP_DIR
	TEMP_DIR=$(mktemp -d)
	# pixi's musl-linux asset naming matches $ARCH exactly.
	curl -L "https://github.com/prefix-dev/pixi/releases/download/v${PIXI_VERSION}/pixi-${ARCH}.tar.gz" -o "$TEMP_DIR/pixi.tar.gz"
	tar -xzf "$TEMP_DIR/pixi.tar.gz" -C "$TEMP_DIR"

	cp "$TEMP_DIR/pixi" "$LOCAL_BIN/pixi"
	chmod +x "$LOCAL_BIN/pixi"

	rm -rf "$TEMP_DIR"
	echo "pixi installed"
}

# Function to install uv, then give Neovim its own dedicated Python venv
# (~/.local/.venv/nvim) with pynvim installed so nvim's Python provider has
# somewhere to point without polluting any other Python environment.
install_uv() {
	echo "Installing uv ${UV_VERSION}..."

	local TEMP_DIR
	TEMP_DIR=$(mktemp -d)
	# uv's musl-linux asset naming matches $ARCH exactly.
	curl -L "https://github.com/astral-sh/uv/releases/download/${UV_VERSION}/uv-${ARCH}.tar.gz" -o "$TEMP_DIR/uv.tar.gz"
	tar -xzf "$TEMP_DIR/uv.tar.gz" -C "$TEMP_DIR"

	cp "$TEMP_DIR/uv-${ARCH}/uv" "$LOCAL_BIN/uv"
	cp "$TEMP_DIR/uv-${ARCH}/uvx" "$LOCAL_BIN/uvx"
	chmod +x "$LOCAL_BIN/uv" "$LOCAL_BIN/uvx"

	rm -rf "$TEMP_DIR"
	echo "uv installed"
}

# --- TOOLS DETECTION ---
# Pulls the first version-shaped token (optionally v-prefixed, optionally
# with a trailing single letter like tmux's "3.5a") out of whatever text is
# piped in. Unlike `awk '{print $N}'`, this doesn't care which word the
# version number shows up as or how many words come before it -- so it
# survives a distro renaming/reordering its --version banner, e.g.
# "Ubuntu clang version 20.1.8", "Debian clang version 20.1.8",
# "Apple clang version 15.0.0", and plain upstream "clang version 20.1.8"
# all resolve the same way.
extract_version() {
	grep -oE 'v?[0-9]+(\.[0-9]+){1,3}[a-z]?' | head -n1
}

# Returns 0 (true) if current_ver < target_ver
is_version_older() {
	local current=$1
	local target=$2

	# If versions are equal, we don't need to update
	if [ "$current" == "$target" ]; then return 1; fi

	# sort -V sorts version numbers.
	local lowest=$(printf '%s\n%s' "$current" "$target" | sort -V | head -n1)

	if [ "$lowest" == "$current" ]; then
		return 0 # True: Current is older
	else
		return 1 # False: Current is newer or same
	fi
}

echo "Checking tools..."
tools=("stow" "starship" "tmux" "nvim" "fd" "rg" "node" "tree-sitter" "curl" "clang" "clang-tidy" "clangd" "nerd-font" "rclone" "pixi" "uv")
for tool in "${tools[@]}"; do
	NEEDS_INSTALL=false

	if [ "$tool" = "nerd-font" ]; then
		# Fonts have no CLI/version to query, so presence of one of the
		# installed Mono weight files stands in for a version check.
		if [ ! -f "$XDG_DATA_HOME/fonts/${NERD_FONT}NerdFontMono-Regular.ttf" ]; then
			echo "⚠️  $tool not found. Marking for install."
			NEEDS_INSTALL=true
		else
			echo "✓ $tool is already installed."
		fi
	# 1. Check if the tool exists at all
	elif ! command -v "$tool" &>/dev/null; then
		echo "⚠️  $tool not found. Marking for install."
		NEEDS_INSTALL=true
	else
		# 2. Tool exists, check version
		CURRENT_VER=""
		TARGET_VER=""

		case "$tool" in
		node)
			# Node output: "v22.14.0"
			CURRENT_VER=$(node -v | extract_version)
			TARGET_VER="$NODE_VERSION"
			;;
		nvim)
			# Nvim output: "NVIM v0.12.4\n..." -> "v0.12.4"
			CURRENT_VER=$(nvim --version | head -n1 | extract_version)
			TARGET_VER="$NVIM_VERSION"
			;;
		tmux)
			# Tmux output: "tmux 3.5a" -> "3.5a"
			CURRENT_VER=$(tmux -V | extract_version)
			TARGET_VER="$TMUX_VERSION"
			;;
		stow)
			# Stow output: "stow (GNU Stow) 2.4.1" -> "2.4.1"
			CURRENT_VER=$(stow --version | extract_version)
			TARGET_VER="$STOW_VERSION"
			;;
		rg)
			# rg output: "ripgrep 15.1.0 (rev ...)" -> "15.1.0"
			CURRENT_VER=$(rg --version | head -n1 | extract_version)
			TARGET_VER="$RG_VERSION"
			;;
		fd)
			# fd output: "fd 10.3.0" -> "10.3.0"
			CURRENT_VER=$(fd --version | extract_version)
			TARGET_VER="$FD_VERSION"
			;;
		tree-sitter)
			# tree-sitter output: "tree-sitter 0.26.6" -> "0.26.6"
			CURRENT_VER=$(tree-sitter --version | extract_version)
			TARGET_VER="$TREE_SITTER_VERSION"
			;;
		curl)
			# curl output: "curl 8.21.0 (...) libcurl/8.21.0 ..." -> "8.21.0"
			CURRENT_VER=$(curl --version | head -n1 | extract_version)
			TARGET_VER="$CURL_VERSION"
			;;
		clang)
			# clang output varies by distro/vendor ("Ubuntu clang version
			# 20.1.8 (2ubuntu8)", "Debian clang version 20.1.8 (11)", plain
			# upstream "clang version 20.1.8", "Apple clang version 15.0.0",
			# ...) -- extract_version finds the version regardless of what
			# comes before it, then we keep only the major series, since
			# the exact patch/revision is resolved dynamically at install
			# time rather than pinned.
			CURRENT_VER=$(clang --version | head -n1 | extract_version | cut -d. -f1)
			TARGET_VER="$CLANG_SERIES"
			;;
		clang-tidy)
			# Same reasoning as clang above.
			CURRENT_VER=$(clang-tidy --version | head -n1 | extract_version | cut -d. -f1)
			TARGET_VER="$CLANG_SERIES"
			;;
		clangd)
			# clangd output: "clangd version 22.1.6 (https://...)" -> "22.1.6"
			CURRENT_VER=$(clangd --version | head -n1 | extract_version)
			TARGET_VER="$CLANGD_VERSION"
			;;
		rclone)
			# rclone output: "rclone v1.74.4" -> "v1.74.4"
			CURRENT_VER=$(rclone version | head -n1 | extract_version)
			TARGET_VER="$RCLONE_VERSION"
			;;
		pixi)
			# pixi output: "pixi 0.73.0" -> "0.73.0"
			CURRENT_VER=$(pixi --version | extract_version)
			TARGET_VER="$PIXI_VERSION"
			;;
		uv)
			# uv output: "uv 0.11.29 (...)" -> "0.11.29"
			CURRENT_VER=$(uv --version | extract_version)
			TARGET_VER="$UV_VERSION"
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
		curl) install_curl ;;
		clang) install_clang ;;
		clang-tidy) install_clang ;; # same package family/download as clang
		clangd) install_clangd ;;
		nerd-font) install_nerd_font ;;
		rclone) install_rclone ;;
		pixi) install_pixi ;;
		uv) install_uv ;;
		esac
	fi
done


echo "Setting up nvim's dedicated Python venv..."
NVIM_VENV="$HOME/.local/.venv/nvim"
mkdir -p "$HOME/.local/.venv"
uv venv --seed "$NVIM_VENV"
uv pip install --venv "$NVIM_VENV" pynvim pip setuptools
echo "nvim's Python venv ready at $NVIM_VENV (point g:python3_host_prog at $NVIM_VENV/bin/python)"
