# GEMTOO: Memory Block Calculation Documentation

## Overview

**GEMTOO** (Gain-Cell Embedded DRAM Modeling Tool) is a MATLAB-based analytical model for estimating the performance of Gain-Cell embedded DRAMs (GC-eDRAMs). It models a **3-transistor all-NMOS gain cell (3T-N)** in advanced CMOS technology (e.g., 28 nm FD-SOI).

### What GEMTOO Calculates

| Output | File | Description |
|--------|------|-------------|
| Timing / Latency | `eval_timing.m` | Delays on all four signal paths; maximum frequency |
| Area | `eval_area.m` | Physical dimensions, area efficiency, memory density |
| Availability | `eval_availbw.m` | Fraction of time not spent on refresh [%] |
| Bandwidth | `eval_availbw.m` | Effective throughput [bit/s] |

> **Important**: GEMTOO does **not** calculate energy, dynamic power, or leakage current. Refresh period and data retention time are treated as pre-characterized inputs (derived from circuit-level SPICE simulations), not computed analytically within GEMTOO.

### Top-Level Call Sequence (`gemtoo.m`)

```matlab
% 1. Apply architectural transformations (partitioning and folding)
n_word = n_word / 2^(n_partitioning_wl + n_folding_wl);
n_rows = n_rows / 2^(n_partitioning_bl + n_folding_bl);

% 2. Evaluate all metrics in sequence
my_gcedram_out = eval_timing(my_gcedram_in, my_gcedram_out);   % latency
my_gcedram_out = eval_area(my_gcedram_in, my_gcedram_out);     % area
my_gcedram_out = eval_availbw(my_gcedram_in, my_gcedram_out);  % availability + bandwidth
```

The original `n_word` and `n_rows` (monolithic) are divided by the transformation factors before being passed to the sub-functions. However, `eval_area` and `eval_availbw` re-expand via the `2^(sum of factors)` multipliers to recover total bit counts.

---

## Architectural Transformations: Partitioning and Folding

Before any metric is evaluated, the monolithic array is logically subdivided via two types of transformations. Each factor is a non-negative integer `n`, and the transformation multiplies/divides by `2^n`.

### Partitioning (Physical Cuts)

| Parameter | Direction | Effect |
|-----------|-----------|--------|
| `n_partitioning_bl` | Horizontal (BL cut) | Divides rows by `2^n`; creates multiple sub-arrays stacked vertically |
| `n_partitioning_wl` | Vertical (WL cut) | Divides columns by `2^n`; creates multiple sub-arrays side by side |

Partitioning shortens word lines or bit lines, reducing RC delay. It requires a global address decoder tree and RBL multiplexing logic.

### Folding (Logical Multiplexing)

| Parameter | Direction | Effect |
|-----------|-----------|--------|
| `n_folding_bl` | BL (horizontal array cut) | Reduces row count per sub-array; multiple GC rows share address decode |
| `n_folding_wl` | WL (vertical array cut) | Reduces column count per sub-array; multiple GC columns share address decode |

Folding reduces the decoder complexity at the cost of adding mux delay in the RBL path.

---

## 1. Latency (Timing) — `eval_timing.m`

### Fundamental Delay Model

All RC delays in GEMTOO are computed using the exponential charging model. For a first-order RC circuit charged toward a final voltage, the time to reach a threshold `h` (expressed as a fraction of the final voltage, 0 < h < 1) is:

```
t = -tau * ln(1 - h)
```

Where `tau = R * C` is the RC time constant. This is derived from `V(t) = V_final * (1 - exp(-t/tau))`.

For distributed RC lines with `n` uniform loads, the effective time constant is:

```
tau_distributed = R_wire * (n+1)*n/2 * C_per_node
```

This is the standard Elmore delay formula for a uniform RC ladder.

### Wire Parasitics

Computed once per call from per-unit-length technology parameters and cell geometry:

