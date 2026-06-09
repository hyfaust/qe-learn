#!/bin/bash
# ============================================================
#  Silicon 能带结构 & 态密度 完整计算流程
#  用法: cd scripts && bash bands_workflow.sh
# ============================================================
set -e

# --- 配置路径 ---
INPUT_DIR="../inputs"
PW_CMD="pw.x"
BANDS_CMD="bands.x"
DOS_CMD="dos.x"
PROJWFC_CMD="projwfc.x"

echo "============================================"
echo "  Step 1: SCF 自洽计算"
echo "============================================"
$PW_CMD < $INPUT_DIR/si_scf.in > si_scf.out
echo "  SCF 完成。费米能级已确定。"

echo ""
echo "============================================"
echo "  Step 2a: 能带计算 (calculation='bands')"
echo "============================================"
$PW_CMD < $INPUT_DIR/si_bands.in > si_bands.out
echo "  能带计算完成。"

echo ""
echo "============================================"
echo "  Step 2b: bands.x 后处理"
echo "============================================"
$BANDS_CMD < $INPUT_DIR/si_bands.pp.in > si_bands.pp.out
echo "  能带数据已提取到 si_bands.dat"

echo ""
echo "============================================"
echo "  Step 3a: DOS 计算 (calculation='nscf')"
echo "============================================"
$PW_CMD < $INPUT_DIR/si_dos.in > si_dos.out
echo "  NSCF (DOS) 计算完成。"

echo ""
echo "============================================"
echo "  Step 3b: dos.x 态密度后处理"
echo "============================================"
$DOS_CMD < $INPUT_DIR/si_dos.pp.in > si_dos.pp.out
echo "  DOS 数据已输出到 si_dos.dat"

echo ""
echo "============================================"
echo "  Step 3c: projwfc.x 投影态密度"
echo "============================================"
$PROJWFC_CMD < $INPUT_DIR/si_pdos.pp.in > si_pdos.pp.out
echo "  PDOS 数据已输出 (si_pdos.*)"

echo ""
echo "============================================"
echo "  计算全部完成！"
echo "============================================"
echo ""
echo "  输出文件："
echo "    能带数据:  si_bands.dat        (用 plotband.x 或 gnuplot 绘图)"
echo "    DOS 数据:  si_dos.dat          (能量 vs 态密度)"
echo "    PDOS 数据: si_pdos.*.dat       (各轨道投影态密度)"
echo ""
echo "  绘图示例 (plotband.x):"
echo "    输入: si_bands.dat, E_fermi 等信息"
echo "    输出: si_bands.ps (PostScript 能带图)"
