# NISP Installer

The easiest way to setup EnginFrame Portal, Slurm and DCV Server without interaction.

Get a popcorn, execute and watch the show ;)

# How to install

The default installation will setup EF Portal, DCV Sever without GPU support and SLURM (24.04.2).

```bash
bash nisp-installer.sh
```

# How to customize SLURM version

```bash
export SLURM_VERSION=24.05.2
bash nisp-installer.sh
```

# Possible parameters:

* --disable-slurm=true : if true, slurm will not be installed
* --disable-dcv=true : if true, DCV will not be installed 
* --disable-efp=true : if true, EF Portal will not be installed 
* --enable-dcv-gpu-nvidia=true : if true, DCV with NVIDIA GPU support will be installed
* --enable-dcv-gpu-amd=true : if true, DCV with AMD GPU support will be installed
