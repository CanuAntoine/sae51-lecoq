#!/bin/bash

#Vérification de l'existence de VirtualBox
if ! command -v vboxmanage > /dev/null 2>&1; then 
    #L'option '-v' permet d'utiliser le mode verbose qui affiche le résultat de la commande
    echo: "Erreur : VBoxManage n'est pas installé ou est introuvable"
    exit 1
fi

#Variables
RAM=4096
DD=65536
CPU=1
VRAM=128

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

#Vérification nombre argumenents
if [ $# -eq 2 ] || [ $# -eq 1 ]; then

    #Création d'une nouvelle VM
    if [ "$action" == "N" ]; then

        #Création VM
        vboxmanage createvm --name "$vm_name" --ostype "Debian_64" --register > /dev/null 2>&1
        if [ $? -ne 0 ]; then 
            echo "Attention : la machine '$vm_name' existe déjà ou une erreur est survenue."
            exit 1
        fi
        echo "La machine '$vm_name' en cours de création..."

        #Modifications caractéristiques VM
        vboxmanage modifyvm "$vm_name" --memory $RAM --cpus $CPU --nic1 nat --boot1 net --boot2 disk --boot3 none --boot4 none --vram $VRAM \
            || { echo "Erreur : Impossible de modifier les caractéristique de la machine"; exit 1; }

        #Ajout du DD
        vboxmanage createhd --filename "/home/$USER/VirtualBox VMs/$vm_name/$vm_name.vdi" --size $DD --format VDI > /dev/null 2>&1 \
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

        echo "Machine créé avec succès et boot initialisé !"
        exit 0
    fi

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
