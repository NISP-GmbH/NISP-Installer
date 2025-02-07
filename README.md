# NISP Installer

The easiest way to setup EnginFrame Portal, Slurm and DCV Server without interation.

Get a popcorn, execute and watch the show ;)

# How to install

```bash
bash nisp-installer.sh
```

# How to customize SLURM version

```bash
export SLURM_VERSION=24.05.2
bash nisp-installer.sh
```

# Possible parameters:

* --disable-slurm= : if true, slurm will not be installed
* --disable-dcv= : if true, dcv will not be installed 
