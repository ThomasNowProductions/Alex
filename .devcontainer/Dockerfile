FROM ubuntu:22.04

# Avoid interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Install basic dependencies
RUN echo "Installing basic dependencies..." && \
    apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    pkg-config \
    python3 \
    python3-pip \
    openssh-client \
    rsync \
    libssl-dev \
    libxslt1-dev \
    libxml2-dev \
    libffi-dev \
    libncurses5-dev \
    libncursesw5-dev \
    libreadline-dev \
    libsqlite3-dev \
    libgdbm-dev \
    libc6-dev \
    libbz2-dev \
    zlib1g-dev \
    liblzma-dev \
    tk-dev \
    build-essential \
    cmake \
    ninja-build \
    pkg-config \
    libgtk-3-dev \
    liblzma-dev \
    libstdc++6 \
    openjdk-17-jdk \
    && rm -rf /var/lib/apt/lists/*

# Install Chrome for web development
RUN echo "Installing Chrome for web development..." && \
    wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list \
    && apt-get update \
    && apt-get install -y google-chrome-stable \
    && rm -rf /var/lib/apt/lists/*

# Set up Flutter
ENV FLUTTER_VERSION=3.24.5
ENV FLUTTER_HOME=/flutter
ENV PATH="$PATH:${FLUTTER_HOME}/bin"

# Download and install Flutter
RUN echo "Downloading and installing Flutter ${FLUTTER_VERSION}..." && \
    wget -O flutter.tar.xz https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz \
    && mkdir -p /flutter \
    && tar -xf flutter.tar.xz -C /flutter --strip-components=1 \
    && rm flutter.tar.xz

# Configure Flutter
RUN echo "Configuring Flutter..." && \
    git config --global --add safe.directory /flutter \
    && flutter channel stable \
    && flutter upgrade \
    && flutter config --enable-web \
    && flutter config --enable-android \
    && flutter config --enable-ios \
    && flutter doctor

# Install Android SDK
ENV ANDROID_SDK_ROOT=/opt/android-sdk
ENV ANDROID_HOME=/opt/android-sdk
ENV PATH="$PATH:${ANDROID_HOME}/tools:${ANDROID_HOME}/tools/bin:${ANDROID_HOME}/platform-tools"
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64

# Download and install Android SDK using temporary directory approach
RUN echo "Downloading and installing Android SDK..." && \
    wget -O android-sdk.zip https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip \
    && mkdir -p /tmp/android-sdk \
    && unzip -q android-sdk.zip -d /tmp/android-sdk \
    && mkdir -p ${ANDROID_SDK_ROOT}/cmdline-tools/latest \
    && mv /tmp/android-sdk/cmdline-tools/* ${ANDROID_SDK_ROOT}/cmdline-tools/latest/ \
    && rm -rf /tmp/android-sdk \
    && rm android-sdk.zip

# Install Android SDK components
RUN echo "Installing Android SDK components..." && \
    yes | ${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin/sdkmanager --sdk_root=${ANDROID_SDK_ROOT} "platform-tools" "platforms;android-34" "build-tools;34.0.0"

# Create a non-root user
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN echo "Creating non-root user..." && \
    groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && apt-get update \
    && apt-get install -y sudo \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME \
    && rm -rf /var/lib/apt/lists/*

# Set ownership of Flutter and Android SDK
RUN echo "Setting ownership of Flutter and Android SDK..." && \
    chown -R $USERNAME:$USERNAME ${FLUTTER_HOME} ${ANDROID_SDK_ROOT}

# Switch to non-root user
USER $USERNAME

# Create workspace directory
WORKDIR /workspace

# Set up environment variables for the user
ENV PATH="$PATH:${FLUTTER_HOME}/bin:${ANDROID_HOME}/tools:${ANDROID_HOME}/tools/bin:${ANDROID_HOME}/platform-tools"

# Accept Android licenses (non-interactive)
RUN echo "Accepting Android licenses..." && \
    yes | ${ANDROID_HOME}/cmdline-tools/latest/bin/sdkmanager --licenses > /dev/null 2>&1

# Initialize Flutter
RUN echo "Running Flutter doctor..." && \
    flutter doctor -v

# Expose ports for web development
EXPOSE 3000 8080 5000

# Set the default command
CMD ["/bin/bash"]