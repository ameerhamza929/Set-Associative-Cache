# Set-Associative-Cache

A parameterizable 4-way set-associative cache written in SystemVerilog. The design implements write-back and write-allocate policies, manages valid and dirty bits, and uses a small tree-based pseudo-LRU structure to choose ways for replacement. It is intended for FPGA projects, simulation-based exploration, and computer‑architecture learning.

Repository: https://github.com/ameerhamza929/Set-Associative-Cache/tree/main

## Features
- 4-way set-associative cache (parameterizable associativity)
- Write-back and write-allocate semantics
- Valid and dirty bit tracking per way
- Tree-based pseudo-LRU replacement (small hardware cost)
- Parameterizable: index, offset, address width and associativity
- Simple testbenches included for functional verification

## Repository layout
```
README.md
RTL/
  Sources/
    cache.sv             -- top-level set_associative_cache module
    set.sv               -- single set (contains ways, tags, LRU tree)
  Testbench/
    set_tb.sv            -- testbench for the set module
    tb_set_associative_cache.sv -- testbench for the top-level cache
```

## Design overview

Top-level module
- Module name: set_associative_cache (in RTL/Sources/cache.sv)
- Parameters:
  - index_bits (default 3) — number of bits used for set indexing
  - offset_bits (default 3) — number of block offset bits (determines DATA_WIDTH)
  - addr_bits (default 16) — width of addresses presented to the cache
  - associativity (default 4) — number of ways per set
  - DATA_WIDTH = 1 << offset_bits
- Ports:
  - input clk, rst
  - input access — pulse when a lookup/operation should occur
  - input is_write — 1 for write accesses, 0 for read
  - input [addr_bits-1:0] addr — byte/word address presented to the cache
  - output logic hit — asserted when any way matches the tag in the indexed set
  - output logic evicted — asserted when an eviction (write-back of a dirty line) occurs
  - output logic [addr_bits-offset_bits-index_bits-1:0] f_evicted_tag — tag of the evicted line (if any)

Single-set module
- Module name: set (in RTL/Sources/set.sv)
- Implements 4 ways of storage (parameterizable)
- Maintains:
  - tags[] per way
  - valid[] and dirty[] bits per way
  - a small lru_tree[] bit array to implement tree-based pseudo-LRU
- On access:
  - If tag matches in any valid way, set updates LRU tree bits to mark that way as recently used; for writes, dirty bit is set.
  - If miss and there is an invalid way, that way is allocated and tag/dirtiness set accordingly (write-allocate behavior).
  - If miss and all ways valid, the LRU tree is used to select a way to replace. If the selected way is dirty, eviction is asserted and the evicted tag is output for the external write-back process.

Replacement policy
- Tree-based pseudo-LRU:
  - For a 4-way set, uses three bits (root and two internal nodes) to select the least-recently-used sub-tree and then a way inside that sub-tree.
  - Each hit updates the tree bits to mark the direction of most recent use.
- When replacing a dirty line, the module asserts eviction and outputs the tag of the evicted line so that higher-level logic can perform write-back.

Address breakdown
- offset bits: low offset_bits used to select byte/word inside a block
- index bits: next index_bits select the set number
- tag bits: remaining high bits, width = addr_bits - offset_bits - index_bits

Example: default parameters (index_bits=3, offset_bits=3, addr_bits=16)
- NUM_SETS = 2^3 = 8
- block size = 2^3 = 8 (DATA_WIDTH = 8)
- tag width = 16 - 3 - 3 = 10 bits

## How to simulate

The repository includes simple testbenches:
- RTL/Testbench/set_tb.sv — tests the single set behavior, misses, hits, write marking, and dirty eviction
- RTL/Testbench/tb_set_associative_cache.sv — exercises the full cache

General steps to run a simulation with a SystemVerilog simulator (replace with the simulator you have: ModelSim/Questa, Synopsys VCS, Cadence Xcelium, etc.):

