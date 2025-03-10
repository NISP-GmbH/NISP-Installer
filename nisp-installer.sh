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
DCV_SERVER_CONFIG_FILE="/etc/dcv/dcv.conf"
DCV_GPU_NVIDIA_SUPPORT="false"
DCV_GPU_AMD_SUPPORT="false"
SLURM_SCRIPT_URL="https://raw.githubusercontent.com/NISP-GmbH/SLURM/main/slurm_install.sh"
SLURM_SCRIPT_NAME=$(basename $SLURM_SCRIPT_URL)
JAVA_FILE_URL="https://www.ni-sp.com/wp-content/uploads/2019/10/jdk-11.0.19_linux-x64_bin.tar.gz"
JAVA_FILE_NAME=$(basename $JAVA_FILE_URL)
RED='\033[0;31m'; GREEN='\033[0;32m'; GREY='\033[0;37m'; BLUE='\034[0;37m'; NC='\033[0m'
ORANGE='\033[0;33m'; BLUE='\033[0;34m'; WHITE='\033[0;97m'; UNLIN='\033[0;4m'
ENABLE_SLURM="false"
ENABLE_DCV="false"
ENABLE_EFP="false"
NISP_INSTALLER_VERBOSE="true"

if [[ "${SLURM_VERSION}x" == "x" ]]
then
    export SLURM_VERSION="24.05.2"
fi

checkParameters()
{
    for arg in "$@"
    do
        case $arg in
            -h|--help|-help|help)
                echo -e "${GREEN}Usage: nisp-installer.sh [options]${NC}"
                echo -e "${GREEN}Options:${NC}"
                echo -e "${GREEN}--enable-slurm=true :${NC} if true, SLURM will be installed"
                echo -e "${GREEN}--enable-dcv=true :${NC} if true, DCV Server will be installed"
                echo -e "${GREEN}--enable-efp=true :${NC} if true, EF Portal will be installed"
                echo -e "${GREEN}--enable-dcv-gpu-nvidia=true :${NC} if true, DCV Server with NVIDIA GPU support will be installed"
                echo -e "${GREEN}--enable-dcv-gpu-amd=true :${NC} if true, DCV Server with AMD GPU support will be installed"
                echo -e "${GREEN}Note :${NC} If you do not explicit to enable some parameter, the default value is false"
                echo -e "${GREEN}-h, --help:${NC} Display this help message"
                exit 0
            ;;
        esac
    done

    for arg in "$@"
    do
        case $arg in
            --enable-slurm=true)
                ENABLE_SLURM="true"
                shift
                ;;
            --enable-dcv=true)
                ENABLE_DCV="true"
                shift
                ;;
            --enable-efp=true)
                ENABLE_EFP="true"
                shift
                ;;
            --enable-dcv-gpu-nvidia=true)
                DCV_GPU_NVIDIA_SUPPORT="true"
                shift
                ;;
            --enable-dcv-gpu-amd=true)
                DCV_GPU_AMD_SUPPORT="true"
                shift
                ;;
            --silent)
                NISP_INSTALLER_VERBOSE="false"
                shift
                ;;
        esac
    done

    if $DCV_GPU_NVIDIA_SUPPORT && $DCV_GPU_AMD_SUPPORT
    then
        $NISP_INSTALLER_VERBOSE && echo -e "${GREEN}Is not possible to support NVIDIA and AMD GPUs at the same time. Exitting.${NC}"
        exit 12
    fi

    if ! $ENABLE_SLURM && ! $ENABLE_DCV && ! $ENABLE_EFP
    then
        $NISP_INSTALLER_VERBOSE && echo -e "${GREEN}Nothing will be installed. You need to enable some service. Please execute bash nisp-installer.sh -h${NC}"
        exit 15
    fi
}

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
    if ! $ENABLE_EFP
    then
        return
    fi
    wget --quiet --no-check-certificate $EF_PORTAL_SCRIPT_URL
    [ $? -ne 0 ] && echo "Failed to download >>> ${EF_PORTAL_SCRIPT_NAME} <<<. Exiting..." && exit 1

    if 
    sudo EF_PORTAL_CONFIG_NAME=$EF_PORTAL_CONFIG_NAME EF_PORTAL_JAR_NAME=$EF_PORTAL_JAR_NAME bash ${EF_PORTAL_SCRIPT_NAME} --slurm_support=true --license_file=./license.ef --https_port=${EF_PORTAL_PORT}
    [ $? -ne 0 ] && echo "Failed to setup EF Portal. Exiting..." && exit 7

    sudo firewall-cmd --zone=public --add-port=${EF_PORTAL_PORT}/tcp --permanent

    $NISP_INSTALLER_VERBOSE && echo -e "${EF_PORTAL_EFADMIN_PASSWORD}\n${EF_PORTAL_EFADMIN_PASSWORD}" | sudo passwd ${EF_PORTAL_EFADMIN_USER}
    rm -f ${EF_PORTAL_SCRIPT_NAME}
}

