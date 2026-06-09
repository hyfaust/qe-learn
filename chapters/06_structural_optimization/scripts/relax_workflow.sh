#!/bin/bash
#
# relax_workflow.sh — 结构优化完整工作流
# 用法: bash scripts/relax_workflow.sh
#
# 本脚本演示 Si 结构优化的两步流程:
#   Step 1: relax   (固定晶格，优化原子位置)
#   Step 2: vc-relax (变晶格，同时优化晶格和原子位置)
#
# 所有输入文件位于 inputs/ 目录，输出文件位于 results/ 目录

set -euo pipefail

# ===================== 配置 =====================
PW_CMD="pw.x"
INPUT_DIR="$(cd "$(dirname "$0")/../inputs" && pwd)"
RESULT_DIR="$(cd "$(dirname "$0")/../results" && pwd)"

mkdir -p "${RESULT_DIR}/tmp"

echo "========================================"
echo "  结构优化工作流: Si relax -> vc-relax"
echo "========================================"
echo ""

# ===================== Step 1: relax =====================
echo "[Step 1/2] 固定晶格优化 (relax) ..."
echo "  输入文件: ${INPUT_DIR}/si_relax.in"
echo "  输出文件: ${RESULT_DIR}/si_relax.out"

${PW_CMD} < "${INPUT_DIR}/si_relax.in" > "${RESULT_DIR}/si_relax.out"

# 检查是否正常结束
if grep -q "JOB DONE" "${RESULT_DIR}/si_relax.out"; then
    echo "  [OK] relax 完成"
    # 提取最终力
    echo "  --- 最终原子力 ---"
    grep "Total force" "${RESULT_DIR}/si_relax.out" | tail -1
    echo ""
else
    echo "  [FAIL] relax 未正常结束，请检查 ${RESULT_DIR}/si_relax.out"
    exit 1
fi

# ===================== Step 2: vc-relax =====================
echo "[Step 2/2] 变晶格优化 (vc-relax) ..."
echo "  输入文件: ${INPUT_DIR}/si_vc_relax.in"
echo "  输出文件: ${RESULT_DIR}/si_vc_relax.out"

${PW_CMD} < "${INPUT_DIR}/si_vc_relax.in" > "${RESULT_DIR}/si_vc_relax.out"

# 检查是否正常结束
if grep -q "JOB DONE" "${RESULT_DIR}/si_vc_relax.out"; then
    echo "  [OK] vc-relax 完成"
    # 提取最终晶格参数
    echo "  --- 最终晶格参数 ---"
    grep -A4 "CELL_PARAMETERS" "${RESULT_DIR}/si_vc_relax.out" | tail -4
    echo "  --- 最终原子坐标 ---"
    grep -A3 "ATOMIC_POSITIONS" "${RESULT_DIR}/si_vc_relax.out" | tail -3
    echo ""
else
    echo "  [FAIL] vc-relax 未正常结束，请检查 ${RESULT_DIR}/si_vc_relax.out"
    exit 1
fi

echo "========================================"
echo "  工作流完成！"
echo "  结果文件在: ${RESULT_DIR}/"
echo "========================================"
