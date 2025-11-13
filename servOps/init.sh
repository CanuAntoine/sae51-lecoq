#!/bin/bash

echo "=========================================="
echo "  Début du script d'initialisation"
echo "=========================================="

echo "MAJ des paquets et installation d'Ansible..."
sudo apt update > /dev/null || { echo "Problème lors de la MAJ des paquets"; exit 1; }
sudo apt install -y ansible || { echo "Problème lors de l'installation d'Ansible"; exit 1; }
echo "Ansible installé"

# Installer Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io
sudo usermod -aG docker $USER

echo "Docker installé et utilisateur ajouté au groupe docker"