# Download and install SLURM
setupSlurm()
{
    if ! $ENABLE_SLURM
    then
        return
    fi

    wget --quiet --no-check-certificate $SLURM_SCRIPT_URL
    [ $? -ne 0 ] && echo "Failed to download >>> ${SLURM_SCRIPT_NAME} <<<. Exiting..." && exit 5

    sudo SLURM_VERSION=${SLURM_VERSION} bash $SLURM_SCRIPT_NAME --without-interaction=true --slurm-accounting-support=false
    [ $? -ne 0 ] && echo "Failed to setup SLURM. Exiting..." && exit 8
    rm -f $SLURM_SCRIPT_NAME
}

# Download and install DCV
setupDcv()
{
    if ! $ENABLE_DCV
    then
        return
    fi

    wget --quiet --no-check-certificate $DCV_INSTALLER_URL
    [ $? -ne 0 ] && echo "Failed to download >>> ${DCV_INSTALLER_NAME} <<<. Exiting..." && exit 6

    if $DCV_GPU_NVIDIA_SUPPORT
    then
        sudo bash $DCV_INSTALLER_NAME --without-interaction --dcv_server_install=true --dcv_server_gpu_nvidia=true
        [ $? -ne 0 ] && echo "Failed to setup DCV Server. Exiting..." && exit 10
    elif $DCV_GPU_AMD_SUPPORT
    then
        sudo bash $DCV_INSTALLER_NAME --without-interaction --dcv_server_install=true --dcv_server_gpu_amd=true
        [ $? -ne 0 ] && echo "Failed to setup DCV Server. Exiting..." && exit 11
    else
        sudo bash $DCV_INSTALLER_NAME --without-interaction --dcv_server_install=true
        [ $? -ne 0 ] && echo "Failed to setup DCV Server. Exiting..." && exit 9
    fi

    rm -f $DCV_INSTALLER_NAME

    if [ -f $DCV_SERVER_CONFIG_FILE ]
    then
        NEW_LINE='auth-token-verifier="http://127.0.0.1:8444"'

        if grep -q '^auth-token-verifier' "$DCV_SERVER_CONFIG_FILE"
        then
            sed -i 's@^auth-token-verifier.*@'"$NEW_LINE"'@' "$DCV_SERVER_CONFIG_FILE"
        else
            if grep -q '^\[security\]' "$DCV_SERVER_CONFIG_FILE"
            then
                sed -i '/^\[security\]/a '"$NEW_LINE" "$DCV_SERVER_CONFIG_FILE"
            fi
        fi
    fi

    sudo systemctl enable --now dcvsimpleextauth.service
    sudo systemctl restart dcvsimpleextauth.service
}

finishMessage()
{
    ! $NISP_INSTALLER_VERBOSE && return

    echo
    echo
    echo
    echo
    echo
    echo -e "${GREEN}Finished the setup with SUCCESS!${NC}"
    if $ENABLE_EFP
    then
        echo -e "${GREEN}To access EF portal: https://your_ip:${EF_PORTAL_PORT}${NC}"
        echo -e "${GREEN}User:${NC} ${EF_PORTAL_EFADMIN_USER}"
        echo -e "${GREEN}Password:${NC} ${EF_PORTAL_EFADMIN_PASSWORD}"
    fi

    if $ENABLE_DCV
    then
        echo -e "${GREEN}To access DCV Server (TCP and UDP):${NC} your_ip:${DCV_SERVER_PORT}"
    fi

    if $ENABLE_SLURM
    then
        echo -e "${GREEN}SLURM is available. You can test: srun hostname, sinfo${NC}"
    fi

    echo -e "${GREEN}Note: If any service get connectiong refused, you need to disable firewalld or allow some ports:${NC}"
    echo "- DCV: 8443 TCP and UDP"
    echo "- EF Portal: 8448 TCP"
}

checkParameters $@

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
$NISP_INSTALLER_VERBOSE && echo "Unknown error. Exiting..."
exit 255
