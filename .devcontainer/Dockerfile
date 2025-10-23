# syntax=docker/dockerfile:1
FROM mcr.microsoft.com/devcontainers/flutter:latest

# Install additional build tools required for Flutter desktop and plugin development
RUN apt-get update \
    && export DEBIAN_FRONTEND=noninteractive \
    && apt-get install -y --no-install-recommends \
        clang \
        cmake \
        ninja-build \
        pkg-config \
        libgtk-3-dev \
        liblzma-dev \
        libglu1-mesa \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Pre-download common Flutter artifacts to speed up first run
RUN flutter config --enable-web \
    && flutter precache --web --linux-desktop
