#!/bin/bash

#Vbox installation check
if ! command -v vboxmanage > /dev/null 2>&1; then 
    echo "Erreur : VBoxManage n'est pas installé ou est introuvable"
    exit 1
fi

#Variables
RAM=4096
DD=8000
CPU=1
VRAM=32

#Arguments
action="$1"
vm_name="$2"

#Variables types check
for var in RAM DD CPU VRAM; do
    value=${!var}
    if ! [[ $value =~ ^[0-9]+$ ]]; then
        echo "Erreur : $var doit être un entier (valeur actuelle: '$value')"
        exit 1
    fi
done

#Functions
create_vm() {
    local action="$1"
    local vm_name="$2"
    local user_vm="$3"
    local pass_vm="$4"

    echo "La machine '$vm_name' en cours de création..."
    vboxmanage createvm --name "$vm_name" \
        --ostype "Debian_64" \
        --register > /dev/null 2>&1 || {
            echo "Attention : la machine '$vm_name' existe déjà ou une erreur est survenue."
            exit 1
        }

    iso_path="$HOME/debian-12.12.0-amd64-netinst.iso"
    iso_url="https://cdimage.debian.org/cdimage/archive/12.12.0/amd64/iso-cd/debian-12.12.0-amd64-netinst.iso"

    if [ -f "$iso_path" ]; then
        echo "ISO déjà présente : $iso_path"
    else
        echo "⬇ Téléchargement de Debian 12.12.0..."
        wget -q --show-progress "$iso_url" -O "$iso_path" || {
            echo "Erreur : impossible de télécharger l'ISO"
            exit 1
        }
        echo "Téléchargement terminé : $iso_path"
    fi

    vboxmanage modifyvm "$vm_name" \
        --memory $RAM --cpus $CPU \
        --nic1 nat --nic2 none \
        --boot1 disk --boot2 none --boot3 none --boot4 none \
        --vram $VRAM --graphicscontroller vmsvga \
        || { echo "Erreur : Impossible de modifier la VM"; exit 1; }

    vboxmanage createmedium --filename "/home/$USER/VirtualBox VMs/$vm_name/$vm_name.vdi" \
        --size $DD --variant Standard > /dev/null 2>&1 \
        || { echo "Erreur : Impossible de créer le disque"; exit 1; }

    vboxmanage storagectl "$vm_name" --name "SATA Controller" --add sata \
        --controller IntelAhci > /dev/null 2>&1 \
        || { echo "Erreur : Impossible de créer le contrôleur SATA"; exit 1; }

    vboxmanage storageattach "$vm_name" --storagectl "SATA Controller" \
        --port 0 --device 0 --type hdd \
        --medium "/home/$USER/VirtualBox VMs/$vm_name/$vm_name.vdi" \
        > /dev/null 2>&1 \
        || { echo "Erreur : Impossible d'attacher le disque"; exit 1; }

    vboxmanage setextradata "$vm_name" "CreationDate" "$(TZ=Europe/Paris date +"%Y-%m-%d %H:%M:%S")"
    vboxmanage setextradata "$vm_name" "CreatedBy" "$USER"

    vboxmanage unattended install "$vm_name" \
        --iso="$iso_path" \
        --user="$user_vm" \
        --password="$pass_vm" \
        --full-user-name="$user_vm" \
        --hostname="$vm_name.local" \
        --install-additions \
        --start-vm=gui \
        --package-selection-adjustment minimal \
        > /dev/null 2>&1 || { echo "Erreur : Installation automatisée échouée"; exit 1; }

    echo "VM créée avec succès"
    exit 0
}

init_network() {
    local action="$1"
    local vm_name="$2"
    local user_vm="$3"
    local pass_vm="$4"

    wait_vmUp "$vm_name" "$user_vm" "$pass_vm"

    #Ajout des droits sudo à l'utilisateur et installer les paquets nécessaires
    read -p "Se connecter à la machine virtuelle"
    read -p "Ouvrir un terminal et se mettre en mode root (commande : su)"
    echo "Installer les paquests nécessaires"
    read -p "   apt update" 
    read -p "   apt install -y sudo openssh-server netplan.io vim"
    read -p "Ajouter les droits sudo à l'utilisateur : sudo usermod -aG sudo $user_vm"    

    if vboxmanage list runningvms | grep -q "\"$vm_name\""; then
        echo "Arrêt de la VM..."
        vboxmanage controlvm "$vm_name" poweroff > /dev/null 2>&1
        sleep 10
    fi

    echo "Configuration interface host-only..."
    vboxmanage modifyvm "$vm_name" --nic2 hostonly --hostonlyadapter2 vboxnet0 \
        || { echo "Erreur : Impossible de modifier NIC2"; exit 1; }

    vboxmanage startvm "$vm_name" --type gui > /dev/null 2>&1 || {
        echo "Erreur : Impossible de démarrer la VM"
        exit 1
    }

    echo "$vm_name démarrée"
    wait_vmUp "$vm_name" "$user_vm" "$pass_vm"

    #Procédure à Suivre
    echo "Reconnectez vous"
    
    read -p "Créer le fichier /etc/netplan/01-netcfg.yaml et y copier network-init.txt"
    echo "Saisir les commande :"
    read -p "   sudo chmod 600 /etc/netplan/01-netcfg.yaml"
    read -p "   sudo netplan generate"
    read -p "   sudo netplan apply #si une erreur apparaît pas d'inquiétude"

    read -p "Récupérer l'adresse IP en 192.168.56.x avec : ip addr show"
    read -p "Si vous n'avez pas d'adresse IP, alors faites : sudo reboot"

    read -p "Modifier le fichier /etc/netplan/01-netcfg.yaml et y copier network.txt en modifiant <ip> par la bonne adresse IP"
    echo "Saisir les commande :"
    read -p "   sudo netplan generate"
    read -p "   sudo netplan apply #si une erreur apparaît pas d'inquiétude"
    read -p "   sudo ssh-keygen -A"
    read -p "   sudo systemctl restart ssh"
    read -p "   sudo systemctl status ssh"

    echo "Vérifier les informations suivantes :"
    read -p "   Connexion internet : ping 8.8.8.8"
    read -p "   Passerelle correcte (@NAT et pas @Reseau_interne) : ip route | grep default"
    read -p "   Serveurs DNS : cat /etc/resolv.conf"
    read -p "   Ping passerelle : ping 192.168.56.1"

    echo "Vous pouvez maintenant utiliser la vm"
    exit 0
}

