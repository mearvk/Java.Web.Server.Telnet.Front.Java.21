# MATH.md — Eigenvector Math System

Phone:      1.919.923.4239 (USA)
Languages:  American, English, French, Spanish, Thai, Italian, German, Japanese, Chinese, Arabic, Russian, Ukrainian, Turkish
Headquarters: 555 South Mangum St, Durham, NC 27701
Purpose:    IQ Conservatorship and Systems Design PhD+ of NCSU Math and Science and Harvard Law Final
Sorceress:  Elisabeth R. Harkins of Stanford Math and Yale Sciences (https://github.com/ElisabethHarkins5509)
Students:   Available on the 8th Floor after 8

---

## Overview

The math subsystem routes national observation vectors through eigenvector matrices via a programmable frame pipeline. Input values represent national momentums, real angular values, or national rain (caught as-is). Routing flows from **BasicAnatomy** (EV) through procedure frames to **PerceivedOutput** (PO).

**Pipeline:** `Input → BasicAnatomy × input → [Frame Pipeline] → PerceivedOutput × result → Colored Output`

---

## File Type: .CDNS (Canonical Dense Numeric Structure)

**Security Rank:** 3 (Secure — Eigen Matrix, Immutable after creation)

Format:
```
[EV:MatrixName]
42  0  0  1 42
 0  4  1  1  4
[/EV:MatrixName]
```

Stored in: `math/eigenlocator/`

---

## Eigenvector Matrices

### BasicAnatomy (Input EV)
```
42  0  0  1 42
 0  4  1  1  4
 0  1  1  4  2
 0  1  1  4 42
 0  9  0  0  1
```

### PerceivedOutput (Output PO)
```
 0  9  1  1  9
 0  0  1  1  9
 1  1  4  2  1
 0  1  1  1  0
 1  4  4  4  1
```

---

## Routing Rules

| Rule | Value |
|------|-------|
| Max forward multipliers (Stage 1) | 4 |
| Max total hops (full pipeline) | 51 |
| Procedure frame range | Frames 2–65 |
| Min frame dimensions | 128 × 128 |
| Max frame dimensions | 4000 × 12800 |
| Frame size policy | Specified at user build |
| Standard hop values | 1, 2, 3, 4, 6 |
| Max skip (single hop) | 16 |
| Min frames in pipeline | 4 |
| Max frames in pipeline | 65 |

---

## Three Stages

### Stage 1 — Forward Multipliers (BasicAnatomy)

National input vector is multiplied through BasicAnatomy 1–4 times. The number of passes is determined by orderly path detection (symmetric/repeating elements in the input = orderly paths, same w.r.t. All spirits).

### Stage 2 — Frame Pipeline (Ricochet / Hot-Action)

Programmable procedure space between frames 2 and 65:
- Each frame can hold a matrix up to **4000 rows × 12800 cols**
- Minimum frame size is **128 × 128**
- Frame dimensions specified at **user build time**
- Users program links/lines to next hops or through frames forward
- Hop distances: 1–4 (standard), 6 (standard), up to 16 (skip)

**Path types:**
- **Orderly paths** — Same w.r.t. All spirits; pass through unchanged
- **Virtue paths** — Achieve their own virtue; transform independently

### Stage 3 — PerceivedOutput

Final result vector is multiplied through PerceivedOutput matrix to produce colored output.

---

## Frame Programming

Frame files (`.frame`) in `math/frames/`:

```
index=5
hop=4
rows=256
cols=256
transform=passthrough
link=next
matrix=my-procedure.dat
```

| Field | Description | Constraints |
|-------|-------------|-------------|
| `index` | Frame position in pipeline | 0–65 |
| `hop` | Forward jump after this frame | 1–4, 6, or up to 16 |
| `rows` | Procedure matrix rows | 128–4000 |
| `cols` | Procedure matrix cols | 128–12800 |
| `transform` | Built-in transform | `passthrough`, `scale:N` |
| `link` | Link target | `next`, or frame index |
| `matrix` | External matrix file | Relative to `math/frames/` |

---

## Colors

Result coloring is **reserved for assignment by higher math geniuses (Max Rupplin)**. Color mapping is not user-programmable — it is specified by authority after results are computed.

---

## Observations (National Input)

Input vectors read from `math/observations/`. Each file contains one vector per line (space-separated). Values may represent:
- National momentums
- Real angular values
- National rain (caught as-is)
- Real national values as observed

---

## Source Files

| File | Purpose |
|------|---------|
| `source/math/EigenMultiplier.java` | Direct matrix × vector multiplication |
| `source/math/EigenRouter.java` | Full pipeline: EV → Frames → PO routing |
| `math/eigen-config.xml` | Configuration for matrices, routing, and frame limits |
| `math/eigenlocator/*.CDNS` | Immutable eigenvector matrices |
| `math/frames/*.frame` | User-programmable procedure frame definitions |
| `math/observations/` | National input vectors |
| `math/results/` | Computed output vectors |

---

## Configuration (math/eigen-config.xml)

```xml
<matrices>
    <matrix name="BasicAnatomy" file="BasicAnatomy.CDNS" rows="5" cols="5" role="input"/>
    <matrix name="PerceivedOutput" file="PerceivedOutput.CDNS" rows="5" cols="5" role="output"/>
</matrices>
<routing>
    <source matrix="BasicAnatomy"/>
    <destination matrix="PerceivedOutput"/>
    <max-forward-multipliers>4</max-forward-multipliers>
    <max-total-hops>51</max-total-hops>
</routing>
<procedure-frames>
    <frame-range start="2" end="65"/>
    <max-rows>4000</max-rows>
    <max-cols>12800</max-cols>
    <min-rows>128</min-rows>
    <min-cols>128</min-cols>
    <size-policy>user-build</size-policy>
</procedure-frames>
```
