# Gopher Getter

**Gopher Getter** is a simple, cross-platform Bash script to automatically download and install the latest stable version of [Go](https://golang.org/).
It verifies the download using SHA256 checksums from the official Go JSON API.

## Features

- Automatically detects the latest stable Go version.
- Works on Linux and macOS.
- Verifies SHA256 checksums for integrity.
- Installs Go to `~/.local/go` by default.
- Easy to integrate into your PATH.

## Installation

1. Clone the repository to `~/projects/gopher-getter`:

```bash
mkdir -p ~/projects
git clone https://github.com/your-username/gopher-getter.git ~/projects/gopher-getter
```

2. Make the script executable:

```bash
chmod +x ~/projects/gopher-getter/gopher-getter.sh
```

3. Symlink the script to your local bin directory:

```bash
mkdir -p ~/.local/bin
ln -s ~/projects/gopher-getter/gopher-getter.sh ~/.local/bin/gopher-getter
```

4. Ensure that `~/.local/bin` is in your path:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

You can add the above line to your shell configuration file (`~/.bashrc`, `~/.zshrc`, etc.) to make it permanent.

## Usage

Simply run:

```bash
gopher-getter
```

The script will:
- Check the latest stable Go version.
- Compare it to your current installation.
- Download and install the latest version if needed.

## Contributing

If you see a problem or improvement that can be made, please open up an issue to discuss it.

## License

Copyright© 2026 Ryan Hendrickson. Released under the BSD-2-Clause License. See [LICENSE](LICENSE) for details.

