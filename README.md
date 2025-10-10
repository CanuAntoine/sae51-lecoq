# SAE51

**Auteurs :** Antoine Canu
**Date :** Années 2025-2026  

## Contexte
...

Toutes les commandes doivent être effectuées depuis le dossier `sae51-lecoq`.

---

## Tester le programme

Après avoir tout initialisé on peut se connecter en tant qu'utilisateur lambda à l'adresse : 
    http://<addresse_ip_server_web>:8500/index.php

## Procédure pour le(s) Serveur(s) Web

1. **Installation de la VM**

   Pour créer une nouvelle VM, exécuter la commande suivante :
   ```bash
   ./servOps/genVM.sh N <nom_vm> <path/to/debian.iso> <user> <pwd>
    ```
    
2. **Initialisation de la VM**

    Pour initialiser une VM (après installation) :
   ```bash
   ./servOps/genVM.sh I <nom_vm> <user> <pwd>
    ```
    Vérifier si une clé ssh nommé id_rsa_sae51 existe :
    ```bash
    ls -l ~/.ssh/
    ```

    Si elle n'existe pas : 
    ```bash
    ssh-keygen -t rsa -f rsa_sae51
    ```

    Copy la clé ssh de la machine ansible vers la vm
    ```bash
    ssh-copy-id -i ~/.ssh/id_rsa_sae51.pub <user>@<ip-vm>
    ```

    Ajouter la nouvelle machine dans le fichier :
        servWeb/servWeb-ansible/inventories/hosts
    PS : Vous pouvez vous baser sur le fichier hosts-example.txt présents dans le même répertoire

3.  **Executer le script ansible**
    ```bash
    ansible-playbook -i servWeb/servWeb-ansible/inventories/hosts servWeb/servWeb-ansible/site.yml --ask-become-pass
    ```