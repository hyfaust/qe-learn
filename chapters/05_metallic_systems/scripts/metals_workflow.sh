#!/bin/bash
# ============================================================
# metals_workflow.sh — 金属体系计算完整流程
# 第五章：金属体系与展宽方法
# ============================================================
#
# 使用方法:
#   cd chapters/05_metallic_systems
#   bash scripts/metals_workflow.sh [pw_cmd]
#
# 参数:
#   pw_cmd — pw.x 和 bands.x 的运行命令（默认 pw.x / bands.x）
#
# ============================================================

set -euo pipefail

# ---- 命令配置 ----
PW_CMD="${1:-pw.x}"
BANDS_CMD="${2:-bands.x}"
INPUT_DIR="$(dirname "$0")/../inputs"
OUTPUT_DIR="$(dirname "$0")/../outputs"

mkdir -p "$OUTPUT_DIR"

echo "============================================"
echo " 第五章：金属体系计算流程"
echo "============================================"
echo ""

# ---- 步骤 1: Al SCF ----
echo "[1/7] Al FCC SCF (Marzari-Vanderbilt smearing)..."
$PW_CMD < "$INPUT_DIR/al_scf.in" > "$OUTPUT_DIR/al_scf.out"
echo "  -> 完成。查看: $OUTPUT_DIR/al_scf.out"
echo ""

# ---- 步骤 2: Cu SCF (MV smearing) ----
echo "[2/7] Cu FCC SCF (Marzari-Vanderbilt smearing)..."
$PW_CMD < "$INPUT_DIR/cu_scf.in" > "$OUTPUT_DIR/cu_scf.out"
echo "  -> 完成。查看: $OUTPUT_DIR/cu_scf.out"
echo ""

# ---- 步骤 3: Cu SCF (Gaussian smearing) ----
echo "[3/7] Cu FCC SCF (Gaussian smearing — 对比用)..."
$PW_CMD < "$INPUT_DIR/cu_scf_gauss.in" > "$OUTPUT_DIR/cu_scf_gauss.out"
echo "  -> 完成。查看: $OUTPUT_DIR/cu_scf_gauss.out"
echo ""

# ---- 对比两种展宽方法 ----
echo "---- 展宽方法对比 ----"
echo "Cu (MV):"
grep "!" "$OUTPUT_DIR/cu_scf.out" || echo "  (未找到总能量)"
echo "Cu (Gaussian):"
grep "!" "$OUTPUT_DIR/cu_scf_gauss.out" || echo "  (未找到总能量)"
echo ""

# ---- 步骤 4: Al 能带计算 ----
echo "[4/7] Al 能带计算..."
$PW_CMD < "$INPUT_DIR/al_bands.in" > "$OUTPUT_DIR/al_bands.out"
echo "  -> 完成。查看: $OUTPUT_DIR/al_bands.out"
echo ""

# ---- 步骤 5: Cu 能带计算 ----
echo "[5/7] Cu 能带计算..."
$PW_CMD < "$INPUT_DIR/cu_bands.in" > "$OUTPUT_DIR/cu_bands.out"
echo "  -> 完成。查看: $OUTPUT_DIR/cu_bands.out"
echo ""

# ---- 步骤 6: Al bands.x 后处理 ----
echo "[6/7] Al bands.x 后处理..."
$BANDS_CMD < "$INPUT_DIR/al_bands.pp.in" > "$OUTPUT_DIR/al_bands.pp.out"
echo "  -> 能带数据: $OUTPUT_DIR/al_bands.dat"
echo ""

# ---- 步骤 7: Cu bands.x 后处理 ----
echo "[7/7] Cu bands.x 后处理..."
$BANDS_CMD < "$INPUT_DIR/cu_bands.pp.in" > "$OUTPUT_DIR/cu_bands.pp.out"
echo "  -> 能带数据: $OUTPUT_DIR/cu_bands.dat"
echo ""

echo "============================================"
echo " 所有计算完成！"
echo "============================================"
echo ""
echo "输出文件位于: $OUTPUT_DIR/"
echo ""
echo "能带数据可使用以下方式绘图："
echo "  - gnuplot: plot 'al_bands.dat' u 1:2 w l"
echo "  - python:  参见第九章 matplotlib 绘图脚本"
echo ""
echo "展宽方法对比（从输出中提取）："
echo "  grep '!  ' outputs/cu_scf.out"
echo "  grep '!  ' outputs/cu_scf_gauss.out"