```
c_wire_hor = gc_width  * c_wire_hor_per_m    % capacitance of one WL wire segment [F]
r_wire_hor = gc_width  * r_wire_hor_per_m    % resistance of one WL wire segment [ohm]
c_wire_ver = gc_height * c_wire_ver_per_m    % capacitance of one BL wire segment [F]
r_wire_ver = gc_height * r_wire_ver_per_m    % resistance of one BL wire segment [ohm]
```

---

### 1a. Write Word Line Delay (twwl)

The WWL path activates the write transistor in the selected gain cell row.

**RC time constants:**

```
c_wwl_cell = c_wire_hor + c_wwl                  % capacitance per cell on WWL [F]

tau_wwl_buffer = r_wwl_buffer * (c_wwl_buffer + n_word * c_wwl_cell)
% Buffer driving all n_word cells in parallel

tau_wwl_cells = r_wire_hor * (n_word+1)*n_word/2 * c_wwl_cell
% Distributed RC along the word line (Elmore delay)

tau_wwl = tau_wwl_buffer + tau_wwl_cells
```

**Local WWL buffer delay:**
```
t_wwl_buffer = -tau_wwl * ln(1 - h_wwl)
```

**Global address wire (used only when partitioning_wl or folding_bl > 0):**

The global address wire distributes the row address to multiple array partitions. Two cases:

- `globadr_buff = 0` (no repeaters): wire length = `n_word * gc_width * (2^(n_partitioning_wl + n_folding_bl) - 1)`
- `globadr_buff = 1` (repeaters every sub-array): wire length = `n_word * gc_width`, RC scaled by `(2^(...) - 1)`

```
tau_wl_globadr_boost = r_globadr_boost_buffer * (c_globadr_boost_buffer + c_wl_globadr)
                       + r_wl_globadr * c_wl_globadr

t_wwl_globadr = t_inv_boost_fo1 + (-tau_wl_globadr_boost * ln(0.5)) + t_and_boost_fo1
              % (= 0 if no partitioning/folding)
```

Boosted-voltage gates (higher supply) are used on the WWL global path for margin.

**Total WWL delay:**
```
twwl = t_ff + tdec + t_ls + t_wwl_globadr + t_inv_boost_fo1 + t_wwl_buffer
```

| Term | Physical meaning |
|------|-----------------|
| `t_ff` | Address register (flip-flop) delay |
| `tdec` | Row decoder delay (see Section 1e) |
| `t_ls` | Level shifter (voltage domain crossing for boosted WWL) |
| `t_wwl_globadr` | Global address routing to partitions (0 if monolithic) |
| `t_inv_boost_fo1` | Boosted inverter driving local buffer |
| `t_wwl_buffer` | Local WWL buffer + distributed RC across all cells |

---

### 1b. Write Bit Line Delay (twbl)

The WBL path delivers write data to the storage node of the selected gain cell.

**RC time constants:**

```
c_wbl_cell = c_wire_ver + c_wbl                   % capacitance per cell on WBL [F]

tau_wbl_buffer = r_wbl_buffer * (c_wbl_buffer + n_rows * c_wbl_cell + c_sn)
% Buffer driving all cells in the column plus the storage node

tau_wbl_cells = r_wire_ver * ((n_rows+1)*n_rows/2 * c_wbl_cell + n_rows * c_sn)
% Distributed RC: wire + storage node caps distributed along column

tau_wbl_sn = r_wwl_on * c_sn
% Access transistor resistance charging storage node

tau_wbl = tau_wbl_buffer + tau_wbl_cells + tau_wbl_sn
```

**Total WBL buffer delay:**
```
t_wbl_buffer = -tau_wbl * ln(1 - h_wbl)
```

**Total WBL delay:**
```
twbl = t_ff + t_inv_fo1 + t_wbl_buffer
```

WBL is simpler than WWL: no global routing and no level shifter, since the write bit line operates within a single sub-array.

---

### 1c. Read Word Line Delay (trwl)

The RWL path activates the read transistor gate in the selected row.

**RC time constants:**

