# 深度学习系统运行环境配置

- 系统环境配置
  - [ubuntu 18.04](#ubuntu)
  - [国内镜像源](#国内镜像源)
  - [基本工具](#基本工具)
  - [docker](#docker)

- 关于NVIDIA
  - [NVIDIA驱动](#NVIDIA显卡驱动)
  - [CUDA](#安装CUDA)
  - [cuDNN](#cuDNN下载)
  - [nvidia-container-toolkit](#NVIDIA_Container_Toolkit)

- 扩展：深度学习框架
  - [Tensorflow](./tensorflow_install_guide.md)
  - [PyTorch](./pytorch_install_guide.md)
  - [Darknet](./darknet_guide.md)

---



*注:实验均在ubuntu18.04中进行*



## 系统环境配置

### ubuntu

操作系统一般选择为ubuntu，目前最新的稳定版本为[20.04](http://releases.ubuntu.com/20.04/)

正常安装即可～



---

### 国内镜像源

1.ubuntu 图形化界面

直接点击 **软件更新器** - 设置 - ubuntu软件 - 下载自   
选择国内的阿里云、清华源 或 使用 <选择最佳服务器(S)>  皆可，
完成后，选择重新载入。

2.命令行

修改 `sources.list` 文件

```sh
#备份
sudo cp /etc/apt/sources.list /etc/apt/sources.list.bak

sudo vim /etc/apt/sources.list
#将内容改为

deb http://mirrors.aliyun.com/ubuntu/ bionic main restricted universe multiverse 
deb http://mirrors.aliyun.com/ubuntu/ bionic-security main restricted universe multiverse 
deb http://mirrors.aliyun.com/ubuntu/ bionic-updates main restricted universe multiverse 
deb http://mirrors.aliyun.com/ubuntu/ bionic-proposed main restricted universe multiverse 
deb http://mirrors.aliyun.com/ubuntu/ bionic-backports main restricted universe multiverse 
deb-src http://mirrors.aliyun.com/ubuntu/ bionic main restricted universe multiverse 
deb-src http://mirrors.aliyun.com/ubuntu/ bionic-security main restricted universe multiverse 
deb-src http://mirrors.aliyun.com/ubuntu/ bionic-updates main restricted universe multiverse 
deb-src http://mirrors.aliyun.com/ubuntu/ bionic-proposed main restricted universe multiverse 
deb-src http://mirrors.aliyun.com/ubuntu/ bionic-backports main restricted universe multiverse


#保存 后，更新软件列表
sudo apt upgrade
sudo apt update

```



---

### 基本工具

#### ssh

若系统未安装SSH，可自行安装

```sh
sudo apt install ssh
```

安装完ssh，即可使用ssh服务远程连接到该机。



####  git

git是必不可少的代码管理工具，一定要安装

``` sh
sudo apt install git

```



---

### docker

官网安装指南: [Install Docker Engine on Ubuntu](https://docs.docker.com/engine/install/ubuntu/)
官方网址提供了三种安装方式，细节请参考官网！

>You can install Docker Engine in different ways, depending on your needs:
>- Most users [set up Docker’s repositories](https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository) and install from them, for ease of installation and upgrade tasks. This is the recommended approach.
>- Some users download the DEB package and [install it manually](https://docs.docker.com/engine/install/ubuntu/#install-from-a-package) and manage upgrades completely manually. This is useful in situations such as installing Docker on air-gapped systems with no access to the internet.
>- In testing and development environments, some users choose to use automated [convenience scripts](https://docs.docker.com/engine/install/ubuntu/#install-using-the-convenience-script) to install Docker.



但**请注意在ubuntu中，可以使用docker.io版本，也就是ubuntu团队维护的Docker版本**

Docker官方维护的版本有：docker-ce (社区免费版本) 、docker-ee(企业收费版)

推荐在ubuntu中使用docker.io版，所有依赖由系统负责，更方便安装以及升级。

```sh
#安装docker
sudo apt-get update
sudo apt-get  install docker.io

#开启docker
systemctl start docker

#开启开机自启动
systemctl enable docker

#查看版本信息
docker version

docker info

#如何卸载docker？
sudo apt-get remove docker docker-engine docker.io containerd runc

sudo rm -rf /var/lib/docker
sudo rm -rf /var/lib/containerd
```

针对非root用户或在无`sudo`命令下运行docker,需要创建docker用户组,参考：[Manage Docker as a non-root user](https://docs.docker.com/engine/install/linux-postinstall/#manage-docker-as-a-non-root-user)

```sh
 #创建docker用户组
 sudo groupadd docker
 #将当前用户加入到 docker用户组
 sudo usermod -aG docker $USER
 #刷新
 newgrp docker 
 #测试
 docker ps
```

> 可能遇到的问题？
>
> Q：docker: Got permission denied while trying to connect to the Docker daemon socket at unix:///var/run/docker.sock: Post http://%2Fvar%2Frun%2Fdocker.sock/v1.24/containers/create?name=tf: dial unix /var/run/docker.sock: connect: permission denied.
>
> 参考：https://stackoverflow.com/questions/48957195/how-to-fix-docker-got-permission-denied-issue
>
> ```sh
> #docker配置文件访问受限制，需要设置
> sudo chgrp docker /lib/systemd/system/docker.socket
> sudo chmod g+w /lib/systemd/system/docker.socket
> 需要重启系统
> 或者
> sudo chmod 666 /var/run/docker.sock
> ```
>
> 



---



## 关于NVIDIA

做深度学习，使用GPU进行加速已是必不可少的操作。

### NVIDIA显卡驱动

1.图形化界面

打开 **软件更新器** - 设置 - 附加驱动 

选择对应的 NVIDIA官方驱动，如： `nvidia-driver-460`

安装完成后，需要重启系统生效



2.命令行

```sh
#先检查是否安装有其他显卡驱动程序，如果有，需要全部清除掉
#查看当前电脑的显卡型号 
lshw -numeric -C display 

#查看nouveau驱动是否使用 
lsmod | grep nouveau 

# 查看集成显卡 
lspci | grep VGA 

# 查看NVIDIA显卡
lspci | grep NVIDIA 

#一定要将旧的驱动程序卸载干净，才可以安装新驱动。
#删除旧的nvidia驱动
sudo apt-get remove –purge nvidia

#更新系统软件
sudo apt upgrade 
sudo apt update

#安装新驱动
sudo apt install nvidia-driver-460

#检查
nvidia-smi
```

3.官网下载安装包
下载地址：https://www.nvidia.com/Download/index.aspx?lang=en-us

下载之后是一个.run 文件，直接运行安装即可！



### 安装CUDA

安装好NVIDIA驱动以后，可以开始安装CUDA。

官网下载地址：[CUDA Toolkit 11.0 Download](https://developer.nvidia.com/cuda-11.0-download-archive?target_os=Linux&target_arch=x86_64&target_distro=Ubuntu&target_version=1804&target_type=runfilelocal) (*可能需要注册nvidia账号*)

```sh
#选择对应系统的版本开始下载安装，目前已经是11.6，也可根据实际需要下载历史版本，如cuda10.0
wget https://developer.download.nvidia.com/compute/cuda/11.6.1/local_installers/cuda_11.6.1_510.47.03_linux.run
sudo sh cuda_11.6.1_510.47.03_linux.run

# 注意在脚本运行过程中，不要再选安装nvidia-driver，前面步骤已经安装过了。

#安装完成以后，还需要配置下环境变量

sudo vim ~/.bashrc 
#添加
   #CUDA_HOME是系统默认安装路径，以实际安装路径为准
    export CUDA_HOME=/usr/local/cuda-10.0 #根据自己安装的版本号
    export LD_LIBRARY_PATH=${CUDA_HOME}/lib64
    export  PATH=${CUDA_HOME}/bin:${PATH}
    
#重新载入使其生效
source ~/.bashrc

#查看cuda版本
nvcc -V

```



### cuDNN下载

官网 [cuDNN](https://developer.nvidia.com/rdp/cudnn-download) (*需要nvidia账号*)



选择与刚才安装的CUDA版本相对应的cuDNN版本，下载后是 一个压缩包

```sh
# 解压，以cuda11.5和cuDNN8.3.2为例
tar -zxvf cudnn-linux-x86_64-8.3.1.22_cuda11.5-archive.tar.xz

#拷贝到对应的cuda安装目录
sudo cp cuda/include/cudnn.h /usr/local/cuda-11.5/include
sudo cp cuda/lib64/libcudnn* /usr/local/cuda-11.5/lib64
sudo chmod a+r /usr/local/cuda-11.5/include/cudnn.h /usr/local/cuda-11.5/lib64/libcudnn*

#查看版本信息
 cat /usr/local/cuda/include/cudnn_version.h | grep CUDNN_MAJOR -A 2
```



### 卸载cuda？

```sh
#执行卸载的脚本,以cuda10.2为例
sudo /usr/local/cuda-10.2/bin/uninstall_cuda_10.2.pl
sudo rm -rf /usr/local/cuda-10.2/

#注释或删除 ～/.bashrc 中与cuda相关的环境变量配置项
```




---

### NVIDIA_Container_Toolkit 

在Docker容器中使用GPU

NVIDIA官方提供了一个docker-nvidia工具，可以将GPU暴露给容器使用

官网安装步骤: [installing-on-ubuntu-and-debian](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html)

>The list of prerequisites for running NVIDIA Container Toolkit is described below:
>- GNU/Linux x86_64 with kernel version > 3.10
>- Docker >= 19.03 (recommended, but some distributions may include older versions of Docker. The minimum supported version is 1.12)
>- NVIDIA GPU with Architecture >= Kepler (or compute capability 3.0)
>- [NVIDIA Linux drivers](http://www.nvidia.com/object/unix.html) >= 418.81.07 (Note that older driver releases or branches are unsupported.)

*注意：确保docker 版本>=19.03，否则可能要使用 nvidia-docker2*

确保先需条件通过后，开始安装

```sh
#	添加源
distribution=$(. /etc/os-release;echo $ID$VERSION_ID) \
   && curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add - \
   && curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list

# 以下为20220715更新
distribution=$(. /etc/os-release;echo $ID$VERSION_ID) \
      && curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
      && curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
            sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
            sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

#   安装 
 sudo apt-get update && sudo apt-get install -y nvidia-container-toolkit
 
# 重启docker
sudo systemctl restart docker

#检查   nvidia-smi  ，注意参数 --gpus all
sudo docker run --rm --gpus all nvidia/cuda:10.0-base nvidia-smi

#输出信息
+-----------------------------------------------------------------------------+
| NVIDIA-SMI 460.91.03    Driver Version: 460.91.03    CUDA Version: 11.2     |
|-------------------------------+----------------------+----------------------+
| GPU  Name        Persistence-M| Bus-Id        Disp.A | Volatile Uncorr. ECC |
| Fan  Temp  Perf  Pwr:Usage/Cap|         Memory-Usage | GPU-Util  Compute M. |
|                               |                      |               MIG M. |
|===============================+======================+======================|
|   0  GeForce GTX 105...  Off  | 00000000:01:00.0 Off |                  N/A |
| N/A   51C    P8    N/A /  N/A |    373MiB /  4040MiB |     10%      Default |
|                               |                      |                  N/A |
+-------------------------------+----------------------+----------------------+
                                                                               
+-----------------------------------------------------------------------------+
| Processes:                                                                  |
|  GPU   GI   CI        PID   Type   Process name                  GPU Memory |
|        ID   ID                                                   Usage      |
|=============================================================================|
+-----------------------------------------------------------------------------+
```



>CUDA images come in three flavors and are available through the [NVIDIA public hub repository](https://hub.docker.com/r/nvidia/cuda).
>- `base`: starting from CUDA 9.0, contains the bare minimum (libcudart) to deploy a pre-built CUDA application.   Use this image if you want to manually select which CUDA packages you want to install.
>- `runtime`: extends the `base` image by adding all the shared libraries from the CUDA toolkit.  Use this image if you have a pre-built application using multiple CUDA libraries.\
>- `devel`: extends the `runtime` image by adding the compiler toolchain, the debugging tools, the headers and the static libraries  Use this image to compile a CUDA application from sources.

参考：https://github.com/NVIDIA/nvidia-docker/wiki/CUDA



需要注意，在安装docker以及nvidia-container-toolkit时，并不会创建docker的配置文件daemon.json，一般需要手动创建。

若是需要将docker运行时 runtimes 参数设置为默认为nvidia,则需要修改配置文件。参考：https://github.com/NVIDIA/nvidia-container-runtime#daemon-configuration-file

```sh
#   /etc/docker/daemon.json

#执行如下命令，设置运行时参数runtimes为nvidia
sudo tee /etc/docker/daemon.json <<EOF
{
    "runtimes": {
        "nvidia": {
            "path": "/usr/bin/nvidia-container-runtime",
            "runtimeArgs": []
        }
    }
}
EOF

#也可以在配置文件中设置默认runtimes参数为nvidia
"default-runtime": "nvidia"


#重启docker后检查
docker info | grep "Runtime"
 Runtimes: io.containerd.runc.v2 io.containerd.runtime.v1.linux nvidia runc
 Default Runtime: nvidia


#默认参数设置成功以后，启动容器时，不用加 --gpus all 也可以正常使用GPU
sudo docker run --rm nvidia/cuda:10.0-base nvidia-smi

+-----------------------------------------------------------------------------+
| NVIDIA-SMI 460.91.03    Driver Version: 460.91.03    CUDA Version: 11.2     |
|-------------------------------+----------------------+----------------------+
| GPU  Name        Persistence-M| Bus-Id        Disp.A | Volatile Uncorr. ECC |
| Fan  Temp  Perf  Pwr:Usage/Cap|         Memory-Usage | GPU-Util  Compute M. |
|                               |                      |               MIG M. |
|===============================+======================+======================|
|   0  GeForce GTX 105...  Off  | 00000000:01:00.0 Off |                  N/A |
| N/A   55C    P0    N/A /  N/A |    350MiB /  4040MiB |      1%      Default |
|                               |                      |                  N/A |
+-------------------------------+----------------------+----------------------+
                                                                               
+-----------------------------------------------------------------------------+
| Processes:                                                                  |
|  GPU   GI   CI        PID   Type   Process name                  GPU Memory |
|        ID   ID                                                   Usage      |
|=============================================================================|
+-----------------------------------------------------------------------------+
```



### NGC

>**Build End-to-End AI With NGC On-Premises, in the Cloud, or at the Edge**
>NVIDIA NGC™ hosts a catalog of GPU-optimized software for AI practitioners to develop their AI solutions. It also provides access to various AI services including NVIDIA Base Command for model training, NVIDIA Fleet Command to deploy and monitor models, and the NGC Private Registry for securely accessing and managing proprietary AI software. Also, NVIDIA AI Enterprise customers can request support through the NGC portal.

[what-is-nvidia-ngc](https://docs.nvidia.com/ngc/ngc-overview/index.html#what-is-nvidia-ngc)

https://catalog.ngc.nvidia.com/





基础运行环境配置结束。



## 扩展：深度学习框架

- [Tensorflow](./tensorflow_install_guide.md)
- [PyTorch](./pytorch_install_guide.md)
- [Darknet](./darknet_guide.md)

