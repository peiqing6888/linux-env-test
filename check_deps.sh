#!/bin/bash

# 设置颜色输出
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}===== Nockchain 依赖检查工具 =====${NC}"
echo "检查系统中是否已安装必要的开发工具..."
echo

# 检查命令是否存在的函数
check_command() {
    if command -v $1 &> /dev/null; then
        echo -e "${GREEN}✓${NC} $1 已安装 $(eval $1 --version 2>&1 | head -n 1)"
        return 0
    else
        echo -e "${RED}✗${NC} $1 未安装"
        return 1
    fi
}

# 检查Rust相关工具
check_rust() {
    if command -v rustc &> /dev/null; then
        echo -e "${GREEN}✓${NC} Rust 已安装 $(rustc --version)"
        if command -v cargo &> /dev/null; then
            echo -e "${GREEN}✓${NC} Cargo 已安装 $(cargo --version)"
        else
            echo -e "${RED}✗${NC} Cargo 未安装，但Rust已安装。这是不正常的情况。"
        fi
        return 0
    else
        echo -e "${RED}✗${NC} Rust 未安装"
        return 1
    fi
}

# 检查基本开发工具
echo -e "\n${YELLOW}基本开发工具:${NC}"
check_command git
GIT_INSTALLED=$?
check_command make
MAKE_INSTALLED=$?
check_command gcc
GCC_INSTALLED=$?

# 检查Rust工具链
echo -e "\n${YELLOW}Rust工具链:${NC}"
check_rust
RUST_INSTALLED=$?

# 检查LLVM/Clang工具
echo -e "\n${YELLOW}LLVM/Clang工具:${NC}"
check_command clang
CLANG_INSTALLED=$?
check_command llvm-config
LLVM_CONFIG_INSTALLED=$?

# 检查其他有用的工具
echo -e "\n${YELLOW}其他有用工具:${NC}"
check_command cmake
CMAKE_INSTALLED=$?
check_command pkg-config
PKG_CONFIG_INSTALLED=$?

# 检查操作系统信息
echo -e "\n${YELLOW}系统信息:${NC}"
if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo -e "操作系统: ${GREEN}$NAME $VERSION${NC}"
elif [ -f /etc/lsb-release ]; then
    . /etc/lsb-release
    echo -e "操作系统: ${GREEN}$DISTRIB_ID $DISTRIB_RELEASE${NC}"
elif [ -f /etc/redhat-release ]; then
    echo -e "操作系统: ${GREEN}$(cat /etc/redhat-release)${NC}"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    echo -e "操作系统: ${GREEN}macOS $(sw_vers -productVersion)${NC}"
else
    echo -e "操作系统: ${YELLOW}无法确定${NC}"
fi

# 检查CPU信息
echo -e "\n${YELLOW}CPU信息:${NC}"
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    CPU_MODEL=$(sysctl -n machdep.cpu.brand_string)
    CPU_CORES=$(sysctl -n hw.physicalcpu)
    CPU_THREADS=$(sysctl -n hw.logicalcpu)
    echo -e "CPU型号: ${GREEN}$CPU_MODEL${NC}"
    echo -e "物理核心数: ${GREEN}$CPU_CORES${NC}"
    echo -e "逻辑核心数: ${GREEN}$CPU_THREADS${NC}"
else
    # Linux
    if [ -f /proc/cpuinfo ]; then
        CPU_MODEL=$(grep -m 1 "model name" /proc/cpuinfo | cut -d ":" -f 2 | sed 's/^[ \t]*//')
        CPU_CORES=$(grep -c "physical id" /proc/cpuinfo | sort -u)
        if [ "$CPU_CORES" -eq 0 ]; then
            CPU_CORES=$(grep -c "processor" /proc/cpuinfo)
        fi
        CPU_THREADS=$(grep -c "processor" /proc/cpuinfo)
        echo -e "CPU型号: ${GREEN}$CPU_MODEL${NC}"
        echo -e "物理核心数: ${GREEN}$CPU_CORES${NC}"
        echo -e "逻辑核心数: ${GREEN}$CPU_THREADS${NC}"
    else
        echo -e "CPU信息: ${YELLOW}无法获取${NC}"
    fi
fi

# 检查内存信息
echo -e "\n${YELLOW}内存信息:${NC}"
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    TOTAL_MEM=$(( $(sysctl -n hw.memsize) / 1024 / 1024 ))
    echo -e "总内存: ${GREEN}${TOTAL_MEM} MB${NC}"
else
    # Linux
    if [ -f /proc/meminfo ]; then
        TOTAL_MEM=$(grep "MemTotal" /proc/meminfo | awk '{print $2}')
        TOTAL_MEM=$(( $TOTAL_MEM / 1024 ))
        FREE_MEM=$(grep "MemAvailable" /proc/meminfo | awk '{print $2}')
        FREE_MEM=$(( $FREE_MEM / 1024 ))
        echo -e "总内存: ${GREEN}${TOTAL_MEM} MB${NC}"
        echo -e "可用内存: ${GREEN}${FREE_MEM} MB${NC}"
    else
        echo -e "内存信息: ${YELLOW}无法获取${NC}"
    fi
fi

# 检查磁盘空间
echo -e "\n${YELLOW}磁盘空间:${NC}"
if command -v df &> /dev/null; then
    echo -e "根目录空间使用情况:"
    df -h / | tail -n 1 | awk '{print "总空间: " $2 ", 已用: " $3 ", 可用: " $4 ", 使用率: " $5}'
