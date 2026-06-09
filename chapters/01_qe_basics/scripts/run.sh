#!/bin/bash
###############################################################################
#  run.sh — 运行 pw.x 进行 Si 晶体 SCF 计算
#
#  用法：
#    bash run.sh                  # 使用默认的 1 个 MPI 进程
#    bash run.sh 4                # 使用 4 个 MPI 进程（并行）
#
#  前提条件：
#    1. 量子 ESPRESSO 已编译安装，pw.x 在 PATH 中
#    2. 赝势文件已放置在 inputs/ 目录中
#    3. 已安装 MPI（如 OpenMPI 或 Intel MPI）
###############################################################################

# --- 配置 ---
NP=${1:-1}                              # MPI 进程数，默认 1
INPUT_DIR="../inputs"                   # 输入文件目录
INPUT_FILE="${INPUT_DIR}/si_scf.in"     # 输入文件名
OUTPUT_FILE="si_scf.out"               # 输出文件名
PSEUDO_DIR="${INPUT_DIR}"              # 赝势文件所在目录
TMP_DIR="./tmp"                        # 临时文件目录

# --- 环境检查 ---
echo "============================================"
echo "  量子 ESPRESSO — Si SCF 计算"
echo "============================================"
echo "MPI 进程数: ${NP}"
echo "输入文件:   ${INPUT_FILE}"
echo "输出文件:   ${OUTPUT_FILE}"
echo ""

# 检查 pw.x 是否可用
if ! command -v pw.x &> /dev/null; then
    echo "错误：找不到 pw.x，请确认量子 ESPRESSO 已安装并加入 PATH"
    echo "  可尝试: export PATH=/path/to/qe-7.0/bin:\$PATH"
    exit 1
fi

# 检查输入文件是否存在
if [ ! -f "${INPUT_FILE}" ]; then
    echo "错误：输入文件 ${INPUT_FILE} 不存在"
    exit 1
fi

# 检查赝势文件
PSEUDO_FILE="${INPUT_DIR}/Si.pbe-n-rrkjus_psl.1.0.0.UPF"
if [ ! -f "${PSEUDO_FILE}" ]; then
    echo "警告：赝势文件 ${PSEUDO_FILE} 不存在"
    echo "  请从 https://www.quantum-espresso.org/pseudopotentials/ 下载"
    echo "  或修改输入文件中的 pseudo_dir 指向赝势所在目录"
fi

# --- 创建临时目录 ---
mkdir -p "${TMP_DIR}"

# --- 运行计算 ---
echo "开始计算..."
echo ""

if [ "${NP}" -gt 1 ]; then
    # 并行运行
    echo "使用 mpirun -np ${NP} pw.x ..."
    mpirun -np ${NP} pw.x \
        -in ${INPUT_FILE} \
        -outdir ${TMP_DIR} \
        > ${OUTPUT_FILE} 2>&1
else
    # 串行运行
    echo "使用 pw.x 串行运行..."
    pw.x \
        -in ${INPUT_FILE} \
        -outdir ${TMP_DIR} \
        > ${OUTPUT_FILE} 2>&1
fi

# --- 检查计算是否成功 ---
if [ $? -eq 0 ]; then
    echo ""
    echo "计算完成！输出文件: ${OUTPUT_FILE}"
    echo ""
    echo "--- 关键结果 ---"
    # 提取总能量
    grep -E '! *total energy' ${OUTPUT_FILE} | tail -1
    # 提取 SCF 收敛信息
    grep 'convergence has been achieved' ${OUTPUT_FILE} | tail -1
    echo ""
    echo "完整输出请查看: cat ${OUTPUT_FILE}"
else
    echo ""
    echo "错误：计算失败，请检查输出文件 ${OUTPUT_FILE}"
    tail -20 ${OUTPUT_FILE}
    exit 1
fi
