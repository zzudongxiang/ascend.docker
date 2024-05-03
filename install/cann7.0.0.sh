#!/bin/bash

# define parameters
MPICH_TAR="/root/software/common/mpich-4.2.0.tar.gz"
CONDA_PKG="/root/software/common/Anaconda3-2024.02-1-Linux-aarch64.sh"
ASCEND_TOOLKIT="/root/software/cann7.0.0/Ascend-cann-toolkit_7.0.0_linux-aarch64.run"
ASCEND_KERNEL="/root/software/cann7.0.0/Ascend-cann-kernels-910b_7.0.0_linux.run"
TORCH_WHL="/root/software/torch2.1.0/torch_npu-2.1.0.post3-cp310-cp310-manylinux_2_17_aarch64.manylinux2014_aarch64.whl"
MINDSPORE_WHL="/home/zhangdx/software/mindspore2.2.11/mindspore-2.2.11-cp39-cp39-linux_aarch64.whl"
echo "CANN_7.0.0" > /root/version
SSH_PORT="700"

# start install.sh
bash /root/script/install.sh ${MPICH_TAR} ${CONDA_PKG} ${ASCEND_TOOLKIT} ${ASCEND_KERNEL}
source /root/script/conda && source /root/script/bashrc
echo "Port ${SSH_PORT}" >> /etc/ssh/sshd_config
service ssh start

# create conda env
bash /root/script/conda_create.sh "torch2.1.0" ${TORCH_WHL}
bash /root/script/conda_create.sh "mindspore2.2.11" ${MINDSPORE_WHL}

