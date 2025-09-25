#!/bin/bash

#Vérification de l'existence de VirtualBox
if ! command -v vboxmanage > /dev/null 2>&1; then 
    #L'option '-v' permet d'utiliser le mode verbose qui affiche le résultat de la commande
    echo "Erreur : VBoxManage n'est pas installé ou est introuvable"
    exit 1
fi

#Variables
RAM=4096
DD=20000
CPU=1
VRAM=256

#Vérification si les variables sont bien des integer
for var in RAM DD CPU VRAM; do
    value=${!var}
    if ! [[ $value =~ ^[0-9]+$ ]]; then
        #utilisation d'un regex pour filtrer seulement les entiers
        echo "Erreur : $var doit être un entier (valeur actuelle: '$value')"
        exit 1
    fi
done

#Récupération des arguments
action="$1"
vm_name="$2"
arg3="$3"
arg4="$4"
arg5="$5"

#Création d'une nouvelle VM
if [ "$action" == "N" ] && [ $# -eq 5 ]; then

    #Utilisation des arguments
    iso_path=$3
    user_vm=$4
    pass_vm=$5

    #Création VM
    echo "La machine '$vm_name' en cours de création..."
    vboxmanage createvm --name "$vm_name" --ostype "Debian_64" --register > /dev/null 2>&1
    if [ $? -ne 0 ]; then 
        echo "Attention : la machine '$vm_name' existe déjà ou une erreur est survenue."
        exit 1
    fi

    #Modifications caractéristiques VM
    vboxmanage modifyvm "$vm_name" \
        --memory $RAM --cpus $CPU \
        --nic1 nat --nic2 none \
        --boot1 disk --boot2 none --boot3 none --boot4 none \
        --vram $VRAM --graphicscontroller vmsvga \
        || { echo "Erreur : Impossible de modifier les caractéristique de la machine"; exit 1; }

    #Ajout du DD
    vboxmanage createhd --filename "/home/$USER/VirtualBox VMs/$vm_name/$vm_name.vdi" --size $DD --variant Standard --format VDI > /dev/null 2>&1 \
        || { echo "Erreur : Impossible de créer le Disque Dur"; exit 1; }

    #Ajout du controlleur SATA
    vboxmanage storagectl "$vm_name" --name "SATA Controller" --add sata --controller IntelAhci > /dev/null 2>&1  \
        || { echo "Erreur: Impossible de créer le contrôleur SATA"; exit 1; }
        
    #Attachement du DD
    vboxmanage storageattach "$vm_name" --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium "/home/$USER/VirtualBox VMs/$vm_name/$vm_name.vdi" > /dev/null 2>&1 \
        || { echo "Erreur : Impossible d'attacher le disque dur à la VM"; exit 1; }

    #Création métadonnées
    vboxmanage setextradata "$vm_name" "CreationDate" "$(TZ=Europe/Paris date +"%Y-%m-%d %H:%M:%S")" \
        || { echo "Erreur : Impossible d'ajouter la date de création"; exit 1; }
    vboxmanage setextradata "$vm_name" "CreatedBy" "$USER" \
        || { echo "Erreur : Impossible d'ajouter l'information de l'utilisateur"; exit 1; }

    # Installation automatisée de l'OS
    echo "Installation automatique lancée pour '$vm_name'..."
    vboxmanage unattended install "$vm_name" \
        --iso="$iso_path" \
        --user="$user_vm" \
        --password="$pass_vm" \
        --full-user-name="$user_vm" \
        --hostname="$vm_name.local" \
        --install-additions \
        --start-vm=gui \
        || { echo "Erreur : Installation automatisée échouée"; exit 1; }
    echo "VM créée avec succès et IP host-only à configurer !"
    echo "Une fois la VM redémarrer (menu de login), lancer la commande : ./genMV.sh I $vm_name $user_vm $pass_vm"
    exit 0
fi


#Initialiser le réseau + procédure à suivre
if [ "$action" == "I" ] && [ $# -eq 4 ]; then

    # Plage IP possibles
    start_ip=10
    end_ip=200
    network="192.168.56"

    # Fonction pour tester si une IP est libre
    find_free_ip() {
        for i in $(seq $start_ip $end_ip); do
            ip="$network.$i"
            if ! ping -c 1 -W 1 $ip &> /dev/null; then
                echo $ip
                return
            fi
        done
        echo ""
    }
    free_ip=$(find_free_ip)
    echo Adresse IP : "$free_ip"

    #Utilisation des arguments
    user_vm=$3
    pass_vm=$4

    #Initialisation réseau
    if vboxmanage list runningvms | grep -q "\"$vm_name\""; then 
        echo "Arrêt de la VM..."
        vboxmanage controlvm "$vm_name" poweroff > /dev/null 2>&1
        if ! [ $? == 0 ]; then 
            echo "Erreur : Impossible d'arrêter la machine"
            exit 1
        fi
        sleep 10
        echo "Machine virtuelle arrêté !"
    fi
            
    echo "Configuration de l'interface host-only..."
    vboxmanage modifyvm "$vm_name" --nic2 hostonly --hostonlyadapter2 vboxnet0 \
        || { echo "Erreur : Impossible de modifier nic2"; exit 1; }

    vboxmanage startvm "$vm_name" > /dev/null 2>&1
    echo "Démarrage de $vm_name..."
    if ! [ $? == 0 ]; then 
        echo "Erreur : Impossible de démarrer la machine"
        exit 1
    fi
    echo "$vm_name démarré !"

    #Attente Guest Additions
    echo "Attente que Guest Additions soit totalement actif..."
    while true; do
        GA_STATUS=$(vboxmanage guestproperty get "$vm_name" "/VirtualBox/GuestAdd/Version" 2>/dev/null | awk '{print $2}')
        if [ -n "$GA_STATUS" ]; then
            vboxmanage guestcontrol "$vm_name" run --username "$user_vm" --password "$pass_vm" --exe "/bin/true" >/dev/null 2>&1
            if [ $? -eq 0 ]; then
                echo "Guest Additions prêtes !"
                break
            fi
        fi
        sleep 5
    done

    #Procédure à Suivre
    read -p "Récupérer l'adresse IP écrite plus haut"
    read -p "Se connecter à la machine virtuelle avec $user_vm et $pass_vm"
    read -p "Se mettre en mode root (commande : su)"
    read -p "Copier le fichier network.txt dans /etc/network/interfaces.d/enp0s8 en modifiant <ip> par la bonne adresse IP"
    read -p "Saisir la commande : sudo systemctl restart networking.service"
    read -p "Vérifier que l'adresse IP est bien : $free_ip"

    echo "Configuration IP terminée pour $vm_name : $free_ip"
    exit 0

fi

#Vérification nombre argumenents
if [ $# -eq 2 ] || [ $# -eq 1 ]; then

    #Démarrage VM
    if [ "$action" == "D" ]; then
        vboxmanage startvm "$vm_name" --type gui > /dev/null 2>&1
        if ! [ $? == 0 ]; then 
            echo "Erreur : Impossible de démarrer la machine"
            exit 1
        fi
        echo "Machine virtuelle démarré !"
        exit 0
    fi

    #Arrêt VM
    if [ "$action" == "A" ]; then
        echo "Arrêt de la VM..."
        vboxmanage controlvm "$vm_name" poweroff > /dev/null 2>&1
        if ! [ $? == 0 ]; then 
            echo "Erreur : Impossible d'arrêter la machine"
            exit 1
        fi
        echo "Machine virtuelle arrêté !"
        exit 0
    fi

    #Suppression VM
    if [ "$action" == "S" ]; then
        if vboxmanage list vms | grep -q "\"$vm_name\""; then
            if vboxmanage list runningvms | grep -q "\"$vm_name\""; then 
                echo "Arrêt de la VM..."
                vboxmanage controlvm "$vm_name" poweroff > /dev/null 2>&1
                if ! [ $? == 0 ]; then 
                    echo "Erreur : Impossible d'arrêter la machine"
                    exit 1
                fi
                sleep 10
                echo "Machine virtuelle arrêté !"
            fi
            echo "Suppresion de la VM..."
            vboxmanage unregistervm "$vm_name" --delete > /dev/null 2>&1
            if ! [ $? == 0 ]; then 
                echo "Erreur : Impossible de supprimer la machine"
                exit 1
            fi
            echo "Machine virtuelle supprimé !"
        fi

        #Supprimer les fichiers de la VM s'il en reste des traces
        vm_files=$(find ~/VirtualBox\ VMs/ -name "*$vm_name*" 2>/dev/null)
        if [ -n "$vm_files" ]; then
            rm -rf "$vm_files"
            #L'option '-r' permet de supprimer de façon récusrive (dossier et contenu)
            #L'option '-f' force l'exécution de la commande
            echo "Suppresion des fichiers de la VM"
        fi
        exit 0
    fi

    #Lister les VMs
    if [ "$action" == "L" ]; then
        temp_file=$(mktemp)
        vboxmanage list vms > "$temp_file"

        echo -e "VMs list and metadata :\n"
        #L'option '-e' permet à la commande d'interpréter des caractères comme \n (retour à la ligne)
        while read -r line; do
        #l'option '-r' empêche la commande read d'interprêter les '\'
            vm=$(echo "$line" | cut -d '"' -f2)
            #L'option '-d' indique quel est le délimiteur de coupure, dans notre cas il s'agit de : " 
            date_creation=$(vboxmanage getextradata "$vm" "CreationDate" 2>/dev/null | cut -d' ' -f2-)
            created_by=$(vboxmanage getextradata "$vm" "CreatedBy" 2>/dev/null | cut -d' ' -f2-)
            [ -z "$date_creation" ] && date_creation="Unknow"
            [ -z "$created_by" ] && created_by="Unknow"
            #L'option '-z' vérifie si la chaine est vide
        
            if [ $# == 1 ]; then
                echo "VM: $vm"
                echo "  Creation : $date_creation"
                echo -e "  By : $created_by \n"
                #L'option '-e' permet à la commande d'interpréter des caractères comme \n (retour à la ligne)
            fi
        done < "$temp_file"
        if [ $# == 2 ]; then
            echo "VM: $vm_name"
            echo "  Creation: $date_creation"
            echo -e "   By: $created_by \n"
            #L'option '-e' permet à la commande d'interpréter des caractères comme \n (retour à la ligne)
        fi
        rm "$temp_file"
        exit 0
    fi
    
    #Erreur : Commande inconnué
    echo "Commande incorrect"
    exit 1
fi

#Erreur : Nombre arguments 
echo "Nombre d'arguments incorrect"
exit 1
