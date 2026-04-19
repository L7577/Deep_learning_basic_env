#!/bin/bash

# ================================================
# NVIDIA Container Toolkit 在线安装脚本
# 遵循官方指南：https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html
# 适用系统：Ubuntu / Debian 衍生发行版
# ================================================

set -e

# ---------- 默认配置 ----------
CUDA_IMAGE="nvidia/cuda:12.2.2-base-ubuntu22.04"
REQUIRED_DOCKER_MAJOR=19
REQUIRED_DOCKER_MINOR=3
AUTO_YES=false
SKIP_TEST=false
CHECK_ONLY=false
ENABLE_EXPERIMENTAL=false
TOOLKIT_VERSION=""

# ---------- 颜色输出 ----------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

info()    { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }
section() { echo -e "\n${CYAN}▶ $1${NC}"; }

# ---------- 帮助信息 ----------
show_help() {
    cat << EOF
用法: $0 [选项]

选项:
  -h, --help              显示此帮助信息
  -i, --image <镜像>       指定要拉取的 CUDA Docker 镜像
                          (默认: $CUDA_IMAGE)
  -y, --yes               自动同意所有确认提示 (非交互模式)
  --skip-test             跳过最终的 GPU 访问测试
  -c, --check-only            仅检查系统环境并显示信息，不执行任何安装操作
  --enable-experimental   启用 NVIDIA 实验性仓库 (默认关闭，请谨慎使用)
  --toolkit-version <版本> 指定要安装的 nvidia-container-toolkit 版本
                          例如: 1.19.0-1 (留空则安装最新稳定版)

示例:
  $0                                    # 交互式安装，使用默认稳定仓库
  $0 -y --skip-test                     # 无人值守安装，跳过测试
  $0 --check-only                       # 仅检查环境

EOF
    exit 0
}

# ---------- 参数解析 ----------
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            ;;
        -i|--image)
            CUDA_IMAGE="$2"
            shift 2
            ;;
        -y|--yes)
            AUTO_YES=true
            shift
            ;;
        --skip-test)
            SKIP_TEST=true
            shift
            ;;
        -c|--check-only)
            CHECK_ONLY=true
            shift
            ;;
        --enable-experimental)
            ENABLE_EXPERIMENTAL=true
            shift
            ;;
        --toolkit-version)
            TOOLKIT_VERSION="$2"
            shift 2
            ;;
        *)
            error "未知参数: $1\n使用 -h 或 --help 查看帮助。"
            ;;
    esac
done

# ---------- 工具函数 ----------
REQUIRED_PKGS=("ca-certificates" "curl" "gnupg2")

check_dependency() {
    dpkg -s "$1" &> /dev/null
}

check_network() {
    local test_urls=(
        "https://nvidia.github.io"
        "https://hub.docker.com"
        "https://deb.debian.org"
        "https://archive.ubuntu.com"
    )
    for url in "${test_urls[@]}"; do
        if curl -s --connect-timeout 5 "$url" > /dev/null; then
            return 0
        fi
    done
    return 1
}

# ---------- 1. 权限检查 ----------
section "权限检查"

if [[ $EUID -eq 0 ]]; then
    info "当前以 root 用户运行，拥有完整权限。"
    SUDO=""
    DOCKER_CMD="docker"
else
    SUDO="sudo"
    info "系统级操作将使用 sudo 提权。"

    # 检查 docker 命令权限
    if docker ps &> /dev/null; then
        info "当前用户已在 docker 组中，可直接运行 docker 命令。"
        DOCKER_CMD="docker"
    else
        warn "当前用户不在 docker 组中，docker 命令也需要 sudo。"
        DOCKER_CMD="sudo docker"
        echo "提示：执行 'sudo usermod -aG docker $USER' 并重新登录后，可免 sudo 使用 docker。"
    fi
fi

# ---------- 2. 收集系统环境信息 ----------
section "收集系统环境信息"

# 操作系统信息
if [[ -f /etc/os-release ]]; then
    OS_NAME=$(grep "^NAME" /etc/os-release | cut -d'"' -f2)
    OS_VERSION=$(grep "^VERSION_ID" /etc/os-release | cut -d'"' -f2)
    OS_INFO="$OS_NAME $OS_VERSION"
else
    OS_INFO="未知 (非标准 /etc/os-release)"
fi

# Docker 版本检查
if ! command -v docker &> /dev/null; then
    DOCKER_STATUS="未安装"
    DOCKER_VERSION="N/A"
