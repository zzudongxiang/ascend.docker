#!/bin/bash

NAME=$1
INSTALL_WHL=$2

# torch use py3.10 and mindspore use py3.9
if [[ $(echo ${NAME} | grep "torch") != "" ]]; then
    PY_VERSION="3.10"
elif [[ $(echo ${NAME} | grep "mindspore") != "" ]]; then
    PY_VERSION="3.9"
else
    echo "Illegal Name: ${NAME}"
    exit
fi

# create conda env
/root/anaconda3/bin/conda init
source /root/script/conda
source /root/script/bashrc
echo -e "\033[32mCreate Conda ${NAME}${VERSION} Environment...\033[0m"
conda create -n ${NAME} python=${PY_VERSION} -y 
conda activate ${NAME}

# install pip packages
pip install -r /root/script/requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple
pip install ${ASCEND_HOME}/lib64/te-*-py3-none-any.whl ${ASCEND_HOME}/lib64/hccl-*-py3-none-any.whl
if [[ $(echo ${NAME} | grep "torch") ]]; then
    pip install torch==2.1.0 --index-url https://download.pytorch.org/whl/cpu
fi

# install ascend-toolkit and ascend-kernels
ASCEND_INSTALL_PATH="/usr/local/Ascend/software"
echo -e "\033[32mInstall Ascend-Toolkit for ${NAME}...\033[0m"
${ASCEND_INSTALL_PATH}/Ascend-cann-toolkit*.run --quiet --install && source /root/script/bashrc
echo -e "\033[32mInstall Ascend-Kernels for ${NAME}...\033[0m"
${ASCEND_INSTALL_PATH}/Ascend-cann-kernels*.run --quiet --install && source /root/script/bashrc

# install and test mindspore
pip install -r /root/script/requirements.txt

if [-f ${INSTALL_WHL}]; then
    pip install ${INSTALL_WHL}
    echo -e "\033[32mTest ${NAME}\033[0m"
    if [[ $(echo ${NAME} | grep "torch") ]]; then
        python -c "import torch;import torch_npu; a = torch.ones(3, 4).npu(); print(a + a);"
    elif [[ $(echo ${NAME} | grep "mindspore") ]]; then
        python -c "import mindspore;mindspore.set_context(device_target='Ascend');mindspore.run_check()"
    else
        echo "NULL Test Function"
    fi
else
    echo "*.whl not exist: ${INSTALL_WHL}"
fi

