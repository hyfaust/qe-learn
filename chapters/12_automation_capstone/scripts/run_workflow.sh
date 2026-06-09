#!/usr/bin/env bash
# ============================================================
# run_workflow.sh — GaAs 完整表征工作流
#
# 步骤:
#   1. 结构优化 (relax)
#   2. 收敛测试 (ecutwfc)
#   3. 自洽计算 (SCF)
#   4. 能带计算 (bands)
#   5. 声子计算 (phonon)
#
# 用法:
#   bash run_workflow.sh
#   NP=8 bash run_workflow.sh   # 使用 8 个 MPI 进程
# ============================================================
set -euo pipefail

# ---------- 配置 ----------
NP=${NP:-4}                           # MPI 进程数
PW="mpirun -np $NP pw.x"             # pw.x 命令
PH="mpirun -np $NP ph.x"             # ph.x 命令
PP="/home/faust/pseudo"              # 赝势目录
INPUT_DIR="inputs"
OUTPUT_DIR="outputs"
TMP_DIR="tmp"

mkdir -p "$OUTPUT_DIR" "$TMP_DIR"

log() { echo ""; echo "=== [$(date +%H:%M:%S)] $* ==="; echo ""; }

# ---------- Step 1: 结构优化 ----------
log "Step 1/5: 结构优化 (relax)"
$PW -in "$INPUT_DIR/gaas_relax.in" > "$OUTPUT_DIR/gaas_relax.out"
echo "  结构优化完成。检查输出: $OUTPUT_DIR/gaas_relax.out"

# ---------- Step 2: 收敛测试 ----------
log "Step 2/5: 收敛测试 (ecutwfc)"
for ECUT in 20 30 40 50 60 70; do
    ECRHO=$((ECUT * 8))
    IN="$OUTPUT_DIR/conv_ecut${ECUT}.in"
    OUT="$OUTPUT_DIR/conv_ecut${ECUT}.out"

    cat > "$IN" <<EOF
&CONTROL
  calculation='scf', prefix='gaas_conv', outdir='./tmp',
  pseudo_dir='$PP', restart_mode='from_scratch'
/
&SYSTEM
  ibrav=2, celldm(1)=10.6917, nat=2, ntyp=2,
  ecutwfc=$ECUT, ecutrho=$ECRHO, nbnd=20
/
&ELECTRONS
  conv_thr=1.0d-8, mixing_beta=0.3
/
ATOMIC_SPECIES
Ga  69.723  Ga.pbe-dn-kjpaw_psl.1.0.0.UPF
As  74.922  As.pbe-n-kjpaw_psl.1.0.0.UPF
ATOMIC_POSITIONS crystal
Ga  0.00  0.00  0.00
As  0.25  0.25  0.25
K_POINTS automatic
6 6 6 0 0 0
EOF

    $PW -in "$IN" > "$OUT"
    ENERGY=$(grep "!" "$OUT" | tail -1 | awk '{print $5}')
    printf "  ecutwfc=%-4d  E = %s Ry\n" "$ECUT" "$ENERGY"
done

# ---------- Step 3: 自洽计算 ----------
log "Step 3/5: 自洽计算 (SCF)"
$PW -in "$INPUT_DIR/gaas_scf.in" > "$OUTPUT_DIR/gaas_scf.out"
echo "  SCF 完成。"

# ---------- Step 4: 能带计算 ----------
log "Step 4/5: 能带计算 (bands)"
$PW -in "$INPUT_DIR/gaas_bands.in" > "$OUTPUT_DIR/gaas_bands.out"
echo "  能带计算完成。使用 bands.x 提取能带数据。"

# ---------- Step 5: 声子计算（Gamma 点） ----------
log "Step 5/5: 声子计算 (phonon @ Gamma)"
cat > "$OUTPUT_DIR/gaas_ph.in" <<EOF
&INPUTPH
  prefix   = 'gaas'
  outdir   = './tmp'
  fildyn   = 'gaas.dyn'
  ldisp    = .false.
  nq1=2, nq2=2, nq3=2
/
0.0  0.0  0.0
EOF
$PH -in "$OUTPUT_DIR/gaas_ph.in" > "$OUTPUT_DIR/gaas_ph.out"
echo "  声子计算完成。"

# ---------- 完成 ----------
log "工作流全部完成！"
echo "输出文件在: $OUTPUT_DIR/"
echo ""
echo "后续步骤:"
echo "  - 用 parse_output.py 解析各步骤能量"
echo "  - 用 convergence_test.py --plot-only 绘制收敛曲线"
echo "  - 用 bands.x + plotband.x 绘制能带图"
echo "  - 用 dynmat.x 分析声子模式"
