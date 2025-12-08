# SAE51 Hébergement de sites Internet clients

**Auteurs :** Antoine Canu
**Date :** Années 2025-2026  

## Contexte
...
Nous sommes du point de vue d'une entreprise du nom de **CanuWebHost** qui propose des services d'hébergement Web pour des clients. 

Si vous souhaitez appliqués cette infrastructure, il faut savoir que toutes les commandes doivent être effectuées depuis le dossier `sae51-lecoq` quand celle-ci sont à effectuer sur la machine hôte.

Vous avez également besoin d'avoir un réseau interne VirtualBox pour que cela fonctionne.

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

Il vous faut avoir Docker d'installé, si ce n'est pas le cas alors entrer les commandes suivantes :
```bash
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io
sudo usermod -aG docker $USER
```

Continuez par installer whois et créer l'utilisateur ansible (pensez à modifier le mdp). L'utilisateur aura de nombreux droits donc pensez bien à mettre un mot de passe très sécurisé :
```bash
sudo apt install whois -y
sudo useradd -m -s /bin/bash -p $(mkpasswd -m sha-512 <mdp>) ansible
```

Ouvrez le privilège sudo :
```bash
sudo visudo
```   

Ajouter la ligne, qui permet à l'utilisateur d'utiliser sudo sans mot de passe. :
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

Une fois l'installation de la VM terminé, c'est à dire que vous pouvez vous connecter en tant qu'utilsateur. Passez à son initialisation en continuant la procédure si dessous

PS : Attention la machine est en QWERTY et non AZERTY

    
2. **Initialisation de la VM**
    
2.1. Partie Client Ansible

Vous devez intialiser la VM après installation pour qu'elle puisse est implémenté dans l'infrastructure. Pour ce faire, initialiser grâce à la commande et suivez la procédure :
```bash
./servOps/genVM.sh I <nom_vm> <user> <pwd>
```

Maintenant que la première partie de l'initialisation est terminée, vous pouvez ajouter la nouvelle machine dans le fichier : **[`hosts`](./servWeb/servWeb-ansible/inventories/hosts)**  
    
PS : Vous pouvez vous baser sur le fichier **[`hosts-examples.txt`](./servWeb/servWeb-ansible/inventories/hosts-examples.txt)** présents dans le même répertoire

Si votre machine gèrera les service d'hébergement il faut également renseigner son IP dans **[`config.env`](./servWeb/files/www/config.env)**

Pour la suite, on doit créer le lien ssh entre la nouvelle machine et le client ansible pour ce faire, vérifier si les fichiers id_rsa_sae51 existent :
```bash
ls -l ~/.ssh/   
```

Si le dossier ou autre n'existe pas, alors vérifier si ssh-server est installé :

Si ce n'est pas le cas, alors l'installer en suivant [ce lien](https://www.linuxtricks.fr/wiki/ssh-installer-et-configurer-un-serveur-ssh-openssh) selon votre distribution 

Dans tous les cas, ajouter la clé ssh en faisant :
```bash
sudo ssh-keygen -f ~/.ssh/keys-ansible_rsa
sudo chmod 600 /home/<username>/.ssh/keys-ansible_rsa
sudo chown <username>:<username> /home/<username>/.ssh/keys-ansible_rsa
```

2.2. Partie Machine Virtuelle

Comme pour la partie client Ansible, installer whois et créer l'utilisateur ansible (mettre le même mdp que pour le client) :
```bash
sudo apt install whois -y
sudo useradd -m -s /bin/bash -p "$(openssl passwd -6 <mdp>)" ansible
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

2.3. Retour sur Client Ansible

Revenir sur la machine hôte et copier la clé ssh de la machine ansible vers la vm
```bash
sudo ssh-copy-id -i ~/.ssh/keys-ansible_rsa.pub ansible@<ip-vm>
```

## Procédure pour déployer l'infrastructure gloable

Pour déployer l'infrastructure et donc ajouter la nouvelle machine, vous pouvez entrer la commande :
```bash
ansible-playbook -i inventories/hosts playbook/deploy_infra.yml
```

## Tester le programme

Après avoir tout initialisé on peut se connecter en tant qu'utilisateur lambda à l'adresse : 
    http://<addresse_ip_server_web>:8500/


## Commandes utiles 

   - **Lister toutes les VMs**  
     ```bash
     ./genMV.sh L 
     ```

   - **Créer une VM nommée "Debian1"**  
     ```bash
     ./genMV.sh N Debian1 <nom_vm> <user> <pwd>
     ```

   - **Supprimer une VM nommée "Debian1"**  
     ```bash
     ./genMV.sh S Debian1
     ```

   - **Démarrer une VM nommée "Debian1"**  
     ```bash
     ./genMV.sh D Debian1
     ```

   - **Arrêter une VM nommée "Debian1"**  
     ```bash
     ./genMV.sh A Debian1
     ```