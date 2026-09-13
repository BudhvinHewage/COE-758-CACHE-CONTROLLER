# COE758 – Cache Controller (Memory Hierarchy Project)

A VHDL implementation of a simplified cache controller for a single-level memory hierarchy — sitting between a CPU and an SDRAM controller, backed by local BlockRAM — built as Project #1 for COE758 (Digital Systems Engineering).

**Status:** Specification and design-tutorial review in progress. VHDL implementation not yet started.

---

## Goals (staged)

Following the course's 7-step design process (see `COE758_Digital_Design_Tutorial.pdf`):

1. **Specification Analysis** — nail down the CPU/SDRAM/BlockRAM interface timing and the four behavioral cases (read/write hit, miss w/ clean block, miss w/ dirty block).
2. **Symbol Creation** — top-level entity/port declaration for the Cache Controller.
3. **Block Diagram & Behavioral Description** — FSM, tag/valid/dirty storage, comparators; process diagrams and clock-accurate timing diagrams.
4. **HDL Implementation** — VHDL processes for the FSM, storage arrays, and muxing logic.
5. **System Integration** — combine the controller with the BlockRAM module (from Tutorial 3) into a complete Cache block.
6. **Synthesis & Circuit Implementation** — Xilinx ISE, targeting the Spartan-3E.
7. **Test & Verification** — measure the six required timing parameters below.

Each stage builds directly on the last, per the course's design methodology — no stage is skipped or reordered.

---

## System Specification

| Parameter | Value |
|---|---|
| Cache size | 256 bytes total |
| Block size | 32 bytes (1 byte/word) |
| Number of blocks | 8 |
| CPU address width | 16 bits |
| Address fields | Tag [15:8] (8b) · Index [7:5] (3b) · Offset [4:0] (5b) |
| Target device | Xilinx Spartan-3E FPGA |

**Interfaces the controller must implement:**

| Interface | Signals |
|---|---|
| CPU | `CS`, `WR/RD`, `ADD[15:0]`, `DIN[7:0]`, `DOUT[7:0]`, `RDY` |
| SDRAM Controller | `ADD[15:0]`, `WR/RD`, `MEMSTRB`, `DIN[7:0]`, `DOUT[7:0]` |
| Local SRAM (BlockRAM) | `ADD[7:0]`, `DIN[7:0]`, `DOUT[7:0]`, `WEN` |

All three interfaces share the same `CLK`.

---

## Behavioral Cases

1. **Write hit** — index/offset sent to local SRAM as write address; dirty and valid bits set; data written.
2. **Read hit** — index/offset sent to local SRAM; read data routed back to CPU.
3. **Miss, dirty = 0** — full block fetched from SDRAM (base address = CPU address with offset = `00000`), written into local SRAM; tag replaced, valid set; then hit procedure runs.
4. **Miss, dirty = 1** — old block written back to SDRAM at `[oldTag & Index & 00000]`; new block fetched from SDRAM at `[newTag & Index & 00000]` and written to local SRAM; tag replaced; then hit procedure runs.

---

## Toolchain

- **Xilinx ISE**, targeting the Spartan-3E — required CAD environment for the course.
- Design work is being done via **VSD**, since ISE doesn't install on my main machine.
- `COE758_Digital_Design_Tutorial.pdf` — the course's formal design-process reference (used as the template for this project's design flow).
- `Cache_Project_12-09-10_.pdf` — the Project #1 specification itself.

---

## Decision Log

*(to be filled in as design decisions get made — FSM state breakdown, storage array structure, etc.)*

---

## Build Log

*(to be filled in as implementation progresses)*

---

## Results to Measure

Required for the final report, based on hardware emulation:

- [ ] Hit/Miss determination time
- [ ] Data access time
- [ ] Block replacement time
- [ ] Hit time (Cases 1 & 2)
- [ ] Miss penalty — Case 3 (dirty = 0)
- [ ] Miss penalty — Case 4 (dirty = 1)

---

## Roadmap

- [ ] Finish reading spec + design tutorial
- [ ] Draft top-level entity/symbol for the Cache Controller
- [ ] Draw FSM state diagram covering hit / miss-clean / miss-dirty transitions
- [ ] Design tag/valid/dirty storage (8 entries each)
- [ ] Implement FSM + storage in VHDL
- [ ] Integrate with BlockRAM module (Tutorial 3) into complete Cache
- [ ] Simulate all four behavioral cases
- [ ] Synthesize for Spartan-3E, capture timing measurements
- [ ] Write final report