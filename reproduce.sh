#!/bin/bash
# Pulsar2 5.2 bug 再現スクリプト
# 想定: このディレクトリをそのまま /data として docker にマウント
#
# 使い方:
#   chmod +x reproduce.sh
#   ./reproduce.sh                  # メイン: dtype assertion error
#   ./reproduce.sh fuse             # 2 つ目: fuse_computing_passive_linear IndexError

set -e
cd "$(dirname "$0")"

PULSAR2_IMAGE="${PULSAR2_IMAGE:-pulsar2:5.2}"
MODE="${1:-dtype}"

case "$MODE" in
  dtype)
    CFG="config_npu_dp_u16.json"
    echo "[main] Reproducing dtype assertion bug (insert_dequantize_linear_between_var_and_op)"
    ;;
  fuse)
    CFG="config_npu_dp_u16_fuse_error.json"
    echo "[variant] Reproducing fuse_computing_passive_linear IndexError"
    ;;
  *)
    echo "usage: $0 [dtype|fuse]"
    exit 1
    ;;
esac

LOG="$(basename "$CFG" .json).log"

echo "----------------------------------------"
echo "image : $PULSAR2_IMAGE"
echo "config: $CFG"
echo "log   : $LOG"
echo "----------------------------------------"

docker run --rm \
  -v "$PWD":/data \
  -w /data \
  --entrypoint pulsar2 \
  "$PULSAR2_IMAGE" \
  build --config "/data/$CFG" 2>&1 | tee "$LOG"

EXIT=${PIPESTATUS[0]}
echo "----------------------------------------"
echo "exit=$EXIT"
echo
echo "=== Key error excerpt ==="
case "$MODE" in
  dtype)
    grep -B 2 -A 1 "expect_type\|AssertionError" "$LOG" | tail -10 || true
    ;;
  fuse)
    grep -B 2 -A 1 "fuse_computing_passive_linear\|IndexError" "$LOG" | tail -10 || true
    ;;
esac
echo "----------------------------------------"

if [ "$EXIT" = "0" ]; then
  echo "axmodel was produced — bug appears fixed in this image!"
  exit 0
else
  echo "axmodel was NOT produced — bug reproduced as expected."
  exit "$EXIT"
fi
