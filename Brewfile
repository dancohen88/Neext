# Neext toolchain. Install or update everything with: brew bundle
# Check what's missing without installing:          brew bundle check --verbose

# Containers and Kubernetes
cask "docker-desktop"   # container runtime; k3d runs inside it
brew "k3d"              # k3s clusters in Docker (dev cluster)
brew "kubernetes-cli"   # kubectl
brew "helm"             # Kubernetes package manager
brew "tilt"             # edit-and-redeploy loop for neext-local

# Java. Pinned to the current LTS. The plain "temurin" cask tracks the newest release.
# Maven pulls in Homebrew's own openjdk; JAVA_HOME (see README) makes it use Temurin 25.
cask "temurin@25"
brew "maven"

# Load testing
brew "k6"

# Checks (same versions CI pins in .github/workflows/ci.yml). Run with: make lint
brew "yamllint"         # YAML formatting
brew "kubeconform"      # Kubernetes manifests against the API schema