else
    DOCKER_VERSION=$(docker --version | grep -oP '\d+\.\d+\.\d+' | head -1)
    if [[ -z "$DOCKER_VERSION" ]]; then
        DOCKER_STATUS="已安装但无法解析版本"
    else
        MAJOR=$(echo "$DOCKER_VERSION" | cut -d. -f1)
        MINOR=$(echo "$DOCKER_VERSION" | cut -d. -f2)
        if [[ $MAJOR -lt $REQUIRED_DOCKER_MAJOR ]] || \
           [[ $MAJOR -eq $REQUIRED_DOCKER_MAJOR && $MINOR -lt $REQUIRED_DOCKER_MINOR ]]; then
            DOCKER_STATUS="版本过低 (需要 >= ${REQUIRED_DOCKER_MAJOR}.${REQUIRED_DOCKER_MINOR})"
        else
            DOCKER_STATUS="已安装且版本符合要求"
        fi
    fi
fi

# NVIDIA 驱动信息
if ! command -v nvidia-smi &> /dev/null; then
    NVIDIA_DRIVER="未安装"
    GPU_INFO="无"
else
    NVIDIA_DRIVER=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader | head -1)
    GPU_COUNT=$(nvidia-smi --query-gpu=name --format=csv,noheader | wc -l)
    GPU_INFO="${GPU_COUNT} 个 GPU(s)"
fi

# NVIDIA Container Toolkit 是否已安装？
if dpkg -l | grep -q "nvidia-container-toolkit"; then
    TOOLKIT_STATUS="已安装"
    INSTALLED_VERSION=$(dpkg-query -W -f='${Version}' nvidia-container-toolkit 2>/dev/null || echo "未知")
else
    TOOLKIT_STATUS="未安装 (将进行安装)"
fi

# ---------- 3. 基础条件验证 ----------
if [[ "$DOCKER_STATUS" == "未安装" ]]; then
    error "Docker 未安装。请先安装 Docker (https://docs.docker.com/engine/install/ubuntu/)"
fi
if [[ "$DOCKER_STATUS" == *"版本过低"* ]]; then
    error "Docker 版本 $DOCKER_VERSION 不满足最低要求。请升级至 >= ${REQUIRED_DOCKER_MAJOR}.${REQUIRED_DOCKER_MINOR}。"
fi
if [[ "$NVIDIA_DRIVER" == "未安装" ]]; then
    error "NVIDIA 驱动未安装或 nvidia-smi 不可用。"
fi

# ---------- 4. 前置依赖存在性检查 ----------
section "检查前置依赖"

MISSING_PKGS=()
for pkg in "${REQUIRED_PKGS[@]}"; do
    if check_dependency "$pkg"; then
        info "前置依赖 $pkg 已安装。"
    else
        warn "前置依赖 $pkg 未安装。"
        MISSING_PKGS+=("$pkg")
    fi
done

# ---------- 5. 网络连通性检测 ----------
section "网络连通性检测"

if ! check_network; then
    error "网络连接不可用，请检查网络后重试。"
fi
info "网络连接正常。"

# ---------- 6. 汇总展示 ----------
section "环境与操作汇总"
echo -e "  ${CYAN}操作系统${NC}         : $OS_INFO"
echo -e "  ${CYAN}NVIDIA 驱动${NC}      : $NVIDIA_DRIVER ($GPU_INFO)"
echo -e "  ${CYAN}Docker 版本${NC}      : $DOCKER_VERSION ($DOCKER_STATUS)"
echo -e "  ${CYAN}Docker 命令${NC}      : $DOCKER_CMD"
echo -e "  ${CYAN}NVIDIA Container Toolkit${NC}: $TOOLKIT_STATUS"
if [[ "$TOOLKIT_STATUS" == "已安装" ]]; then
    echo -e "  ${CYAN}NVIDIA Container Toolkit 版本${NC}: $INSTALLED_VERSION"
fi
if [[ "$TOOLKIT_STATUS" != "已安装" && -n "$TOOLKIT_VERSION" ]]; then
    echo -e "                     目标版本: $TOOLKIT_VERSION"
fi

if [[ "$ENABLE_EXPERIMENTAL" == true ]]; then
    echo -e "  ${CYAN}实验性仓库${NC}       : ${YELLOW}已启用 (非生产环境谨慎使用)${NC}"
else
    echo -e "  ${CYAN}实验性仓库${NC}       : 已关闭 (使用稳定仓库)"
fi
echo -e "  ${CYAN}将要拉取的 CUDA 镜像${NC}  : $CUDA_IMAGE"

if [[ "$CHECK_ONLY" == true ]]; then
    echo -e "  ${CYAN}运行模式${NC}         : 仅检查 (--check-only)"