start_vm() {
    vboxmanage startvm "$vm_name" --type gui > /dev/null 2>&1 || {
        echo "Erreur : Impossible de démarrer la VM"
        exit 1
    }
    echo "VM démarrée"
    exit 0
}

stop_vm() {
    echo "Arrêt de la VM..."
    vboxmanage controlvm "$vm_name" poweroff > /dev/null 2>&1 || {
        echo "Erreur : Impossible d'arrêter la VM"
        exit 1
    }
    echo "VM arrêtée"
    exit 0
}

delete_vm() {

    if vboxmanage list vms | grep -q "\"$vm_name\""; then
        if vboxmanage list runningvms | grep -q "\"$vm_name\""; then
            echo "Arrêt de la VM..."
            vboxmanage controlvm "$vm_name" poweroff > /dev/null 2>&1
            sleep 10
        fi

        echo "Suppression de la VM..."
        vboxmanage unregistervm "$vm_name" --delete > /dev/null 2>&1 || {
            echo "Erreur : Impossible de supprimer la VM"
            exit 1
        }
    fi

    vm_files=$(find ~/VirtualBox\ VMs/ -name "*$vm_name*" 2>/dev/null)
    [ -n "$vm_files" ] && rm -rf "$vm_files"

    echo "VM supprimée"
    exit 0
}

list_vms() {
    temp_file=$(mktemp)
    vboxmanage list vms > "$temp_file"

    echo -e "Liste des VMs :\n"

    while read -r line; do
        vm=$(echo "$line" | cut -d '"' -f2)
        date_creation=$(vboxmanage getextradata "$vm" "CreationDate" | cut -d' ' -f2-)
        created_by=$(vboxmanage getextradata "$vm" "CreatedBy" | cut -d' ' -f2-)

        echo "VM : $vm"
        echo "  Créée le : ${date_creation:-Unknown}"
        echo "  Par      : ${created_by:-Unknown}"
        echo
    done < "$temp_file"

    rm "$temp_file"
    exit 0
}

wait_vmUp() {
    local vm_name="$1"
    local user_vm="$2"
    local pass_vm="$3"

    echo "Attente que la VM soit totalement active..."

    while true; do
        GA_STATUS=$(vboxmanage guestproperty get "$vm_name" "/VirtualBox/GuestAdd/Version" 2>/dev/null | awk '{print $2}')

        if [ -n "$GA_STATUS" ]; then
            vboxmanage guestcontrol "$vm_name" run \
                --username "$user_vm" \
                --password "$pass_vm" \
                --exe "/bin/true" >/dev/null 2>&1

            if [ $? -eq 0 ]; then
                echo "VM prête !"
                break
            fi
        fi

        sleep 5
    done
}

#Action check
valid_action="N D A S L I"

if ! [[ " $valid_action " =~ " $action " ]]; then
    echo "Erreur : Action invalide '$action'"
    echo "Actions possibles : N (Nouvelle VM), D (Démarrer), A (Arrêter), S (Supprimer), L (Lister), I (Initialiser réseau)"
    exit 1
fi

#Using the functions
case "$action" in

    N) [ $# -eq 4 ] || { echo "Usage : N <vm> <user> <pass>"; exit 1; }
        create_vm "$@"
        ;;

    I) [ $# -eq 4 ] || { echo "Usage : I <vm> <user> <pass>"; exit 1; }
    init_network "$@"
    ;;

    D) [ $# -eq 2 ] || { echo "Usage : D <vm>"; exit 1; }
       start_vm
       ;;

    A) [ $# -eq 2 ] || { echo "Usage : A <vm>"; exit 1; }
       stop_vm
       ;;

    S) [ $# -eq 2 ] || { echo "Usage : S <vm>"; exit 1; }
       delete_vm
       ;;

    L) list_vms ;;
    *) echo "Action inconnue" ; exit 1 ;;
esac