# Tensorflow 安装

官网安装指南：[安装 TensorFlow 2](https://www.tensorflow.org/install)



- [使用pip安装](#pip 安装 tensorflow)

- [使用docker](Docker)

- [GPU支持](#GPU支持)

- [源代码构建](#源代码构建)

- [在线环境](#在线环境)

注：实验所使用的系统为ubuntu18.04



## 软件包

### pip 安装 tensorflow

> 系统要求
> Python 3.6–3.9
> 若要支持 Python 3.9，需要使用 TensorFlow 2.5 或更高版本。
> 若要支持 Python 3.8，需要使用 TensorFlow 2.2 或更高版本。
> pip 19.0 或更高版本（需要 manylinux2010 支持）
> Ubuntu 16.04 或更高版本（64 位）
> macOS 10.12.6 (Sierra) 或更高版本（64 位）（不支持 GPU）
> macOS 要求使用 pip 20.3 或更高版本
> Windows 7 或更高版本（64 位）
> 适用于 Visual Studio 2015、2017 和 2019 的 Microsoft Visual C++ 可再发行软件包
> GPU 支持需要使用支持 CUDA® 的卡（适用于 Ubuntu 和 Windows）
>
> 硬件要求
> 从 TensorFlow 1.6 开始，二进制文件使用 AVX 指令，这些指令可能无法在旧版 CPU 上运行。
> 阅读 GPU 支持指南，以在 Ubuntu 或 Windows 上设置支持 CUDA® 的 GPU 卡。



#### 安装python 开发环境

```sh
#检查python pip 版本
python3 --version
pip3 --version

#若未安装，则执行以下命令安装
sudo apt update
sudo apt install python3-dev python3-pip python3-venv
```



#### 创建虚拟环境

Python 虚拟环境用于将软件包安装与系统隔离开来。

```sh
#创建一个新的虚拟环境，方法是选择 Python 解释器并创建一个 `./venv` 目录来存放它：
python3 -m venv --system-site-packages ./venv

#使用特定于 shell 的命令激活该虚拟环境
source ./venv/bin/activate  # sh, bash, or zsh

. ./venv/bin/activate.fish  # fish

source ./venv/bin/activate.csh  # csh or tcsh

#当虚拟环境处于有效状态时，shell 提示符带有 (venv) 前缀。

#在不影响主机系统设置的情况下，在虚拟环境中安装软件包。首先升级 pip

pip install --upgrade pip

pip list  # show packages installed within the virtual environment

#退出虚拟环境
deactivate  # don't exit until you're done using TensorFlow
```



#### 安装Tensorflow pip 包

```sh
#虚拟环境安装
pip install --upgrade tensorflow
#测试
python -c "import tensorflow as tf;print(tf.reduce_sum(tf.random.normal([1000, 1000])))"

#系统安装
pip3 install --user --upgrade tensorflow  # install in $HOME

#测试
python3 -c "import tensorflow as tf; print(tf.reduce_sum(tf.random.normal([1000, 1000])))"

```



### Docker

>Docker 使用容器创建虚拟环境，以便将 TensorFlow 安装结果与系统的其余部分隔离开来。TensorFlow 程序在此虚拟环境中运行，该环境能够与其主机共享资源（访问目录、使用 GPU、连接到互联网等）。我们会针对每个版本测试 TensorFlow Docker 映像。
>
>Docker 是在 Linux 上启用 TensorFlow GPU 支持的最简单方法，因为只需在主机上安装 NVIDIA® GPU 驱动程序，而不必安装 NVIDIA® CUDA® 工具包。
>
>验证 `nvidia-docker` 安装效果:`docker run --gpus all --rm nvidia/cuda nvidia-smi`

> TensorFlow Docker 要求
> 在本地主机上安装 Docker。
> 如需在 Linux 上启用 GPU 支持，请安装 NVIDIA Docker 支持。
> 请通过 docker -v 检查 Docker 版本。对于 19.03 之前的版本，您需要使用 nvidia-docker2 和 --runtime=nvidia 标记；对于 19.03 及之后的版本，您将需要使用 nvidia-container-toolkit 软件包和 --gpus all 标记。这两个选项都记录在上面链接的网页上。



#### 下载Tensorflow Docker 镜像

```sh
#可以选择自己所需的版本下载
docker pull tensorflow/tensorflow                     # latest stable release
docker pull tensorflow/tensorflow:devel-gpu           # nightly dev release w/ GPU support
docker pull tensorflow/tensorflow:latest-gpu-jupyter  # latest release w/ GPU support and Jupyter


#启动Tensorflow容器的命令
docker run [-it] [--rm] [-p hostPort:containerPort] tensorflow/tensorflow[:tag] [command]

#使用每夜版 TensorFlow 启动 Jupyter 笔记本服务器：
docker run -it -p 8888:8888 tensorflow/tensorflow:nightly-jupyter

#按照说明在主机网络浏览器中打开以下网址：http://127.0.0.1:8888/?token=...


#下载并运行支持 GPU 的 TensorFlow 映像（可能需要几分钟的时间）：
docker run --gpus all -it --rm tensorflow/tensorflow:latest-gpu \
   python -c "import tensorflow as tf; print(tf.reduce_sum(tf.random.normal([1000, 1000])))"
   
  #输出
  tf.Tensor(-608.4587, shape=(), dtype=float32)
   
```



### GPU支持

参考官网指南https://www.tensorflow.org/install/gpu





## 源代码构建

官网指南：https://www.tensorflow.org/install/source



### 构建工具

#### 安装 Python 和 TensorFlow 软件包依赖项

```sh
sudo apt install python3-dev python3-pip


#安装依赖项
pip install -U --user pip numpy wheel
pip install -U --user keras_preprocessing --no-deps
```



#### 安装 Bazel

安装[bazelisk](https://github.com/bazelbuild/bazelisk) 更方便的安装bazel，也可以直接安装[bazel](https://docs.bazel.build/versions/main/install.html)



#### 下载源码

```sh
git clone https://github.com/tensorflow/tensorflow.git
cd tensorflow

#检出想要构建的版本
git checkout branch_name  # r2.2, r2.3, etc.
```



### 配置build

运行 TensorFlow 源代码树根目录下的 ./configure 配置系统 build。此脚本会提示您指定 TensorFlow 依赖项的位置，并要求指定其他构建配置选项（例如，编译器标记）。

```sh
./configure

#示例会话参考
./configure
You have bazel 3.0.0 installed.
Please specify the location of python. [Default is /usr/bin/python3]:

Found possible Python library paths:
  /usr/lib/python3/dist-packages
  /usr/local/lib/python3.6/dist-packages
Please input the desired Python library path to use.  Default is [/usr/lib/python3/dist-packages]

Do you wish to build TensorFlow with OpenCL SYCL support? [y/N]:
No OpenCL SYCL support will be enabled for TensorFlow.

Do you wish to build TensorFlow with ROCm support? [y/N]:
No ROCm support will be enabled for TensorFlow.

Do you wish to build TensorFlow with CUDA support? [y/N]: Y
CUDA support will be enabled for TensorFlow.

Do you wish to build TensorFlow with TensorRT support? [y/N]:
No TensorRT support will be enabled for TensorFlow.

Found CUDA 10.1 in:
    /usr/local/cuda-10.1/targets/x86_64-linux/lib
    /usr/local/cuda-10.1/targets/x86_64-linux/include
Found cuDNN 7 in:
    /usr/lib/x86_64-linux-gnu
    /usr/include

Please specify a list of comma-separated CUDA compute capabilities you want to build with.
You can find the compute capability of your device at: https://developer.nvidia.com/cuda-gpus Each capability can be specified as "x.y" or "compute_xy" to include both virtual and binary GPU code, or as "sm_xy" to only include the binary code.
Please note that each additional compute capability significantly increases your build time and binary size, and that TensorFlow only supports compute capabilities >= 3.5 [Default is: 3.5,7.0]: 6.1

Do you want to use clang as CUDA compiler? [y/N]:
nvcc will be used as CUDA compiler.

Please specify which gcc should be used by nvcc as the host compiler. [Default is /usr/bin/gcc]:

Please specify optimization flags to use during compilation when bazel option "--config=opt" is specified [Default is -march=native -Wno-sign-compare]:

Would you like to interactively configure ./WORKSPACE for Android builds? [y/N]:
Not configuring the WORKSPACE for Android builds.

Preconfigured Bazel build configs. You can use any of the below by adding "--config=<>" to your build command. See .bazelrc for more details.
    --config=mkl            # Build with MKL support.
    --config=monolithic     # Config for mostly static monolithic build.
    --config=ngraph         # Build with Intel nGraph support.
    --config=numa           # Build with NUMA support.
    --config=dynamic_kernels    # (Experimental) Build kernels into separate shared objects.
    --config=v2             # Build TensorFlow 2.x instead of 1.x.
Preconfigured Bazel build configs to DISABLE default on features:
    --config=noaws          # Disable AWS S3 filesystem support.
    --config=nogcp          # Disable GCP support.
    --config=nohdfs         # Disable HDFS support.
    --config=nonccl         # Disable NVIDIA NCCL support.
Configuration finished
```



> 注意若是需要GPU支持，检查并明确设置CUDA版本及路径。
>
> 可以将一些预先配置好的 build 配置添加到 bazel build 命令中，例如：
> --config=dbg - 构建时提供调试信息。详情请参阅 CONTRIBUTING.md。
> --config=mkl - 支持 Intel® MKL-DNN。
> --config=monolithic：此配置适用于基本保持静态的单体 build。
> --config=v1：用于构建 TensorFlow 1.x，而不是 2.x。



### 构建pip软件包

```sh
#使用bazel build 构建仅支持tensorflow 2.x的软件包
bazel build [--config=option] //tensorflow/tools/pip_package:build_pip_package

#构建GPU支持的软件包
bazel build --config=cuda [--config=option] //tensorflow/tools/pip_package:build_pip_package

#若要构建旧版 TensorFlow 1.x 软件包，请使用 --config=v1 选项：
bazel build --config=v1 [--config=option] //tensorflow/tools/pip_package:build_pip_package

```

`bazel build` 命令会创建一个名为 `build_pip_package` 的可执行文件，此文件是用于构建 `pip` 软件包的程序。如下所示地运行该可执行文件，以在 `/tmp/tensorflow_pkg` 目录中构建 `.whl` 软件包。

```sh
#如需从某个版本分支构建，请使用如下目录：
./bazel-bin/tensorflow/tools/pip_package/build_pip_package /tmp/tensorflow_pkg
```



生成的 `.whl` 文件的文件名取决于 TensorFlow 版本和您的平台。例如，使用 `pip install` 安装软件包：

```sh
pip install /tmp/tensorflow_pkg/tensorflow-version-tags.whl
```



### Docker Linux 构建

以下参考示例会下载 TensorFlow `:devel-gpu` 映像并使用 `nvidia-docker` 运行支持 GPU 的容器。此开发映像配置为构建支持 GPU 的 pip 软件包：

```sh
docker pull tensorflow/tensorflow:devel-gpu
docker run --gpus all -it -w /tensorflow -v $PWD:/mnt -e HOST_PERMS="$(id -u):$(id -g)" \
    tensorflow/tensorflow:devel-gpu bash
git pull  # within the container, download the latest source code

#在该容器的虚拟环境中，构建支持 GPU 的 TensorFlow 软件包：
./configure  # answer prompts or use defaults

bazel build --config=opt --config=cuda //tensorflow/tools/pip_package:build_pip_package

./bazel-bin/tensorflow/tools/pip_package/build_pip_package /mnt  # create package

chown $HOST_PERMS /mnt/tensorflow-version-tags.whl


#在该容器中安装和验证软件包并检查是否有 GPU：

pip uninstall tensorflow  # remove current version

pip install /mnt/tensorflow-version-tags.whl
cd /tmp  # don't import from source directory
python -c "import tensorflow as tf; print(\"Num GPUs Available: \", len(tf.config.list_physical_devices('GPU')))"


```



官方经过测试的构建配置：https://www.tensorflow.org/install/source#tested_build_configurations

---



## 在线环境



 [Google Colab](https://colab.research.google.com/notebooks/welcome.ipynb)

无需安装，可直接在浏览器中使用 [Colaboratory](https://colab.research.google.com/notebooks/welcome.ipynb) 运行 [TensorFlow 教程](https://www.tensorflow.org/tutorials)。Colaboratory 是一个 Google 研究项目，旨在帮助传播机器学习知识和研究成果。它是一个 Jupyter 笔记本环境，不需要进行任何设置就可以使用，并且完全在云端运行。 [阅读博文](https://medium.com/tensorflow/colab-an-easy-way-to-learn-and-use-tensorflow-d74d1686e309)。