```
c_rwl_cell = c_wire_hor + c_rwl

tau_rwl_buffer = r_rwl_buffer * (c_rwl_buffer + n_word * c_rwl_cell)
tau_rwl_cells  = r_wire_hor   * (n_word+1)*n_word/2 * c_rwl_cell
tau_rwl        = tau_rwl_buffer + tau_rwl_cells
```

**Local RWL buffer delay:**
```
t_rwl_buffer = -tau_rwl * ln(1 - h_rwl)
```

**Global RWL address wire (used only when partitioning_wl or folding_bl > 0):**

```
t_rwl_globadr = t_inv_fo1 + (-tau_wl_globadr * ln(0.5)) + t_and_fo1
              % (= 0 if no partitioning/folding)
```

Standard (non-boosted) gates are used on the RWL path, unlike WWL.

**Total RWL delay:**
```
trwl = t_ff + tdec + t_rwl_globadr + t_inv_fo1 + t_rwl_buffer
```

---

### 1d. Read Bit Line Delay (trbl)

The RBL path carries the charge from the storage node to the sense amplifier.

**RBL ON-resistance selection:**

The read transistor's ON-resistance depends on how degraded the storage node voltage has become (lower SN voltage → weaker drive → higher resistance). The correct `r_rbl_on` is selected by index lookup:

```
% VSN mode: select based on acceptable voltage degradation
i_rbl_on = find((sn_degradation >= sn_degr_vect), 1, 'last')

% ref_period mode: select based on refresh period vs retention time
i_rbl_on = find((ref_period <= tret_vect), 1, 'first')

r_rbl_on = r_rbl_on_vect(i_rbl_on)
```

**RC time constants:**

```
c_rbl_cell = c_wire_ver + c_rbl

tau_rbl_on    = r_rbl_on * (c_rbl + (n_rows-1)*c_rbl_cell + (c_wire_ver + c_sa))
% Selected GC drives: its own RBL cap + all other cells on line + wire to SA + SA cap

tau_rbl_cells = r_wire_ver * (n_rows*(n_rows-1)/2 * c_rbl_cell + (n_rows-1)*(c_wire_ver + c_sa))
% Distributed RC: other cells and SA-wire along the bit line

tau_sa        = r_wire_ver * (c_wire_ver + c_sa)
% Last segment: wire from bit line to sense amplifier

tau_rbl = tau_rbl_on + tau_rbl_cells + tau_sa
```

**GC-to-RBL charging delay:**
```
t_gc_rbl = -tau_rbl * ln(1 - h_rbl)
```

**RBL mux delay** (0 if no partitioning/folding; see Sections 1f and 1g):
```
t_mux = eval_timing_rblmuxtree(...)     % if rblmux_topology == 'tree'
t_mux = eval_timing_rblmuxtristate(...) % if rblmux_topology == 'tristate'
```

**Total RBL delay:**
```
trbl = t_gc_rbl + t_sa + t_mux
```

---

### 1e. Row Decoder Delay — `eval_timing_rowdecoder.m`

The row decoder converts `log2(n_rows)` address bits into a one-hot row select signal. It is implemented as a tree of AND gates.

**Decoder depth:**
```
bits_adr = log2(n_rows)          % number of address bits
dec_depth = ceil(log2(bits_adr)) % number of AND gate stages
```

Examples: 256 rows → 8-bit address → `dec_depth = 3`.

#### 2-Stage Decoder (dec_depth = 2, e.g., 8–16 rows)

**Without stage-2 RC buffer (`dec_intconbuff_2 = 0`):**
```
tdec = 2*t_inv_fo2 + t_and_fo4 + t_and_fo1 + t_and_fo1
```

**With stage-2 RC buffer (`dec_intconbuff_2 = 1`):**
```
n_wire_2 = 8 + (16-8)/2 = 12     % interpolated number of intermediate wires
tau_rc_buff_2 = r_dec_buffer_2 * (c_dec_buffer_2 + n_wire_2*c_wire_ver + 4*c_and)
              + r_wire_ver * ((n_wire_2+1)*n_wire_2/2 * c_wire_ver + n_wire_2*4*c_and)
t_rc_buff_2 = t_inv_fo1 + (-tau_rc_buff_2 * ln(0.5))
tdec = 2*t_inv_fo2 + t_and_fo1 + t_rc_buff_2 + t_and_fo1 + t_and_fo1
```

