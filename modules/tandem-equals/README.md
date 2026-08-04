# TandemEquals™

**Human Intellect Modulator Simplex & Control Curve**

White and Red. Port 49223.

## The Four Layers

| Layer | Name | Function |
|-------|------|----------|
| 1 | **Perception** | Intake signals — sensory, data, emotional, environmental, temporal |
| 2 | **Cognition** | Pattern recognition — logic gates (AND, OR, XOR, THRESHOLD), inference, memory |
| 3 | **Modulation** | Calibration — gain, bias, filter, envelope, limiter, curve shaping |
| 4 | **Expression** | Output — speech, decision, creation, inhibition, signal relay |

## Control Curve

The simplex path traces from Layer 1 through to Layer 4. Each control curve maps one perception signal through a cognition pattern, applies modulator shaping, and produces an expression output.

```
Perception → Cognition → Modulation → Expression
   (L1)         (L2)         (L3)          (L4)
```

Simplex value = integrated signal strength across all four layers.
Stability = consistency of the curve over repeated evaluations.

## Database

`nwe_tandem_equals` — 6 tables:
- `perception` — raw intake signals
- `cognition` — pattern/logic layer
- `modulation` — gain/filter/envelope
- `expression` — output actuation
- `control_curve` — complete simplex paths
- `intellect_log` — immutable evaluation history

## TCP Protocol (Port 49223)

```
PERCEPTION          — list all signals
COGNITION           — list all patterns
MODULATION          — list all modulators
EXPRESSION          — list all outputs
CURVE               — list control curves
EVALUATE|<id>       — evaluate full simplex path
STATUS              — table counts
QUIT                — disconnect
```

## Deploy

```bash
bash modules/tandem-equals/servlets/setup-db.sh
sudo bash modules/tandem-equals/servlets/deploy-local.sh
```

## Author

Max Rupplin — MEARVK LLC
