# Gamescope Portable

I Originally made this because there's no Gamescope repo for my Pop!_OS 22.04 that i can use, there are some but they're also outdated. I use Gamescope mainly just for Wayland Compositor to run Waydroid on it. Since i use NVIDIA Graphics Card, i much prefer to run Waydroid on X11 (Xorg) instead of using Wayland directly

## Features
- Built inside Docker (Arch Linux) means that the final binaries are not tied to the host system.
- Installed under `/opt/gamescope-portable`
- Wrapper script `gamescope-portable` to run it directly without Docker.
- Can coexist with the distro-provided `gamescope` package.

## Build

Clone this repo:

```bash
git clone https://github.com/yanuaraudi/gamescope-portable.git
cd gamescope-portable
```

Build with Docker:
```bash
docker build -t gamescope-builder .
```

Extract the build result into ```/opt/gamescope-portable```:
```bash
sudo mkdir -p /opt/gamescope-portable
docker run --rm -v /opt/gamescope-portable:/out gamescope-builder cp -a /appdir/* /out/
```

Install Wrapper:
```bash
sudo tee /usr/local/bin/gamescope-portable >/dev/null <<'EOF'

#!/usr/bin/env bash
GSDIR="/opt/gamescope-portable"

export LD_LIBRARY_PATH="$GSDIR/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

export XDG_DATA_DIRS="$GSDIR/share:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"

exec "$GSDIR/bin/gamescope" "$@"
EOF
```
```bash
sudo chmod +x /usr/local/bin/gamescope-portable
```

## Usage

Run like normal but instead of using ```gamescope```, run with:
```bash
gamescope-portable
```

## Notes

- These binaries are built with a newer glibc (≥ 2.38).
On hosts with older glibc, you may need to run directly inside the container (method 1).

- The wrapper method (method 2) is easier, but can conflict with system libraries if LD_LIBRARY_PATH isn’t set properly.