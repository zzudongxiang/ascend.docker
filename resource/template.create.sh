docker run -it --ipc=host --privileged --name {name} \
    -v {container_outside_path}/{name}:{container_inside_path} \
    -v {container_outside_path}/{name}/.install.sh:/root/install.sh \
    -v ~/.ssh/id_rsa:/root/.ssh/id_rsa \
    -v ~/.ssh/authorized_keys:/root/.ssh/authorized_keys.host \
    -v /etc/localtime:/etc/localtime \
    -v /usr/local/dcmi:/usr/local/dcmi \
    -v /usr/local/bin/npu-smi:/usr/local/bin/npu-smi \
    -v /usr/local/Ascend/driver:/usr/local/Ascend/driver \
    -v /usr/local/Ascend/firmware:/usr/local/Ascend/firmware \
    -v /etc/ascend_install.info:/etc/ascend_install.info \
    -v ~/workdir:/root/workdir \
    --workdir=/root \
    --device=/dev/davinci0 \
    --device=/dev/davinci1 \
    --device=/dev/davinci2 \
    --device=/dev/davinci3 \
    --device=/dev/davinci4 \
    --device=/dev/davinci5 \
    --device=/dev/davinci6 \
    --device=/dev/davinci7 \
    --device=/dev/hisi_hdc \
    --device=/dev/devmm_svm \
    --device=/dev/davinci_manager \
    -u root \
    {network} \
    ubuntu:20.04 /bin/bash