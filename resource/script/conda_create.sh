#!/bin/bash

ROOT_PATH=$1
ENV_NAME=$2
PY_VERSION=$3
INSTALL_WHL=$4

# check parameter
if [[ $(echo ${ENV_NAME} | grep "None") ]]; then
    echo "Skip Empty Create Args"
    exit
fi

# create conda env
/root/anaconda3/bin/conda init
source ${ROOT_PATH}/script/conda
source ${ROOT_PATH}/script/bashrc
echo -e "\033[32mCreate Conda ${ENV_NAME} Python=${PY_VERSION} Environment...\033[0m"
conda create -n ${ENV_NAME} python=${PY_VERSION} -y 
conda activate ${ENV_NAME}

# install pip packages
pip install -r ${ROOT_PATH}/script/requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple
pip install ${ASCEND_HOME}/lib64/te-*-py3-none-any.whl ${ASCEND_HOME}/lib64/hccl-*-py3-none-any.whl
if [[ $(echo ${ENV_NAME} | grep "torch") ]]; then
    pip install torch==2.1.0 --index-url https://download.pytorch.org/whl/cpu
fi

# install ascend-toolkit and ascend-kernels
echo -e "\033[32mInstall Ascend-Toolkit for ${ENV_NAME}...\033[0m"
TOOLKIT_PATH=${ROOT_PATH}/Ascend-cann-toolkit*.run
KERNEL_PATH=${ROOT_PATH}/Ascend-cann-kernels*.run
chmod +x ${TOOLKIT_PATH}
${TOOLKIT_PATH} --quiet --install && ${ROOT_PATH}/script/bashrc
if [ ! -z ${KERNEL_PATH} ]; then
    echo -e "\033[32mInstall Ascend-Kernels for ${ENV_NAME}...\033[0m"
    chmod +x ${KERNEL_PATH}
    ${KERNEL_PATH} --quiet --install && source ${ROOT_PATH}/script/bashrc
fi

# install and test mindspore or torch
pip install -r ${ROOT_PATH}/script/requirements.txt
if [ ! -z ${INSTALL_WHL} ]; then
    pip install ${INSTALL_WHL}
    echo -e "\033[32mTest ${ENV_NAME}\033[0m"
    if [[ $(echo ${ENV_NAME} | grep "torch") ]]; then
        python -c "import torch;import torch_npu; a = torch.ones(3, 4).npu(); print(a + a);"
    elif [[ $(echo ${ENV_NAME} | grep "mindspore") ]]; then
        python -c "import mindspore;mindspore.set_context(device_target='Ascend');mindspore.run_check()"
    else
        echo "NULL Test Function"
    fi
else
    echo "Skip install *.whl"
fi
