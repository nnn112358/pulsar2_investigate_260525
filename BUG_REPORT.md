# Pulsar2 5.2 — `pulsar2 build` failure on VITS duration-predictor sub-graph

## Symptom

`pulsar2 build` aborts during the quantization stage and produces no `.axmodel`.
The failure occurs on a Variable named after `/dp/flows.5/Split_output_1`, the second of three structurally identical `ConvFlow` blocks in the input model.

Two distinct error messages are observed depending on `onnx_opt.enable_onnxsim`:

### Variant A — `enable_onnxsim: false`

```
AssertionError:
  DequantizeLinearOp_link_to_1_/dp/flows.5/Split_output_1_link_var
  But var.dtype = <DataType.UINT16: 4> vs expect_type = <DataType.FP32: 1>

→ yamain.common.error.CodeException: (<ErrorCode.QuantError: 3>, ...)
```

### Variant B — `enable_onnxsim: true` (default)

```
IndexError: list index out of range
→ yamain.common.error.CodeException: (<ErrorCode.QuantError: 3>, ...)
```

## Environment

| Field | Value |
|---|---|
| Image | `pulsar2:5.2` |
| Host OS | Linux 6.17.0-22-generic |
| Target | `AX620E`, `npu_mode: NPU2` |
| Quantization | `U16`, `MinMax` |

## Reproduction

Unpack and run:

```bash
tar xzf bug_report_pulsar2_5.2_dp_dtype.tar.gz
cd bug_report_pkg
./reproduce.sh           # variant A
./reproduce.sh fuse      # variant B
```

Or manually:

```bash
docker run --rm -v "$PWD":/data -w /data --entrypoint pulsar2 pulsar2:5.2 \
    build --config /data/config_npu_dp_u16.json
```

### Bundle contents

```
bug_report_pkg/
├── BUG_REPORT.md                        (this file)
├── reproduce.sh                         one-shot docker invocation
├── dp.onnx                              3.4 MB, FP32, opset 15, fixed shapes
├── config_npu_dp_u16.json               variant A
├── config_npu_dp_u16_fuse_error.json    variant B
├── dp_u16_dtype_error.log               full pulsar2 traceback for variant A
└── calibration/
    ├── dp_x.tar
    ├── dp_x_mask.tar
    ├── dp_g.tar
    ├── dp_prosody_features.tar
    └── dp_lid.tar
```

### Input model shape

- `x [1, 192, 256] float32`
- `x_mask [1, 1, 256] float32`
- `g [1, 512, 1] float32`
- `prosody_features [1, 256, 3] int64`
- `lid [1] int64`
- Output: `logw [1, 1, 256] float32`

Calibration values are synthetic; the failure is structural and does not depend on calibration content.
