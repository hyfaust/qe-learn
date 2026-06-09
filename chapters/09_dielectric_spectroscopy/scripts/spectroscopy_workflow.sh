#!/bin/bash
###############################################################################
#  介电与光谱性质计算流程脚本
#
#  本脚本演示两个工作流：
#    工作流 1: 金刚石（C）的介电性质 + IR/Raman 光谱（DFPT 方法）
#    工作流 2: Si 的频率依赖介电函数（epsilon.x 方法）
#
#  用法: bash spectroscopy_workflow.sh
###############################################################################

set -e  # 遇到错误立即退出

# === 配置 ===
PW="pw.x"
PH="ph.x"
DYNMAT="dynmat.x"
EPSILON="epsilon.x"
PSEUDO_DIR="./"        # 赝势文件目录
TMP_DIR="./tmp"        # 临时文件目录

mkdir -p "$TMP_DIR"

echo "============================================"
echo "  工作流 1: 金刚石 IR/Raman 光谱（DFPT）"
echo "============================================"

# Step 1: SCF 计算
echo "[Step 1] 金刚石 SCF 计算..."
$PW -in c_scf.in > c_scf.out
echo "  SCF 完成。"

# Step 2: Γ 点声子 + 介电性质
echo "[Step 2] 金刚石 Γ 点声子计算 (epsil=.true., lraman=.true.)..."
$PH -in c_ph_gamma.in > c_ph_gamma.out
echo "  声子计算完成。"

# Step 3: dynmat.x 后处理
echo "[Step 3] dynmat.x 提取 IR/Raman 强度..."
$DYNMAT -in c_dynmat.in > c_dynmat.out
echo "  IR/Raman 数据已写入 C.dyn.out"
echo "  查看: grep 'IR' C.dyn.out"

echo ""
echo "============================================"
echo "  工作流 2: Si 频率依赖介电函数"
echo "============================================"

# Step 4: Si SCF
echo "[Step 4] Si SCF 计算..."
# 使用第1章的输入或自行准备
# $PW -in si_scf.in > si_scf.out
echo "  (跳过 - 请先完成 Si SCF 计算)"

# Step 5: Si NSCF（更多能带）
echo "[Step 5] Si NSCF 计算（nbnd=32）..."
# $PW -in si_scf.nscf.in > si_nscf.out
echo "  (跳过 - 需要先完成 Step 4)"

# Step 6: epsilon.x
echo "[Step 6] epsilon.x 介电函数计算..."
# $EPSILON -in si_epsilon.in > si_epsilon.out
echo "  (跳过 - 需要先完成 Step 5)"

echo ""
echo "============================================"
echo "  全部计算完成！"
echo "============================================"
echo ""
echo "输出文件说明:"
echo "  c_scf.out      — SCF 输出（总能量、力）"
echo "  c_ph_gamma.out — 声子输出（频率、介电常数、Born 电荷、拉曼张量）"
echo "  C.dyn.out      — dynmat.x 输出（IR/Raman 强度）"
echo ""
echo "查看介电常数:     grep -A5 'dielectric' c_ph_gamma.out"
echo "查看 Born 电荷:   grep -A5 'Effective' c_ph_gamma.out"
echo "查看声子频率:     grep 'freq' c_ph_gamma.out"
