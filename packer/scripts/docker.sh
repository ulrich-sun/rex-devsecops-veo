#!/bin/bash

# Variables de configuration
VERSION_STRING="5:20.10.0~3-0~ubuntu-focal"
# ENABLE_ZSH=true

# Configuration pour éviter les prompts interactifs
export DEBIAN_FRONTEND=noninteractive
export DEBCONF_NONINTERACTIVE_SEEN=true

echo "Script Started: $(date)"

# Fonction pour gérer les erreurs
handle_error() {
    echo "Erreur à la ligne $1: $2"
    exit 1
}

# Trap pour capturer les erreurs
trap 'handle_error $LINENO "$BASH_COMMAND"' ERR

# Nettoyer les listes APT corrompues (pour éviter les erreurs APT)
echo "Nettoyage des listes APT..."
sudo rm -rf /var/lib/apt/lists/*
sudo apt-get clean

# Mise à jour du système
echo "Mise à jour du système..."
sudo apt-get update 2>/dev/null || true

# Installation des outils de base
echo "Installation des outils de base..."
sudo apt-get install -y --no-install-recommends apt-utils 2>/dev/null || true

# Chargement des modules kernel nécessaires
echo "Chargement des modules kernel..."
sudo modprobe overlay || true
sudo modprobe br_netfilter || true

# Vérification que les modules sont chargés
lsmod | grep overlay || echo "Module overlay non chargé"
lsmod | grep br_netfilter || echo "Module br_netfilter non chargé"

# Configuration des modules pour le chargement automatique
echo "Configuration des modules pour le chargement automatique..."
cat <<EOF | sudo tee /etc/modules-load.d/docker.conf
overlay
br_netfilter
EOF

# Configuration sysctl pour Docker
echo "Configuration sysctl pour Docker..."
cat <<EOF | sudo tee /etc/sysctl.d/99-docker.conf
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF

# Application des paramètres sysctl - méthode robuste
echo "Application des paramètres sysctl..."
sudo sysctl -w net.bridge.bridge-nf-call-iptables=1 2>/dev/null || echo "bridge-nf-call-iptables non disponible"
sudo sysctl -w net.bridge.bridge-nf-call-ip6tables=1 2>/dev/null || echo "bridge-nf-call-ip6tables non disponible"
sudo sysctl -w net.ipv4.ip_forward=1 2>/dev/null || echo "ip_forward non disponible"

# Rechargement de la configuration sysctl
sudo sysctl --system 2>/dev/null || true

# Mise à jour des packages et installation des dépendances
echo "Installation des dépendances..."
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg lsb-release

# Création du répertoire pour les clés GPG
echo "Configuration des clés GPG Docker..."
sudo install -m 0755 -d /etc/apt/keyrings

# Téléchargement et installation de la clé GPG Docker
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Ajout du repository Docker
echo "Ajout du repository Docker..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Mise à jour avec le nouveau repository
echo "Mise à jour avec le repository Docker..."
sudo apt-get update

# Installation de Docker avec la version spécifiée
echo "Installation de Docker version $VERSION_STRING..."
sudo apt-get install -y \
    docker-ce=$VERSION_STRING \
    docker-ce-cli=$VERSION_STRING \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

# Démarrage et activation de Docker
echo "Démarrage et activation de Docker..."
sudo systemctl start docker
sudo systemctl enable docker

# Ajout de l'utilisateur ubuntu au groupe docker
echo "Ajout de l'utilisateur ubuntu au groupe docker..."
sudo usermod -aG docker ubuntu

# Vérification de l'installation
echo "Vérification de l'installation Docker..."
sudo docker --version || echo "Erreur lors de la vérification de Docker"
sudo docker info > /dev/null 2>&1 || echo "Docker daemon non accessible"

# Configuration optionnelle de ZSH si activée
# if [ "$ENABLE_ZSH" = true ]; then
#     echo "Installation et configuration de ZSH..."
#     sudo apt-get install -y zsh
    
#     # Installation de Oh My Zsh pour l'utilisateur ubuntu
#     sudo -u ubuntu sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended || echo "Oh My Zsh installation failed"
    
#     # Changement du shell par défaut pour ubuntu
#     sudo chsh -s /bin/zsh ubuntu || echo "Failed to change shell to zsh"
# fi

# Nettoyage final
echo "Nettoyage final..."
sudo apt-get autoremove -y
sudo apt-get autoclean

echo "Script terminé avec succès: $(date)"