#### 3-Stage Decoder (dec_depth = 3, e.g., 32–256 rows)

Four buffering configurations are supported:

| `dec_intconbuff_2` | `dec_intconbuff_3` | Stage 2 gate | Stage 3 gate |
|--------------------|--------------------|----|---|
| 0 | 0 | `t_and_fo16` | `t_and_fo1` |
| 1 | 0 | `t_rc_buff_2 + t_and_fo16` | `t_and_fo1` |
| 0 | 1 | `t_and_fo1` | `t_rc_buff_3 + t_and_fo1` |
| 1 | 1 | `t_rc_buff_2 + t_and_fo16` | `t_rc_buff_3 + t_and_fo1` |

Stage 3 RC buffer uses `n_wire_3 = 32 + (256-32)/2 = 144` wires and drives 16 AND gate inputs per wire:

```
tau_rc_buff_3 = r_dec_buffer_3 * (c_dec_buffer_3 + 144*c_wire_ver + 16*c_and)
              + r_wire_ver * ((144+1)*144/2 * c_wire_ver + 144*16*c_and)
t_rc_buff_3 = t_inv_fo1 + (-tau_rc_buff_3 * ln(0.5))
```

---

### 1f. RBL Mux Delay — Tree Topology (`eval_timing_rblmuxtree.m`)

The NAND-tree RBL mux is the preferred topology. It uses cascaded 2-to-1 muxes.

**2-to-1 mux unit delay:**
```
t_nand_fo1   = t_and_fo1 - t_inv_fo1   % NAND gate delay approximation
t_mux_2to1   = 2 * t_nand_fo1           % 2 NAND stages per 2:1 mux
```

**Horizontal RC buffer (needed for BL folding — routes selected signal across array width):**
```
d_array_width    = gc_width * n_word
tau_array_width  = r_rwl_buffer * (c_rwl_buffer + c_wire_hor_per_m*d_array_width)
                 + (r_wire_hor_per_m*d_array_width) * (c_wire_hor_per_m*d_array_width)
t_rcbuff_hor     = -tau_array_width * ln(0.5)
```

**Vertical RC buffer (needed for BL partitioning — routes selected signal across array height):**
```
d_array_height   = gc_height * n_rows
tau_array_height = r_wbl_buffer * (c_wbl_buffer + c_wire_ver_per_m*d_array_height)
                 + (r_wire_ver_per_m*d_array_height) * (c_wire_ver_per_m*d_array_height)
t_rcbuff_ver     = -tau_array_height * ln(0.5)
```

**Total mux delays:**
```
t_mux_hor = n_folding_bl * t_mux_2to1
            + 2^(n_folding_bl - 1) * t_rcbuff_hor
% n_folding_bl levels of 2:1 muxes, with RC buffers at tree nodes

t_mux_ver = n_partitioning_bl * t_mux_2to1
            + (2^(n_partitioning_bl + n_folding_wl - 1) - 1) * t_rcbuff_ver
% n_partitioning_bl levels of 2:1 muxes, with RC buffers

t_mux = t_mux_hor + t_mux_ver    % (0 if no partitioning or folding)
```

---

### 1g. RBL Mux Delay — Tristate Topology (`eval_timing_rblmuxtristate.m`)

The tristate topology uses shared-bus tristate buffers. Suitable only for small memories (the shared output capacitance grows with array size).

**Wire lengths (lumped model):**
```
% Vertical wire (from horizontal cuts / partitioning_bl + folding_wl)
length_mux_wire_ver = (gc_height * n_rows) * (2^(n_partitioning_bl + n_folding_wl) - 2)

% Horizontal wire (from vertical cuts / folding_bl)
length_mux_wire_hor = (gc_width * n_word) * (2^n_folding_bl - 1)

% If both cuts exist, each direction is scaled by the other:
length_mux_wire_ver *= 2^n_folding_bl
length_mux_wire_hor *= 2^(n_partitioning_bl + n_folding_wl - 1)
```

