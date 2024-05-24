#!/bin/bash

# define parameters
MPICH_PKG="{mpich_pkg}"
CONDA_PKG="{conda_pkg}"
TOOLKIT_PKG="{toolkit_pkg}"
KERNEL_PKG="{kernel_pkg}"
echo "CANN_{cann_version}" > /root/version

# update apt packages
echo -e "\033[32m[1/7] update apt packages...\033[0m"
apt update && apt upgrade -y
apt install -y git git-lfs nano openssh-server openssl tcl patch
apt install -y gcc gcc-7 g++ gdb make cmake net-tools iproute2
apt install -y autoconf automake unzip pciutils gfortran flex
apt install -y zlib1g zlib1g-dev libsqlite3-dev libssl-dev
apt install -y libtool libffi-dev libblas-dev libblas3 libnuma-dev
apt install -y libgl1-mesa-glx

# install mpich
MPICH_PATH="/root/mpich"
echo -e "\033[32m[2/7] install mpich...\033[0m"
if [ ! -d ${MPICH_PATH} ]; then
    cd && mkdir
    cp ${MPICH_PKG} mpich_tmp.tar.gz
    tar -zvxf mpich_tmp.tar.gz && rm mpich_tmp.tar.gz
    cd mpich-* && ./configure -prefix=${MPICH_PATH} --disable-fortran
    make -j 32 && make install
    cd .. && rm -rf mpich-*
fi

# install anaconda
CONDA_PATH="/root/anaconda3"
echo -e "\033[32m[3/7] install anaconda\033[0m"
if [ ! -d ${CONDA_PATH} ]; then
    bash ${CONDA_PKG} -b
fi
${CONDA_PATH}/bin/conda init
source {container_inside_path}/script/conda
conda install -c conda-forge conda-bash-completion -y
pip install -r {container_inside_path}/script/requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple

# init bashrc and sshd_config
echo -e "\033[32m[4/7] init bashrc and sshd_config...\033[0m"
if [ `grep -c "conda env list && cat /root/version" ~/.bashrc` -ne '1' ];then
    cat /root/.ssh/authorized_keys.host > ~/.ssh/authorized_keys
    cat {container_inside_path}/script/sshd_config >> /etc/ssh/sshd_config
    cat {container_inside_path}/script/bashrc >> ~/.bashrc
    echo "conda env list && cat /root/version" >> ~/.bashrc
fi

# install ascend-toolkit
echo -e "\033[32m[5/7] install ascend-toolkit...\033[0m"
ASCEND_INSTALL_PATH="/usr/local/Ascend/software"
mkdir ${ASCEND_INSTALL_PATH}
cp ${TOOLKIT_PKG} ${ASCEND_INSTALL_PATH}/
chmod +x ${TOOLKIT_PKG}
${TOOLKIT_PKG} --quiet --install
source {container_inside_path}/script/bashrc

# install ascend-kernels
echo -e "\033[32m[6/7] install ascend-kernels\033[0m"
if [[ ! $(echo ${KERNEL_PKG} | grep "None") ]]; then
cp ${KERNEL_PKG} ${ASCEND_INSTALL_PATH}/
chmod +x ${KERNEL_PKG}
${KERNEL_PKG} --quiet --install
source {container_inside_path}/script/bashrc
fi

# test npu-smi and mpirun
echo -e "\033[32m[7/7] test npu-smi and mpirun\033[0m"
npu-smi info
cd /usr/local/Ascend/ascend-toolkit/latest/tools/hccl_test
make ASCEND_DIR=/usr/local/Ascend/ascend-toolkit/latest
mpirun -n 8 ./bin/all_reduce_test -b 2048M -e 2048M -f 2 -p 8 && cd

# source and start ssh
source {container_inside_path}/script/conda && source {container_inside_path}/script/bashrc
service ssh start

# create conda env
bash {container_inside_path}/script/conda_create.sh "{container_inside_path}" "{mindspore_name}" "{mindspore_py}" "{mindspore_pkg}"
bash {container_inside_path}/script/conda_create.sh "{container_inside_path}" "{torch_name}" "{torch_py}" "{torch_pkg}"
