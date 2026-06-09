#!/bin/bash
#
# k_convergence.sh — k 点收敛性测试脚本
#
# 用法: bash k_convergence.sh [pw.x 路径]
# 示例: bash k_convergence.sh /home/faust/qe-7.0/bin/pw.x
#
# 功能: 依次运行不同 k 网格的 Si SCF 计算，提取总能量，
#       输出 k 网格 vs 能量 的汇总表。

set -euo pipefail

# ── 配置 ──────────────────────────────────────────────
PW="${1:-pw.x}"                         # pw.x 路径，默认在 PATH 中
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INPUT_DIR="${SCRIPT_DIR}/../inputs"
WORK_DIR="${SCRIPT_DIR}/../k_conv_work"
OUTPUT_FILE="${WORK_DIR}/k_convergence.dat"

# 要测试的输入文件列表（按网格密度排序）
INPUTS=(
  "si_gamma.in"
  "si_k2.in"
  "si_k4.in"
  "si_k6.in"
  "si_k8.in"
  "si_k10.in"
)

# 对应的标签
LABELS=(
  "Gamma"
  "2x2x2"
  "4x4x4"
  "6x6x6"
  "8x8x8"
  "10x10x10"
)

# ── 主流程 ────────────────────────────────────────────
mkdir -p "${WORK_DIR}"
echo "# k-grid        Energy (Ry)"  >  "${OUTPUT_FILE}"
echo "# ------------------------------" >> "${OUTPUT_FILE}"

for i in "${!INPUTS[@]}"; do
    infile="${INPUTS[$i]}"
    label="${LABELS[$i]}"
    input_path="${INPUT_DIR}/${infile}"
    logfile="${WORK_DIR}/${infile%.in}.log"

    if [ ! -f "${input_path}" ]; then
        echo "[WARNING] 输入文件不存在，跳过: ${input_path}"
        continue
    fi

    echo ">>> 运行 ${label} (${infile}) ..."

    # 清理临时目录，避免前一次计算的影响
    rm -rf "${WORK_DIR}/tmp"

    # 运行 pw.x
    mpirun -np 1 "${PW}" -in "${input_path}" > "${logfile}" 2>&1 || {
        echo "[WARNING] ${label} 计算失败，查看日志: ${logfile}"
        continue
    }

    # 提取总能量
    energy=$(grep "^!" "${logfile}" | tail -1 | awk '{print $5}')

    if [ -z "${energy}" ]; then
        echo "[WARNING] 未能从 ${logfile} 中提取能量"
        continue
    fi

    printf "%-15s %s\n" "${label}" "${energy}" >> "${OUTPUT_FILE}"
    echo "    能量 = ${energy} Ry"
done

# ── 输出结果 ──────────────────────────────────────────
echo ""
echo "========================================="
echo "  k 点收敛性测试结果"
echo "========================================="
column -t "${OUTPUT_FILE}"
echo ""
echo "结果已保存至: ${OUTPUT_FILE}"
