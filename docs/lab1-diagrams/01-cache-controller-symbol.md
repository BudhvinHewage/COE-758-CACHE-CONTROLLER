# 1. Cache Controller — Symbol

## What this artifact is
The **symbol** is the top-level entity: the box you place on a bigger schematic.
**External pins only** — the three interfaces from the project spec, plus CLK.
No internals.

## What the course is asking for
As per the initial review of the project requirements, and resulting draft

| Interface | Signals |
|---|---|
| **CPU** | `CS`, `WR/RD`, `ADD[15:0]`, `DIN[7:0]`, `DOUT[7:0]`, `RDY` |
| **SDRAM Controller** | `ADD[15:0]`, `WR/RD`, `MEMSTRB`, `DIN[7:0]`, `DOUT[7:0]` |
| **Local SRAM (BlockRAM)** | `ADD[7:0]`, `DIN[7:0]`, `DOUT[7:0]`, `WEN` |
| **Clock** | `CLK` (shared by all three interfaces) |

## Mermaid draft

```mermaid
flowchart LR
    CPU["CPU"] <-->|"CS, WR/RD, ADD[15:0] in<br/>DOUT[7:0] out, RDY out<br/>DIN[7:0] in (write data)"| CC["CACHE CONTROLLER<br/>(symbol)"]
    CC <-->|"ADD[15:0], WR/RD, MEMSTRB in<br/>DIN[7:0], DOUT[7:0] both ways"| SC["SDRAM CONTROLLER"]
    CC <-->|"ADD[7:0], WEN in<br/>DIN[7:0] in, DOUT[7:0] out"| SRAM[("LOCAL SRAM<br/>(BlockRAM)<br/>256 x 8")]
    CLK["CLK"] --> CC
```
## Final Component Symbol
![alt text](image-1.png)