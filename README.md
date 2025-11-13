# SAE51

**Auteurs :** Antoine Canu
**Date :** Années 2025-2026  

## Contexte
...

Toutes les commandes doivent être effectuées depuis le dossier `sae51-lecoq` quand celle-ci sont à effectuer sur la machine hôte.

---

# Installation du client Ansible 

    Exécuter les commandes suivantes si vous êtes sur une machine **Ubuntu** :
    ```bash
    sudo apt update 
    sudo apt install -yqq git software-properties-common tree 
    sudo apt-add-repository --yes --update ppa:ansible/ansible 
    sudo apt install -yqq ansible
    ```
    Exécuter les commandes suivantes si vous êtes sur une machine **Debian** :
    ```bash
    sudo apt update
    sudo apt install software-properties-common
    sudo add-apt-repository --yes "deb http://ppa.launchpad.net/ansible/ansible/ubuntu focal main"
    sudo apt update
    sudo apt install ansible -y
    ```

    Continuez par installer whois et créer l'utilisateur ansible (pensez à modifier le mdp) :
    ```bash
    sudo apt install whois -y
    sudo useradd -m -s /bin/bash -p $(mkpasswd -m sha-512 <mdp>) ansible
    ```

    Ouvrez le privilège sudo :
    ```bash
    sudo visudo
    ```   

    Ajouter la ligne :
    ```bash
    ansible ALL=(ALL:ALL) NOPASSWD: ALL
    ```    

    Vous pouvez vérifier le bon fonctionnement avec la commande qui suit, aucun mot de passe ne doit vous être demande pour la seconde :
    ```bash
    su - ansible
    sudo whoami
    ```    


# Procédure d'installation

1. **Installation de la VM**

   Pour créer une nouvelle VM, exécuter la commande suivante :
   ```bash
   ./servOps/genVM.sh N <nom_vm> <user> <pwd>
    ```
    
2. **Initialisation de la VM**
    
    Partie Client

    Pour initialiser une VM (après installation) :
   ```bash
   ./servOps/genVM.sh I <nom_vm> <user> <pwd>
    ```
    Ajouter la nouvelle machine dans le fichier :
        servWeb/servWeb-ansible/inventories/hosts
    PS : Vous pouvez vous baser sur le fichier hosts-example.txt présents dans le même répertoire

    Vérifier si le dossier et une clé ssh nommé id_rsa_sae51 existent :
    ```bash
    ls -l ~/.ssh/   
    ```

    Si le dossier ou autre n'existe pas, alors les ajouter : 
    ```bash
    sudo ssh-keygen -f ~/.ssh/keys-ansible_rsa
    sudo chmod 600 /home/antoine/.ssh/keys-ansible_rsa
    sudo chown antoine:antoine /home/antoine/.ssh/keys-ansible_rsa
    ```

    Partie VM

    Continuez par installer whois et créer l'utilisateur ansible (mettre le même mdp que pour le client) :
    ```bash
    sudo apt install whois -y
    sudo useradd -m -s /bin/bash -p $(mkpasswd -m sha-512 <mdp>) ansible
    ```

    Ouvrez le privilège sudo :
    ```bash
    sudo visudo
    ```   

    Ajouter la ligne :
    ```bash
    ansible ALL=(ALL:ALL) NOPASSWD: ALL
    ```    

    Vous pouvez vérifier le bon fonctionnement avec la commande qui suit, aucun mot de passe ne doit vous être demande pour la seconde :
    ```bash
    su - ansible
    sudo whoami
    ```    

    Copy la clé ssh de la machine ansible vers la vm
    ```bash
    sudo ssh-copy-id -i ~/.ssh/keys-ansible_rsa.pub ansible@<ip-vm>
    ```

## Procédure pour le(s) Serveur(s) Web

    ```bash
    ansible-playbook -i servWeb/servWeb-ansible/inventories/hosts servWeb/servWeb-ansible/site.yml
    ```

## Procédure pour les serveurs d'Hébergement

    <!-- sudo usermod -aG docker <your_user> -->


    ```bash
    ansible-playbook -i servHebergement/servHebergement-ansible/inventory/hosts.ini servHebergement/servHebergement-ansible/playbooks/check_and_provision.yml -e service_type=minecraft -e service_user=testuser -e service_request_id=req001 --ask-become-pass
    ```

## Tester le programme

Après avoir tout initialisé on peut se connecter en tant qu'utilisateur lambda à l'adresse : 
    http://<addresse_ip_server_web>:8500/index.php