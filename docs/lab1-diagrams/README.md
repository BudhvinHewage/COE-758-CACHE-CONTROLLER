# COE 758 — Cache Controller: Lab 1 Diagrams (Symbol / Internal / System)

> **Due: Wednesday, during the lab.**
> Three required artifacts for the cache controller (Project #1), as markdown +
> Mermaid. Each file has: (a) what the course is asking for, (b) the Mermaid draft,
> (c) a checklist of things to adjust against the lab handout / your own design.

## The assignment
Produce three views of the cache controller:

| # | Artifact | What it shows |
|---|----------|---------------|
| 1 | **Cache controller symbol** | The box for a bigger schematic — external pins only (CPU, SDRAM-controller, local-SRAM interfaces + CLK). |
| 2 | **Internal block diagram** | What's inside the box: address splitting (tag/index/offset), tag/valid/dirty storage, comparator, FSM, block-transfer logic. |
| 3 | **System block diagram** | Controller's place in the system: CPU ↔ controller ↔ local SRAM + SDRAM controller ↔ SDRAM. |

## Project spec (from this repo's `README.md` — single source of truth)
- **Cache:** 256 bytes total; block = 32 bytes (1 byte/word); **8 blocks**.
- **Address:** 16-bit CPU address → **Tag [15:8] (8 b) · Index [7:5] (3 b) · Offset [4:0] (5 b)**.
- **Three interfaces** (all share `CLK`):
  - **CPU:** `CS`, `WR/RD`, `ADD[15:0]`, `DIN[7:0]`, `DOUT[7:0]`, `RDY`
  - **SDRAM controller:** `ADD[15:0]`, `WR/RD`, `MEMSTRB`, `DIN[7:0]`, `DOUT[7:0]`
  - **Local SRAM (BlockRAM):** `ADD[7:0]`, `DIN[7:0]`, `DOUT[7:0]`, `WEN`
- **Behavioral cases:** write hit · read hit · miss w/ dirty=0 (fetch block at
  `ADD & 00000`) · miss w/ dirty=1 (write back old block at `[oldTag & Index & 00000]`
  first, then fetch).
- Course design process (7-step): Specification → **Symbol** → **Block diagram &
  behavioral description** → HDL → System integration → Synthesis → Test.

## Files
- [`01-cache-controller-symbol.md`](01-cache-controller-symbol.md)
- [`02-internal-block-diagram.md`](02-internal-block-diagram.md)
- [`03-system-block-diagram.md`](03-system-block-diagram.md)

## How to preview the Mermaid
- Obsidian renders ```mermaid blocks natively — just open the files.
- CLI: `npx -y @mermaid-js/mermaid-cli -i <file>.mmd -o out.svg` (if needed).

## Status
- [ ] Cross-checked against the exact Lab 1 submission requirements in `Cache_Project_12-09-10_.pdf`
- [ ] Diagrams updated to match whatever you settled on (FSM states, storage structure)
- [ ] Rendered / pasted into the lab submission doc if the format requires images