**Lumped RC model:**
```
r_mux_wire = r_wire_hor_per_m * length_mux_wire_hor
           + r_wire_ver_per_m * length_mux_wire_ver
c_mux_wire = c_wire_hor_per_m * length_mux_wire_hor
           + c_wire_ver_per_m * length_mux_wire_ver

tau_mux = r_mux_buffer * (c_mux_buffer + c_mux_wire) + r_mux_wire * c_mux_wire
```

**Total tristate mux delay:**
```
t_mux = t_inv_fo1 + (-tau_mux * ln(0.5))
      % (0 if no partitioning or folding)
```

---

### 1h. Maximum Operating Frequency

```
twrite = max(twwl, twbl)         % write limited by slower of WWL or WBL
tread  = trwl + trbl             % read is serial: RWL then RBL
tmin   = max(twrite, tread)      % critical path
fmax   = 1 / tmin                % [Hz]
```

Write operations drive WWL and WBL in parallel, so the worst case is taken.
Read operations are serial: the word line must activate before the bit line can be sensed.

---

## 2. Area — `eval_area.m`

### GC Array Dimensions

```
gcarray_width  = gc_width  * n_word    % [m]
gcarray_height = gc_height * n_rows    % [m]
```

### Row Decoder Width

```
bits_adr  = log2(n_rows)
dec_depth = ceil(log2(bits_adr))
d_dec     = dec_depth * d_and
% Add interconnect buffers if present:
%   dec_depth == 3:  d_dec += (dec_intconbuff_2 + dec_intconbuff_3) * d_dec_intconbuff
%   dec_depth == 2:  d_dec += dec_intconbuff_2 * d_dec_intconbuff
```

### Baseline Memory Dimensions (no partitioning or folding)

```
d_width  = gcarray_width  + (d_ff + d_dec + d_ls + d_wwl_buffer)  % left (WWL side)
                           + (d_ff + d_dec + d_rwl_buffer)         % right (RWL side)

d_height = gcarray_height + (d_ff + d_wbl_buffer)                  % bottom (WBL side)
                           + d_sa                                   % top (sense amplifier)
```

**Peripheral dimension variables:**

| Variable | Component |
|----------|-----------|
| `d_ff` | Flip-flop (address register) |
| `d_dec` | Row decoder (AND tree + optional RC buffers) |
| `d_ls` | Level shifter (WWL voltage domain) |
| `d_wwl_buffer` | Local WWL driver |
| `d_rwl_buffer` | Local RWL driver |
| `d_wbl_buffer` | Local WBL driver |
| `d_sa` | Read bit-line sense amplifier |
| `d_mux_buffer` | RBL mux buffer (added only when BL partitioning/folding > 0) |
| `d_globadr_buffer` | Global RWL address buffer |
| `d_globadr_boost_buffer` | Boosted global WWL address buffer |
| `d_dec_intconbuff` | Decoder interconnect buffer |

### Effect of Partitioning and Folding

The following sequence is applied when any transformation factor > 0:

**Step 1** — If WL partitioning or BL folding (`n_partitioning_wl + n_folding_bl > 0`): remove local decoders and level shifter (they become global):
```
d_width -= (2*d_dec + d_ls)
```

**Step 2** — If `globadr_buff = 1`: add local address repeaters back:
```
d_width += d_wwl_buffer + d_rwl_buffer
```

**Step 3** — If BL partitioning or folding (`n_partitioning_bl + n_folding_bl > 0`): add RBL mux buffer to height:
```
d_height += d_mux_buffer
```

**Step 4** — Scale by transformation factors:
```
d_width  *= 2^(n_partitioning_wl + n_folding_bl)
d_height *= 2^(n_partitioning_bl  + n_folding_wl)
```

