#!/bin/bash
#create temp folder and set cleanup
tmp="$(mktemp -d -t autoinstallXXXXX)"
cd "$tmp" || exit 4
#cleanup
cleanup() {
	rm -rf "$tmp" 
	}
trap cleanup EXIT
##VARS
#bundle variables
BASEDNF="sudo dnf install -y chromium libreoffice-fresh pinta wine wine-gecko wine-mono freetype2"
BASEFLAT="flatpak install -y --noninteractive --or-update com.github.IsmaelMartinez.teams_for_linux"
GAMEDNF="sudo dnf install -y freetype2 steam lutris mangohud gamescope goverlay"
GAMEFLAT="flatpak install -y --noninteractive --or-update org.prismlauncher.PrismLauncher com.heroicgameslauncher.hgl com.obsproject.Studio io.github.unknownskl.greenlight com.discordapp.Discord com.valvesoftware.Steam.Utility.MangoHud"
##FUNCTIONS
#get language from OS
get_lang() {
      local lang="${LANG:0:2}"
      local available=("pt" "en")

      if [[ " ${available[*]} " == *"$lang"* ]]; then
          ulang="$lang"
      else
          ulang="en"
      fi
    }
languages() {
    if [ "$ulang" == "pt" ]; then
        intro () { 
            echo "Este é o script *Psygreg AutoInstall*."
            echo "Ele atualiza completamente o sistema, instala todos os aplicativos, drivers e dependências necessárias para seu sistema Linux baseado em Arch."
            echo "Se todos os programas já tiverem sido instalados, ele só irá fazer uma atualização completa do sistema e criará um ponto de restauração quando finalizar."             
            }
        bundleopt="Qual pacote deseja instalar?"
        cancel="Operação cancelada."
        success="Script Psygreg AutoInstall concluiu com sucesso. Reinicie para aplicar as alterações."
        restorefail="Não foi possível criar um snapshot do sistema. Abortando..."
        #radeoncheck="Patch Radeon-Vulkan já aplicado ou não é necessário, pulando..."
        noroot="Não execute o AutoInstall como root."
        fedora="Iniciando..."
        nofedora="Esta não é uma distro com pacotes RPM. Esta é uma distribuição Linux baseada em Fedora?"
        nonvidia="GPU Nvidia não detectada. Pulando..."
    else
        intro () { 
            echo "This is the *Psygreg AutoInstall Script*."
            echo "It will perform a complete system update, and install required dependencies, drivers and applications to your Arch-based Linux system."
            echo "If all programs are already installed, it will just perform the system update and create a system restore point through Timeshift."            
            }
        bundleopt="Which bundle do you wish to install?"
        cancel="Operation cancelled."
        success="Script Psygreg AutoInstall has finished successfully. Reboot to apply all changes."
        restorefail="Failed to create a system snapshot. Aborting..."
        #radeoncheck="Radeon Vulkan fix already applied or unnecessary, skipping..."
        noroot="Do not run AutoInstall as root."
        fedora="Starting..."
        nofedora="This is not a RPM package distro. Is this a Fedora-based distro?"
        nonvidia="No Nvidia GPU detected. Skipping..."
    fi
}
#bundle picker
choose_bundle() {
	echo "1) Basic"
	echo "2) Gamer"
	echo "3) Cancel"
	read -p "(1, 2 or 3): " bundle
}
#restore point failsafe
restore() {
    sudo dnf install -y btrfs-assistant
    sudo snapper -c default create-config /
    snapper -c default create --description "Autoinstall recovery" || echo "$restorefail" && exit 3
}
#nvidia gpu install
nvcheck() {
	GPU=$(lspci | grep -i '.* vga .* nvidia .*')
	shopt -s nocasematch
	if [[ $GPU == *' nvidia '* ]]; then
		sudo dnf install -y akmod-nvidia xorg-x11-drv-nvidia-cuda xorg-x11-drv-nvidia-power xorg-x11-drv-nvidia-cuda-libs
	else
		echo "$nonvidia"
	fi
}
##radeon vulkan patch - being rewritten for Fedora
#radeon_vlk() {
    #if pacman -Qs amdvlk > /dev/null; then
        #sudo dnf remove -y amdvlk lib32-amdvlk
        #sudo dnf install -y vulkan-radeon lib32-vulkan-radeon
    #else
        #echo "$radeoncheck"
    #fi
#}
##SCRIPT RUN START
#get language
get_lang
languages
#root checker
if (( ! UID )); then
	echo "$noroot"
	exit 1
else
#check if OS is fedora-based
    if command -v dnf &> /dev/null; then
        echo "$fedora"
    else
        echo "$nofedora"
        exit 2
    fi
    intro
    ##BUNDLE INSTALL
    echo "$bundleopt"
    choose_bundle
    if [ "$bundle" == "1" ]; then
        restore
        nvcheck
        #radeon_vlk
        eval "$BASEDNF"
        eval "$BASEFLAT"
    elif [ "$bundle" == "2" ]; then
        restore
        nvcheck
        #radeon_vlk
	    eval "$GAMEDNF"
        eval "$GAMEFLAT"
    else
        echo "$cancel"
        exit 0
    fi
    echo "$success"
    exit 0
fi
