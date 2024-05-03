NAME=$1
VERSION=$2

if ! [ -f ~/install/${VERSION}.sh ]; then
    echo "Please Input cann version like:"
    echo ">> ./create.sh test cann8.0.rc2"
    echo "-------------------"
    ls cann | grep *.sh
    echo "-------------------"
    exit
fi

docker run -it --ipc=host --name ${NAME}-${VERSION} \
    -v ~/install/${VERSION}.sh:/root/install.sh \
    -v ~/script:/root/script \
    -v ~/workdir:/root/workdir \
    -v ~/software:/root/software \
    -v ~/.ssh/id_rsa:/root/.ssh/id_rsa \
    -v ~/.ssh/authorized_keys:/root/.ssh/authorized_keys.host \
    -v /etc/localtime:/etc/localtime \
    --workdir=/root \
    --network=host \
    --privileged \
    --device=/dev/davinci0 \
    --device=/dev/davinci1 \
    --device=/dev/davinci2 \
    --device=/dev/davinci3 \
    --device=/dev/davinci4 \
    --device=/dev/davinci5 \
    --device=/dev/davinci6 \
    --device=/dev/davinci7 \
    --device=/dev/davinci_manager \
    --device=/dev/devmm_svm \
    --device=/dev/hisi_hdc \
    -v /usr/local/Ascend/driver:/usr/local/Ascend/driver \
    -v /usr/local/Ascend/firmware:/usr/local/Ascend/firmware \
    -v /usr/local/bin/npu-smi:/usr/local/bin/npu-smi \
    -v /usr/local/dcmi:/usr/local/dcmi \
    -v /etc/ascend_install.info:/etc/ascend_install.info \
    -u root \
    ubuntu:20.04 /bin/bash