**Step 5** — If WL partitioning or BL folding: re-add centralized decoder, level shifter, and global address buffers:
```
d_width += (2*d_dec + d_ls) + (d_globadr_buffer + d_globadr_boost_buffer)
```

### Area Efficiency and Memory Density

```
bitcell_number = 2^(n_partitioning_bl + n_partitioning_wl + n_folding_bl + n_folding_wl)
                 * (n_word * n_rows)

area_bitcells  = 2^(n_partitioning_bl + n_partitioning_wl + n_folding_bl + n_folding_wl)
                 * (gcarray_width * gcarray_height)

area_tot = d_width * d_height

area_efficiency = (area_bitcells / area_tot) * 100    % [%]
memory_density  = bitcell_number / area_tot            % [bit/m^2]
```

The factors `2^(sum of all transformation factors)` restore the original total bit count since `gemtoo.m` divides `n_word` and `n_rows` before calling `eval_area`.

---

## 3. Availability and Bandwidth — `eval_availbw.m`

### Refresh Period Determination

Two modes are supported:

**Mode `'vsn'`** (storage-node voltage degradation):
```
i_tret     = find((sn_degradation >= sn_degr_vect), 1, 'last')
ref_period = tret_vect(i_tret)
% Looks up the retention time corresponding to the worst-case SN degradation level
```

**Mode `'ref_period'`** (fixed refresh period):
```
% ref_period is used directly as specified in gcedram_in
```

### Stall Time

```
tstall = n_rows / fmax
```

All `n_rows` rows must be refreshed sequentially; each row takes one clock cycle at `fmax`.
Note: `n_rows` here is already the post-transformation (per sub-array) row count.

### Memory Availability

```
avail = (1 - tstall / ref_period) * 100    % [%]
```

A fraction `tstall / ref_period` of time is consumed by refresh. The remainder is available for normal read/write operations.

**Example**: With `n_rows = 256`, `fmax = 500 MHz`, and `ref_period = 3 µs`:
- `tstall = 256 / 500e6 = 512 ns`
- `avail = (1 - 512e-9 / 3e-6) * 100 = 82.9%`

### Bandwidth

```
bw = n_word * fmax * (avail / 100)    % [bit/s]
```

Peak bandwidth (`n_word * fmax`) is derated by the availability factor to give effective throughput.

---

## 4. Input Parameters — `gcedram_in.m`

### Architecture

| Parameter | Unit | Description |
|-----------|------|-------------|
| `n_rows` | — | Rows in GC array (monolithic) |
| `n_word` | bit | Columns / word size |
| `n_partitioning_bl` | — | BL cut partitioning factor |
| `n_partitioning_wl` | — | WL cut partitioning factor |
| `n_folding_bl` | — | BL folding factor |
| `n_folding_wl` | — | WL folding factor |
| `ref_rate_mode` | — | `'vsn'` or `'ref_period'` |
| `ref_period` | s | Refresh period (for `ref_period` mode) |
| `sn_degradation` | % | Max acceptable SN voltage degradation |
| `globadr_buff` | 0/1 | Insert global address repeaters |
| `rblmux_topology` | — | `'tree'` or `'tristate'` |

### Gain Cell (GC) Circuits

| Parameter | Unit | Description |
|-----------|------|-------------|
| `gc_width`, `gc_height` | m | Physical GC dimensions |
| `c_wwl`, `c_wbl`, `c_rwl`, `c_rbl` | F | Port capacitances |
| `c_sn` | F | Storage node capacitance |
| `r_wwl_on` | ohm | WWL transistor ON-resistance |
| `r_rbl_on_vect` | ohm | RBL ON-resistance vs. SN degradation |
| `sn_degr_vect` | % | SN degradation levels (vector) |
| `tret_vect` | s | Retention times for each degradation level |
| `h_wwl`, `h_wbl`, `h_rwl`, `h_rbl` | 0–1 | Switching thresholds |

### Buffers (each has r_, c_, d_ variants)