ModelSim / Questa (example)
```
# compile
vlog RTL/Sources/*.sv RTL/Testbench/*.sv

# run the top-level testbench (module name used in the file)
vsim work.tb_set_associative_cache
run -all
```

Synopsys VCS (example)
```
vcs -sverilog RTL/Sources/*.sv RTL/Testbench/tb_set_associative_cache.sv -o simv
./simv
```

Notes:
- Some open-source tools (iverilog) do not fully support SystemVerilog features used here. Use a commercial SystemVerilog-capable simulator (ModelSim/Questa, VCS, Xcelium) or adapt the testbench for Verilator (which typically requires a C++ harness).
- Waveform dumping: add appropriate simulator flags (e.g., +vcd or -lca/ +vcdfile options) to capture waveforms.

## How to instantiate

Top-level instantiation example:
```systemverilog
set_associative_cache #(
  .index_bits(3),
  .offset_bits(3),
  .addr_bits(16),
  .associativity(4)
) my_cache (
  .clk(clk),
  .rst(rst),
  .access(access),
  .is_write(is_write),
  .addr(addr),
  .hit(hit),
  .evicted(evicted),
  .f_evicted_tag(evicted_tag)
);
```

Single-set instantiation (internal use; shown for reference):
```systemverilog
set #(
  .index_bits(3),
  .offset_bits(3),
  .addr_bits(16),
  .associativity(4)
) my_set (
  .clk(clk),
  .rst(rst),
  .access(access_for_this_set),
  .is_write(is_write),
  .tag(tag_for_this_set),
  .hit(hit_out),
  .eviction(eviction_out),
  .evicted_tag(evicted_tag_out)
);
```

When connecting the top-level cache, the top module instantiates one set per index and gates the access signal so only the selected set sees the operation.

## Test coverage & expected behavior
- The included testbenches exercise:
  - Misses that allocate ways until all ways are valid
  - Hits that update LRU and set dirty when writes occur
  - Replacement decisions and dirty evictions (eviction signal and evicted tag)
- Testbenches are basic functional checks. For comprehensive verification, extend tests to:
  - Randomized sequences (reads/writes)
  - Concurrent access patterns (if your target environment supports it)
  - Integration with a memory model to verify write-back transactions

## Synthesis and FPGA considerations
- The design is small and hardware-friendly (small arrays of registers and a couple of LRU bits per set).
- Before synthesizing, check:
  - Target synthesis tool's SystemVerilog support
  - Replace behavioral constructs (if any) with supported RTL-friendly patterns
  - Consider creating a proper memory array or BRAM interface rather than register arrays when targeting large caches on FPGA
- The current implementation stores tags and valid/dirty bits as reg arrays. Data storage is not modeled beyond the DATA_WIDTH parameter — for a full cache you will need to attach data arrays or BRAM blocks.

## Files of interest
- RTL/Sources/cache.sv — top-level cache wrapper; parameterizes and instantiates sets
- RTL/Sources/set.sv — implements per-set logic, tags, valid/dirty bits, and replacement
- RTL/Testbench/set_tb.sv — focused test for single set behavior
- RTL/Testbench/tb_set_associative_cache.sv — testbench that drives the full cache

## Extending the design
- Add data arrays (per-way) and memory interface for write-back transfers
- Add byte-enable support for partial-width writes
- Add configurable block size and different replacement policies (LRU, random)
- Add statistics counters for hits, misses, and evictions

## License and contribution
- No license file is included in the repository. If you plan to share or reuse this code publicly, add an appropriate LICENSE file (MIT, Apache 2.0, etc.).
- Contributions: open an issue or submit a pull request with a clear description and testcases for functional changes.

## Contact / Questions
If you want help adding a memory model, preparing a Verilator-friendly testbench, or adapting the design for synthesis to a particular FPGA toolchain, provide the target toolchain and I can suggest specific changes and simulation commands.
