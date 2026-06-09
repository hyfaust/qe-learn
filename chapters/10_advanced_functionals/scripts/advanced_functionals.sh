#!/bin/bash
###############################################################################
# advanced_functionals.sh — 第十章：高级泛函与电子关联修正 计算流程
#
# 用法: bash scripts/advanced_functionals.sh [pw.x路径] [hp.x路径]
#
# 计算内容:
#   1. NiO 反铁磁 DFT+U 自洽计算
#   2. hp.x 线性响应计算 Hubbard U 参数
#   3. 石墨烯（石墨）DFT-D3 层间距优化
#   4. Si HSE06 杂化泛函 SCF
#   5. H2O 分子 DFT-D3 色散修正
#
# 参考: QE PW/examples/example08/, dftd3_example/, EXX_example/
#       QE HP/examples/example02/
###############################################################################

set -e

PW=${1:-pw.x}
HP=${2:-hp.x}
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INPUT_DIR="$(cd "$SCRIPT_DIR/../inputs" && pwd)"
OUTPUT_DIR="$SCRIPT_DIR/../results"
PSEUDO_DIR="$INPUT_DIR/../pseudo"
mkdir -p "$OUTPUT_DIR"

echo "============================================================"
echo "  第十章：高级泛函与电子关联修正"
echo "============================================================"
echo "  pw.x:       $PW"
echo "  hp.x:       $HP"
echo "  输入目录:    $INPUT_DIR"
echo "  输出目录:    $OUTPUT_DIR"
echo "  赘势目录:    $PSEUDO_DIR"
echo "============================================================"
echo ""

###############################################################################
# 1. NiO DFT+U 自洽计算
###############################################################################
echo ">>> [1/5] NiO 反铁磁 DFT+U SCF 计算 ..."
echo "    参数: lda_plus_u=.true., Hubbard_U(Ni)=5.0 eV, nspin=2"
$PW < "$INPUT_DIR/nio_dftu_scf.in" > "$OUTPUT_DIR/nio_dftu_scf.out" 2>&1
echo "    完成。输出: $OUTPUT_DIR/nio_dftu_scf.out"
grep -e '!' "$OUTPUT_DIR/nio_dftu_scf.out" | tail -1
echo ""

###############################################################################
# 2. hp.x 线性响应计算 Hubbard U
#    注意: 运行 hp.x 前，需先用极小的 Hubbard_U (1.d-8) 重新运行 SCF
#    这里假设 nio_dftu_scf.in 已使用极小 U 值
###############################################################################
echo ">>> [2/5] hp.x 线性响应计算 Hubbard U 参数 ..."
echo "    注意: hp.x 需要以极小 Hubbard_U 的 SCF 结果为输入"
echo "    如需正式计算，请先将 nio_dftu_scf.in 中的 Hubbard_U 改为 1.d-8"
$HP < "$INPUT_DIR/nio_hp.in" > "$OUTPUT_DIR/nio_hp.out" 2>&1
echo "    完成。输出: $OUTPUT_DIR/nio_hp.out"
echo "    提取 Hubbard U 值:"
grep -i 'Hubbard' "$OUTPUT_DIR/nio_hp.out" | head -5 || echo "    (请检查输出文件)"
echo ""

###############################################################################
# 3. 石墨烯 DFT-D3 层间距优化
###############################################################################
echo ">>> [3/5] 石墨烯 vdW-D3 层间距优化 ..."
echo "    参数: vdw_corr='dft-d3', vc-relax (cell_dofree='z')"
$PW < "$INPUT_DIR/graphene_vdw.in" > "$OUTPUT_DIR/graphene_vdw.out" 2>&1
echo "    完成。输出: $OUTPUT_DIR/graphene_vdw.out"
grep -e '!' "$OUTPUT_DIR/graphene_vdw.out" | tail -1
# 提取最终晶格参数
grep -A1 'CELL_PARAMETERS' "$OUTPUT_DIR/graphene_vdw.out" | tail -4 || true
echo ""

###############################################################################
# 4. Si HSE06 杂化泛函 SCF
###############################################################################
echo ">>> [4/5] Si HSE06 杂化泛函 SCF ..."
echo "    参数: input_dft='hse', nqx=2, exx_fraction=0.25"
echo "    注意: 杂化泛函计算较慢，请耐心等待"
$PW < "$INPUT_DIR/si_hse_scf.in" > "$OUTPUT_DIR/si_hse_scf.out" 2>&1
echo "    完成。输出: $OUTPUT_DIR/si_hse_scf.out"
grep -e '!' "$OUTPUT_DIR/si_hse_scf.out" | tail -1
echo ""

###############################################################################
# 5. H2O 分子 DFT-D3 色散修正
###############################################################################
echo ">>> [5/5] H2O 分子 DFT-D3 色散修正 ..."
echo "    参数: vdw_corr='dft-d3'"
$PW < "$INPUT_DIR/h2o_dftd3.in" > "$OUTPUT_DIR/h2o_dftd3.out" 2>&1
echo "    完成。输出: $OUTPUT_DIR/h2o_dftd3.out"
grep -e '!' "$OUTPUT_DIR/h2o_dftd3.out" | tail -1
echo ""

echo "============================================================"
echo "  全部计算完成！"
echo "  结果保存在: $OUTPUT_DIR"
echo "============================================================"
echo ""
echo "  提示: 查看各方法的色散能量贡献，可在输出文件中搜索"
echo "    'DFT-D3' 或 'Dispersion' 关键字"
echo ""