else
    echo -e "磁盘信息: ${YELLOW}无法获取${NC}"
fi

# 检查网络连接
echo -e "\n${YELLOW}网络连接:${NC}"
if command -v curl &> /dev/null; then
    if curl -s --connect-timeout 5 https://www.google.com > /dev/null; then
        echo -e "互联网连接: ${GREEN}可用${NC}"
    else
        echo -e "互联网连接: ${RED}不可用${NC}"
    fi
else
    echo -e "互联网连接: ${YELLOW}无法检查 (curl未安装)${NC}"
fi

# 总结
echo -e "\n${YELLOW}===== 检查结果摘要 =====${NC}"
MISSING=0

if [ $GIT_INSTALLED -ne 0 ]; then
    echo -e "- ${RED}需要安装 Git${NC}"
    MISSING=1
fi

if [ $MAKE_INSTALLED -ne 0 ]; then
    echo -e "- ${RED}需要安装 Make${NC}"
    MISSING=1
fi

if [ $RUST_INSTALLED -ne 0 ]; then
    echo -e "- ${RED}需要安装 Rust 和 Cargo${NC}"
    MISSING=1
fi

if [ $CLANG_INSTALLED -ne 0 ]; then
    echo -e "- ${RED}需要安装 Clang${NC}"
    MISSING=1
fi

if [ $LLVM_CONFIG_INSTALLED -ne 0 ]; then
    echo -e "- ${RED}需要安装 LLVM 开发包${NC}"
    MISSING=1
fi

if [ $CMAKE_INSTALLED -ne 0 ]; then
    echo -e "- ${YELLOW}建议安装 CMake (可选)${NC}"
fi

if [ $PKG_CONFIG_INSTALLED -ne 0 ]; then
    echo -e "- ${YELLOW}建议安装 pkg-config (可选)${NC}"
fi

if [ $MISSING -eq 0 ]; then
    echo -e "\n${GREEN}所有必要的开发工具都已安装!${NC}"
    echo -e "此系统已准备好构建和运行Nockchain。"
else
    echo -e "\n${RED}一些必要的开发工具缺失。${NC}"
    echo -e "请安装上述缺失的工具后再尝试构建Nockchain。"
    
    # 提供安装命令建议
    echo -e "\n${YELLOW}安装建议:${NC}"
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        echo -e "在macOS上，您可以使用Homebrew安装缺失的工具:"
        if [ $GIT_INSTALLED -ne 0 ]; then echo "brew install git"; fi
        if [ $MAKE_INSTALLED -ne 0 ]; then echo "brew install make"; fi
        if [ $CLANG_INSTALLED -ne 0 ]; then echo "xcode-select --install"; fi
        if [ $LLVM_CONFIG_INSTALLED -ne 0 ]; then echo "brew install llvm"; fi
        if [ $RUST_INSTALLED -ne 0 ]; then echo "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"; fi
    elif [ -f /etc/debian_version ]; then
        # Debian/Ubuntu
        echo -e "在Debian/Ubuntu上，您可以使用apt安装缺失的工具:"
        echo "sudo apt update"
        if [ $GIT_INSTALLED -ne 0 ]; then echo "sudo apt install -y git"; fi
        if [ $MAKE_INSTALLED -ne 0 ]; then echo "sudo apt install -y make"; fi
        if [ $GCC_INSTALLED -ne 0 ]; then echo "sudo apt install -y build-essential"; fi
        if [ $CLANG_INSTALLED -ne 0 ] || [ $LLVM_CONFIG_INSTALLED -ne 0 ]; then echo "sudo apt install -y clang llvm-dev libclang-dev"; fi
        if [ $CMAKE_INSTALLED -ne 0 ]; then echo "sudo apt install -y cmake"; fi
        if [ $PKG_CONFIG_INSTALLED -ne 0 ]; then echo "sudo apt install -y pkg-config"; fi
        if [ $RUST_INSTALLED -ne 0 ]; then echo "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"; fi
    elif [ -f /etc/redhat-release ]; then
        # RHEL/CentOS/Fedora
        echo -e "在RHEL/CentOS/Fedora上，您可以使用dnf/yum安装缺失的工具:"
        if [ $GIT_INSTALLED -ne 0 ]; then echo "sudo dnf install -y git"; fi
        if [ $MAKE_INSTALLED -ne 0 ]; then echo "sudo dnf install -y make"; fi
        if [ $GCC_INSTALLED -ne 0 ]; then echo "sudo dnf install -y gcc gcc-c++"; fi
        if [ $CLANG_INSTALLED -ne 0 ] || [ $LLVM_CONFIG_INSTALLED -ne 0 ]; then echo "sudo dnf install -y clang llvm-devel"; fi
        if [ $CMAKE_INSTALLED -ne 0 ]; then echo "sudo dnf install -y cmake"; fi
        if [ $PKG_CONFIG_INSTALLED -ne 0 ]; then echo "sudo dnf install -y pkgconfig"; fi
        if [ $RUST_INSTALLED -ne 0 ]; then echo "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"; fi
    else
        echo -e "请根据您的操作系统安装上述缺失的工具。"
    fi
fi

echo -e "\n${YELLOW}===== 检查完成 =====${NC}"