#!/bin/bash

# variables
EF_PORTAL_SCRIPT_URL="https://raw.githubusercontent.com/NISP-GmbH/EF-Portal-Installer/refs/heads/main/ef-portal-installer.sh"
EF_PORTAL_SCRIPT_NAME=$(basename $EF_PORTAL_SCRIPT_URL)
EF_PORTAL_PORT="8448"
EF_PORTAL_EFADMIN_USER="efadmin"
EF_PORTAL_EFADMIN_PASSWORD=$(echo "efadmin@#@$(printf '%04d' $((RANDOM % 10000)))")
DCV_INSTALLER_URL="https://raw.githubusercontent.com/NISP-GmbH/DCV-Installer/refs/heads/main/DCV_Installer.sh"
DCV_INSTALLER_NAME=$(basename $DCV_INSTALLER_URL)
DCV_SERVER_PORT="8443"
SLURM_SCRIPT_URL="https://raw.githubusercontent.com/NISP-GmbH/SLURM/main/slurm_install.sh"
SLURM_SCRIPT_NAME=$(basename $SLURM_SCRIPT_URL)
JAVA_FILE_URL="https://www.ni-sp.com/wp-content/uploads/2019/10/jdk-11.0.19_linux-x64_bin.tar.gz"
JAVA_FILE_NAME=$(basename $JAVA_FILE_URL)
RED='\033[0;31m'; GREEN='\033[0;32m'; GREY='\033[0;37m'; BLUE='\034[0;37m'; NC='\033[0m'
ORANGE='\033[0;33m'; BLUE='\033[0;34m'; WHITE='\033[0;97m'; UNLIN='\033[0;4m'

if [[ "${SLURM_VERSION}x" == "x" ]]
then
    export SLURM_VERSION="24.05.2"    
fi

# Setup environment
prepareEnvironment()
{
    cat <<EOF >> ~/.bashrc 
alias p=pushd
alias l="ls -ltr"
alias x="emacs -nw "
alias ex=exit
alias les=less
alias j=jobs
alias m=less
EOF
    source ~/.bashrc

    if cat /etc/os-release | egrep -iq "(ubuntu|debian)"
    then
        sudo apt update -y
        sudo apt install unzip tar -y
    else
        sudo yum install emacs-nox unzip tar -y
    fi
}

# Download and install EF Portal
setupEfportal()
{
    wget --quiet --no-check-certificate $EF_PORTAL_SCRIPT_URL
    [ $? -ne 0 ] && echo "Failed to download >>> ${EF_PORTAL_SCRIPT_NAME} <<<. Exiting..." && exit 1

    sudo bash ${EF_PORTAL_SCRIPT_NAME} --slurm_support=true --license_file=./license.ef --https_port=${EF_PORTAL_PORT}
    [ $? -ne 0 ] && echo "Failed to setup EF Portal. Exiting..." && exit 7

    sudo firewall-cmd --zone=public --add-port=${EF_PORTAL_PORT}/tcp --permanent

    echo -e "${EF_PORTAL_EFADMIN_PASSWORD}\n${EF_PORTAL_EFADMIN_PASSWORD}" | sudo passwd ${EF_PORTAL_EFADMIN_USER}
    rm -f ${EF_PORTAL_SCRIPT_NAME}
}

# Download and install SLURM
setupSlurm()
{
    wget --quiet --no-check-certificate $SLURM_SCRIPT_URL
    [ $? -ne 0 ] && echo "Failed to download >>> ${SLURM_SCRIPT_NAME} <<<. Exiting..." && exit 5

    sudo SLURM_VERSION=${SLURM_VERSION} bash $SLURM_SCRIPT_NAME --without-interaction=true --slurm-accounting-support=false
    [ $? -ne 0 ] && echo "Failed to setup SLURM. Exiting..." && exit 8
    rm -f $SLURM_SCRIPT_NAME
}

# Download and install DCV
setupDcv()
{
    wget --quiet --no-check-certificate $DCV_INSTALLER_URL
    [ $? -ne 0 ] && echo "Failed to download >>> ${DCV_INSTALLER_NAME} <<<. Exiting..." && exit 6

    sudo bash $DCV_INSTALLER_NAME --without-interaction --dcv_server_install=true
    [ $? -ne 0 ] && echo "Failed to setup DCV Server. Exiting..." && exit 9

    rm -f $DCV_INSTALLER_NAME
}

finishMessage()
{
    echo
    echo
    echo
    echo
    echo
    echo -e "${GREEN}Finished the setup with SUCCESS!${NC}"
    echo -e "${GREEN}To access EF portal: https://your_ip:${EF_PORTAL_PORT}${NC}"
    echo -e "${GREEN}User:${NC} ${EF_PORTAL_EFADMIN_USER}"
    echo -e "${GREEN}Password:${NC} ${EF_PORTAL_EFADMIN_PASSWORD}"
    echo -e "${GREEN}To access DCV Server (TCP and UDP):${NC} your_ip:${DCV_SERVER_PORT}"
    echo -e "${GREEN}SLURM is available. You can test: srun hostname, sinfo${NC}"
}

# main
main()
{
    prepareEnvironment
    setupEfportal
    setupSlurm
    setupDcv
    finishMessage
    exit 0
}

main

# unknown error
echo "Unknown error. Exiting..."
exit 255
