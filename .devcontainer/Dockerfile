FROM ruby:3.3.6

# Installer les dépendances système essentielles
RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    sqlite3 \
    libsqlite3-dev \
    nodejs \
    npm \
    curl \
    wget \
    vim \
    less \
    chromium \
    chromium-driver \
    && rm -rf /var/lib/apt/lists/*

# Installer bundler et autres gems utiles
RUN gem install bundler rake

# Configuration pour éviter les problèmes de permissions
RUN mkdir -p /usr/local/bundle && chmod -R 777 /usr/local/bundle

# Créer un utilisateur non-root pour plus de sécurité
RUN useradd -m -s /bin/bash vscode && \
    usermod -aG sudo vscode && \
    echo "vscode ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Créer le répertoire de travail
WORKDIR /workspace

# Changer le propriétaire du workspace
RUN chown -R vscode:vscode /workspace

# Passer à l'utilisateur non-root
USER vscode