else
    echo -e "  ${CYAN}将要执行的操作${NC}      : 安装/配置 NVIDIA Container Toolkit，拉取 CUDA 镜像"
    if [[ "$SKIP_TEST" == false ]]; then
        echo -e "                     并进行 GPU 访问测试。"
    else
        echo -e "                     并跳过 GPU 访问测试 (--skip-test)。"
    fi
fi
echo

if [[ "$CHECK_ONLY" == true ]]; then
    info "检查模式完成。"
    exit 0
fi

# ---------- 7. 交互确认 ----------
if [[ "$AUTO_YES" == false ]] && [[ -t 0 ]]; then
    read -p "是否继续执行？(Y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]?$|^$ ]]; then
        info "用户取消操作，退出脚本。"
        exit 0
    fi
fi

# ---------- 8. 执行在线安装 ----------

# 安装缺失的前置依赖
if [[ ${#MISSING_PKGS[@]} -gt 0 ]]; then
    info "正在安装缺失的前置依赖: ${MISSING_PKGS[*]}"
    $SUDO apt-get update
    $SUDO apt-get install -y --no-install-recommends "${MISSING_PKGS[@]}"
fi

# 安装 NVIDIA Container Toolkit
if [[ "$TOOLKIT_STATUS" != "已安装" ]]; then
    section "配置 NVIDIA Container Toolkit 仓库"

    info "添加 NVIDIA GPG 密钥..."
    curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | \
        $SUDO gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg

    info "添加 stable 仓库 (官方稳定源)..."
    curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
        sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
        $SUDO tee /etc/apt/sources.list.d/nvidia-container-toolkit.list > /dev/null

    if [[ "$ENABLE_EXPERIMENTAL" == true ]]; then
        info "启用实验性仓库 (--enable-experimental 已指定)..."
        $SUDO sed -i -e '/experimental/ s/^#//g' /etc/apt/sources.list.d/nvidia-container-toolkit.list
    else
        info "实验性仓库保持关闭状态 (默认稳定仓库)。"
    fi

    info "更新软件包列表..."
    $SUDO apt-get update

    section "安装 NVIDIA Container Toolkit 包"
    if [[ -n "$TOOLKIT_VERSION" ]]; then
        info "指定版本: $TOOLKIT_VERSION"
        $SUDO apt-get install -y \
            nvidia-container-toolkit=${TOOLKIT_VERSION} \
            nvidia-container-toolkit-base=${TOOLKIT_VERSION} \
            libnvidia-container-tools=${TOOLKIT_VERSION} \
            libnvidia-container1=${TOOLKIT_VERSION}
    else
        info "安装最新稳定版本..."
        $SUDO apt-get install -y nvidia-container-toolkit
    fi

    info "配置 Docker 运行时以使用 NVIDIA 容器工具包..."
    $SUDO nvidia-ctk runtime configure --runtime=docker

    info "重启 Docker 服务..."
    $SUDO systemctl restart docker

    info "NVIDIA Container Toolkit 安装完成。"
else
    info "NVIDIA Container Toolkit 已安装 (版本: $INSTALLED_VERSION)，跳过安装步骤。"
    # 确保配置已应用
    if ! $SUDO docker info 2>/dev/null | grep -q "nvidia"; then
        warn "检测到 NVIDIA Container Toolkit 未配置到 Docker，现在进行配置..."
        $SUDO nvidia-ctk runtime configure --runtime=docker
        $SUDO systemctl restart docker
    fi
fi

# 拉取 CUDA 镜像
# section "拉取 CUDA Docker 镜像"
# info "镜像: $CUDA_IMAGE"
# $DOCKER_CMD pull "$CUDA_IMAGE"

# 测试 GPU 访问
if [[ "$SKIP_TEST" == false ]]; then
    section "测试容器 GPU 访问"
    info "运行命令: $DOCKER_CMD run --rm --gpus all $CUDA_IMAGE nvidia-smi"
    if $DOCKER_CMD run --rm --gpus all "$CUDA_IMAGE" nvidia-smi; then
        info "✅ 测试成功！容器可以正常访问 GPU。"
    else
        error "❌ 测试失败！容器无法访问 GPU。请检查 NVIDIA Container Toolkit 安装。"
    fi
else
    info "已跳过 GPU 访问测试 (--skip-test)。"
fi

section "安装与验证完成"
echo -e "${GREEN}现在可以使用以下命令运行 CUDA 容器：${NC}"
echo "  $DOCKER_CMD run --rm --gpus all -it $CUDA_IMAGE /bin/bash"
if [[ "$DOCKER_CMD" == "sudo docker" ]]; then
    echo -e "\n${YELLOW}提示：为避免频繁使用 sudo，建议将当前用户加入 docker 组：${NC}"
    echo "  sudo usermod -aG docker $USER"
    echo "  然后注销重新登录即可。"
fi
echo