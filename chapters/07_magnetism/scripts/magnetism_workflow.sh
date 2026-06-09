#!/bin/bash
#============================================================
# 磁性计算工作流脚本
# 功能：Ni (fcc) 和 Fe (bcc) 铁磁态 SCF 计算 + Ni 能带计算
# 用法：bash magnetism_workflow.sh
#============================================================

set -e

PW="pw.x"
BANDS="bands.x"
PP_DIR="/home/faust/qe-7.0/pseudo"
INPUT_DIR="$(dirname "$0")/../inputs"
WORK_DIR="$(dirname "$0")/../work"

echo "=========================================="
echo " 磁性与自旋极化计算工作流"
echo "=========================================="

# --- 准备工作目录 ---
mkdir -p "${WORK_DIR}"
cd "${WORK_DIR}"

# --- Step 1: Ni 铁磁 SCF ---
echo ""
echo "[Step 1/4] Ni fcc 铁磁 SCF 计算..."
${PW} < "${INPUT_DIR}/ni_fm_scf.in" > ni_fm_scf.out
echo "  -> 总磁矩:"
grep "total magnetization" ni_fm_scf.out || true
grep "absolute magnetization" ni_fm_scf.out || true

# --- Step 2: Fe 铁磁 SCF ---
echo ""
echo "[Step 2/4] Fe bcc 铁磁 SCF 计算..."
${PW} < "${INPUT_DIR}/fe_fm_scf.in" > fe_fm_scf.out
echo "  -> 总磁矩:"
grep "total magnetization" fe_fm_scf.out || true
grep "absolute magnetization" fe_fm_scf.out || true

# --- Step 3: Ni 能带计算 ---
echo ""
echo "[Step 3/4] Ni 铁磁能带计算..."
${PW} < "${INPUT_DIR}/ni_fm_bands.in" > ni_fm_bands.out

# --- Step 4: 能带后处理 ---
echo ""
echo "[Step 4/4] bands.x 能带后处理..."
${BANDS} < "${INPUT_DIR}/ni_bands.pp.in" > ni_bands.pp.out
echo "  -> 能带数据已写入 ni_fm_bands.dat"

echo ""
echo "=========================================="
echo " 计算完成！"
echo " 输出文件位于: ${WORK_DIR}"
echo "=========================================="
