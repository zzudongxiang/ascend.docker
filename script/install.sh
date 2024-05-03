#!/bin/bash

MPICH_TAR=$1
CONDA_PKG=$2
ASCEND_TOOLKIT=$3
ASCEND_KERNEL=$4

# update apt packages
echo -e "\033[32m[1/7] update apt packages...\033[0m"
apt update && apt upgrade -y
apt install -y git git-lfs nano openssh-server openssl 
apt install -y gcc g++ gdb make cmake net-tools iproute2 
apt install -y autoconf automake unzip pciutils gfortran 
apt install -y zlib1g zlib1g-dev libsqlite3-dev libssl-dev 
apt install -y libtool libffi-dev libblas-dev libblas3

# install mpich
echo -e "\033[32m[2/7] install mpich...\033[0m"
if [ ! -d "/root/mpich" ]; then
    cd && mkdir
    cp ${MPICH_TAR} mpich_tmp.tar.gz
    tar -zvxf mpich_tmp.tar.gz && rm mpich_tmp.tar.gz
    cd mpich-* && ./configure -prefix=/root/mpich --disable-fortran
    make -j 32 && make install
    cd .. && rm -rf mpich-*
fi

# install anaconda
echo -e "\033[32m[3/7] install anaconda\033[0m"
if [ ! -d "/root/anaconda3" ]; then
    bash ${CONDA_PKG} -b
fi

/root/anaconda3/bin/conda init
source /root/script/conda
pip install -r /root/script/requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple

# init bashrc and sshd_config
echo -e "\033[32m[4/7] init bashrc and sshd_config...\033[0m"
if [ `grep -c "conda env list && cat /root/version" ~/.bashrc` -ne '1' ];then
    cat /root/.ssh/authorized_keys.host > ~/.ssh/authorized_keys
    cat /root/script/sshd_config >> /etc/ssh/sshd_config
    cat /root/script/bashrc >> ~/.bashrc
    echo "conda env list && cat /root/version" >> ~/.bashrc
fi

# copy ascend file
ASCEND_INSTALL_PATH="/usr/local/Ascend/software"
mkdir ${ASCEND_INSTALL_PATH}
cp ${ASCEND_TOOLKIT} ${ASCEND_INSTALL_PATH}/
cp ${ASCEND_KERNEL} ${ASCEND_INSTALL_PATH}/

# install ascend-toolkit
echo -e "\033[32m[5/7] install ascend-toolkit...\033[0m"
${ASCEND_TOOLKIT} --quiet --install && source /root/script/bashrc

# install ascend-kernels
echo -e "\033[32m[6/7] install ascend-kernels\033[0m"
${ASCEND_KERNEL} --quiet --install && source /root/script/bashrc

# test npu-smi and mpirun
echo -e "\033[32m[7/7] test npu-smi and mpirun\033[0m"
npu-smi info
cd /usr/local/Ascend/ascend-toolkit/latest/tools/hccl_test
make ASCEND_DIR=/usr/local/Ascend/ascend-toolkit/latest
mpirun -n 8 ./bin/all_reduce_test -b 2048M -e 2048M -f 2 -p 8 && cd
