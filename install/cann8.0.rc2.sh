#!/bin/bash

# define parameters
MPICH_TAR="/root/software/common/mpich-4.2.0.tar.gz"
CONDA_PKG="/root/software/common/Anaconda3-2024.02-1-Linux-aarch64.sh"
ASCEND_TOOLKIT="/root/software/cann8.0.rc2/Ascend-cann-toolkit_8.0.RC2.alpha001_linux-aarch64.run"
ASCEND_KERNEL="/root/software/cann8.0.rc2/Ascend-cann-kernels-910b_8.0.RC2.alpha001_linux.run"
TORCH_WHL="/root/software/torch2.1.0/torch_npu-2.1.0.post3-cp310-cp310-manylinux_2_17_aarch64.manylinux2014_aarch64.whl"
MINDSPORE_WHL="/root/software/mindspore2.3.0rc1/mindspore-2.3.0rc1-cp39-cp39-linux_aarch64.whl"
echo "CANN_8.0.RC2" > /root/version
SSH_PORT="802"

# start install.sh
bash /root/script/install.sh ${MPICH_TAR} ${CONDA_PKG} ${ASCEND_TOOLKIT} ${ASCEND_KERNEL}
source /root/script/conda && source /root/script/bashrc
echo "Port ${SSH_PORT}" >> /etc/ssh/sshd_config
service ssh start

# create conda env
bash /root/script/conda_create.sh "torch2.1.0" ${TORCH_WHL}
bash /root/script/conda_create.sh "mindspore2.3.0rc1" ${MINDSPORE_WHL}
