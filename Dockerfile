# =============================================================================
# Claude Code Dev Container - Full-stack development environment
# Base: node:20 (required for Claude Code)
# Added: Java 17, Maven, TypeScript, Angular, DB clients, Git
# =============================================================================

FROM node:20-bookworm

# Versions - easy to bump
ARG CLAUDE_CODE_VERSION=latest
ARG JAVA_VERSION=17
ARG MAVEN_VERSION=3.9.9
ARG ANGULAR_CLI_VERSION=19

# Avoid interactive prompts during build
ENV DEBIAN_FRONTEND=noninteractive

# ---------------------------------------------------------------------------
# 1. System packages + Java + DB clients
# ---------------------------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Core tools
    curl wget unzip zip ca-certificates gnupg2 lsb-release \
    sudo nano vim less jq tree htop \
    # Git + extras
    git git-lfs \
    # Network tools (for debugging connectivity to SonarQube etc.)
    iputils-ping dnsutils netcat-openbsd telnet \
    # Java 17
    openjdk-${JAVA_VERSION}-jdk \
    # DB clients
    postgresql-client \
    default-mysql-client \
    # Build essentials (native modules)
    build-essential python3 \
    # SSH client (for git over SSH)
    openssh-client \
    && rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------------------------
# 2. Maven
# ---------------------------------------------------------------------------
RUN curl -fsSL https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz \
    | tar -xz -C /opt \
    && ln -s /opt/apache-maven-${MAVEN_VERSION} /opt/maven

ENV MAVEN_HOME=/opt/maven
ENV PATH="${MAVEN_HOME}/bin:${PATH}"

# ---------------------------------------------------------------------------
# 3. GitHub CLI
# ---------------------------------------------------------------------------
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update && apt-get install -y gh \
    && rm -rf /var/lib/apt/lists/* \
    && mv /usr/bin/gh /usr/bin/gh-real

# gh wrapper - blocks destructive commands (repo delete, archive, rename...)
COPY gh-wrapper.sh /usr/bin/gh
RUN chmod +x /usr/bin/gh

# ---------------------------------------------------------------------------
# 4. Node.js global tools: TypeScript, Angular CLI, common utilities
# ---------------------------------------------------------------------------
RUN npm install -g \
    typescript \
    ts-node \
    @angular/cli@${ANGULAR_CLI_VERSION} \
    eslint \
    prettier \
    npm-check-updates

# ---------------------------------------------------------------------------
# 5. Claude Code
# ---------------------------------------------------------------------------
RUN npm install -g @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}

# ---------------------------------------------------------------------------
# 6. User setup - use existing 'node' user (UID 1000 in node:20 image)
# ---------------------------------------------------------------------------
RUN echo "node ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/node

# Java & Maven env
ENV JAVA_HOME=/usr/lib/jvm/java-${JAVA_VERSION}-openjdk-amd64
ENV PATH="${JAVA_HOME}/bin:${PATH}"

# ---------------------------------------------------------------------------
# 7. Workspace + volumes
# ---------------------------------------------------------------------------
RUN mkdir -p /workspace /home/node/.claude /home/node/.ssh /home/node/.m2 /home/node/.npm \
    && chown -R node:node /workspace /home/node

WORKDIR /workspace
USER node

# ---------------------------------------------------------------------------
# 8. Git config defaults (user can override via volume mount)
# ---------------------------------------------------------------------------
RUN git config --global init.defaultBranch main \
    && git config --global pull.rebase false \
    && git config --global core.autocrlf input

# ---------------------------------------------------------------------------
# 9. Built-in skills, hooks, settings (stored in /opt/claude - outside home volume)
# ---------------------------------------------------------------------------
COPY --chown=node:node CLAUDE.md /opt/claude/CLAUDE.md
COPY --chown=node:node skills/ /opt/claude/skills/
COPY --chown=node:node hooks/ /opt/claude/hooks/
RUN chmod +x /opt/claude/hooks/*.sh
COPY --chown=node:node settings.json /opt/claude/settings.json

# ---------------------------------------------------------------------------
# 10. Entrypoint
# ---------------------------------------------------------------------------
COPY --chown=node:node entrypoint.sh /opt/claude/entrypoint.sh
RUN chmod +x /opt/claude/entrypoint.sh

ENTRYPOINT ["/opt/claude/entrypoint.sh"]
CMD ["claude", "--dangerously-skip-permissions"]
