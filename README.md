# NISP Installer

The easiest way to setup EnginFrame Portal, Slurm and DCV Server without interaction.

Get a popcorn, execute and watch the show ;)

# Requirements:

* OS Linux RedHat based (EL 8 and 9): RedHat, CentOS, Rocky and Alma Linux
* OS Linux Ubuntu based: 20.04, 22.04 and 24.04

Notes:
- Some componentes can be installed under Ubuntu 18.04 if you provide correct repositories, but we recommend to use a newer LTS version.

# How to install

If you want to setup EF Portal, DCV Sever and SLURM (24.04.2):

```bash
bash nisp-installer.sh --enable-slurm=true --enable-dcv=true --enable-efp=true
```

Notes:
- If you do not provide a specific parameter (example: --enable-slurm=true), the default value is false.
- If you want to customize the SLURM version, please continue reading this guide.

# How to customize SLURM version

```bash
export SLURM_VERSION=24.05.2
bash nisp-installer.sh
```

# Possible parameters:

* --enable-slurm=true : if true, SLURM will be installed
* --enable-dcv=true : if true, DCV Server will be installed 
* --enable-efp=true : if true, EF Portal will be installed 
* --enable-dcv-gpu-nvidia=true : if true, DCV Server with NVIDIA GPU support will be installed
* --enable-dcv-gpu-amd=true : if true, DCV Server with AMD GPU support will be installed