| Buffer | r_ [ohm] | c_ [F] | d_ [m] |
|--------|----------|--------|--------|
| WWL local | `r_wwl_buffer` | `c_wwl_buffer` | `d_wwl_buffer` |
| WBL local | `r_wbl_buffer` | `c_wbl_buffer` | `d_wbl_buffer` |
| RWL local | `r_rwl_buffer` | `c_rwl_buffer` | `d_rwl_buffer` |
| Global address | `r_globadr_buffer` | `c_globadr_buffer` | `d_globadr_buffer` |
| Global boosted | `r_globadr_boost_buffer` | `c_globadr_boost_buffer` | `d_globadr_boost_buffer` |
| RBL mux | `r_mux_buffer` | `c_mux_buffer` | `d_mux_buffer` |

### Sense Amplifier, Decoders, Standard Cells

| Parameter | Unit | Description |
|-----------|------|-------------|
| `c_sa`, `t_sa`, `d_sa` | F / s / m | Sense amplifier capacitance, delay, dimension |
| `dec_intconbuff_2`, `dec_intconbuff_3` | 0/1 | Enable decoder RC buffers at stage 2/3 |
| `r_dec_buffer_2/3`, `c_dec_buffer_2/3` | ohm / F | Decoder buffer parasitics |
| `d_dec_intconbuff`, `d_and`, `d_ls`, `d_ff` | m | Decoder/cell physical dimensions |
| `r_wire_hor/ver_per_m`, `c_wire_hor/ver_per_m` | ohm/m / F/m | Wire parasitics |
| `t_ff`, `t_ls`, `t_inv_fo1/fo2`, `t_and_fo1/fo4/fo16` | s | Standard cell delays |
| `t_inv_boost_fo1`, `t_and_boost_fo1` | s | Boosted-supply gate delays |

---

## 5. Example: 28 nm FD-SOI 3T-N — `load_28fdsoi_3tn.m`

This file provides a complete set of pre-characterized technology inputs.

| Parameter | Value |
|-----------|-------|
| Technology | 28 nm FD-SOI |
| Gain cell | 3-transistor all-NMOS (3T-N) |
| Array size | 256 rows × 32 bits |
| Partitioning / folding | None (all = 0) |
| `ref_rate_mode` | `'ref_period'` |
| `ref_period` | 3 µs |
| `h_wwl`, `h_wbl`, `h_rwl` | 0.9 (90% swing) |
| `h_rbl` | 0.58 (58% swing — sense amplifier is less sensitive) |
| `c_sn` | 97 fF |
| `c_wwl` / `c_rwl` | 63 / 65 fF |
| `c_wbl` / `c_rbl` | 37 / 47 fF |
| `r_wwl_on` | 15 kΩ |
| RBL R @ 0%/10%/20%/30%/40% SN degradation | 17 / 21 / 29 / 45 / 73 kΩ |
| Retention time @ 0%/.../40% | 0 / 45 ns / 483 ns / 3.98 µs / 19.24 µs |
| `t_ff` / `t_ls` | 37 ps / 50 ps |
| `t_inv_fo1` / `t_and_fo1` / `t_and_fo4` | 7.5 ps / 17 ps / 24 ps |
| `t_sa` | 16 ps |
| `rblmux_topology` | `'tree'` |
| `dec_intconbuff_2` / `dec_intconbuff_3` | 0 / 1 |
| Wire R (hor/ver) | 9.47 / 9.43 MΩ/m |
| Wire C (hor/ver) | 303 / 294 fF/mm |

---

## 6. Note on Energy and Leakage

GEMTOO does **not** model energy or leakage. The outputs of `gcedram_out` are:
- Timing: `twwl`, `twbl`, `trwl`, `trbl`, `fmax`
- Area: `d_width`, `d_height`, `area_efficiency`, `memory_density`
- Availability: `avail`
- Bandwidth: `bw`

Leakage is implicitly embedded in the `tret_vect` / `r_rbl_on_vect` vectors, which must be pre-characterized from SPICE simulations or silicon measurements. The tool takes these as inputs and does not compute current or power from first principles.
