#!/bin/bash

# Configuration pour éviter les prompts interactifs
export DEBIAN_FRONTEND=noninteractive
export DEBCONF_NONINTERACTIVE_SEEN=true

echo "Script Started: $(date)"
# Nettoyer les listes APT corrompues
sudo rm -rf /var/lib/apt/lists/*
sudo apt-get clean

# Mettre à jour sans le système command-not-found
sudo apt-get update 2>/dev/null || true

# Désactiver temporairement command-not-found pendant l'installation
sudo apt-get install -y --no-install-recommends apt-utils 2>/dev/null || true

# Continuer avec vos installations normales
sudo apt-get install -y curl git wget unzip socat 
# init.sh - Script d'initialisation pour l'image Ubuntu 20.04 LTS

