FROM archlinux:latest

# 1) Toolchain + deps
RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm \
      base-devel meson ninja cmake git pkgconf \
      wayland wayland-protocols libxkbcommon libdrm libcap \
      libdisplay-info libliftoff \
      vulkan-headers vulkan-icd-loader libglvnd \
      libx11 libxrandr libxcb xorgproto libxxf86vm \
      pipewire libpipewire \
      libinput seatd systemd-libs \
      libxfixes libxdamage libxrender libxcomposite \
      xcb-util xcb-util-wm xcb-util-keysyms \
      libxcursor libxtst libxres libxmu libxi libxinerama \
      pixman libei sdl2 libavif hwdata \
      glslang spirv-tools spirv-headers luajit \
      xorg-xwayland lcms2

# 2) Build gamescope
RUN useradd -m builder
USER builder
WORKDIR /home/builder

RUN git clone --recursive https://github.com/ValveSoftware/gamescope.git
WORKDIR /home/builder/gamescope

RUN meson setup build -Dpipewire=enabled --prefix=/opt/gamescope && \
    ninja -C build && \
    meson install -C build --destdir /home/builder/stage

# 3) AppDir portable + wrapper
USER root
RUN mkdir -p /appdir/bin /appdir/lib && \
    cp -a /home/builder/stage/opt/gamescope/* /appdir/

RUN set -e; \
    NEED=$(ldd /appdir/bin/gamescope | awk '{print $3}' | grep -E '^/' || true); \
    for f in $NEED; do \
      base=$(basename "$f"); \
      case "$base" in \
        ld-linux*|libc.so.*|libm.so.*|libdl.so.*|libpthread.so.*|librt.so.*|libgcc_s.so.*|libstdc++.so.*) continue ;; \
      esac; \
      cp -n "$f" /appdir/lib/ || true; \
    done

RUN cat >/appdir/bin/gamescope-portable <<'EOF'
#!/usr/bin/env bash
HERE="$(cd "$(dirname "$0")" && pwd)"
export LD_LIBRARY_PATH="$HERE/../lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
exec "$HERE/gamescope" "$@"
EOF
RUN chmod +x /appdir/bin/gamescope-portable

WORKDIR /
RUN mkdir -p /out && tar -czf /out/gamescope-portable.tar.gz appdir
