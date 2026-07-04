`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/04/2026 02:54:56 PM
// Design Name: 
// Module Name: tb_set_associative_cache
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


`timescale 1ns/1ps

module set_associative_cache_tb;

        parameter index_bits    = 3;
        parameter offset_bits   = 3;
        parameter addr_bits     = 16;
        parameter associativity = 4;
        
        reg clk;
        reg rst;
        reg access;
        reg is_write;
        reg [addr_bits-1:0] addr;
        
        wire hit;
        wire evicted;
        wire [addr_bits-offset_bits-index_bits-1:0] f_evicted_tag;
        
        set_associative_cache #(
            .index_bits(index_bits),
            .offset_bits(offset_bits),
            .addr_bits(addr_bits),
            .associativity(associativity)
        ) DUT (
            .clk(clk),
            .rst(rst),
            .access(access),
            .is_write(is_write),
            .addr(addr),
            .hit(hit),
            .evicted(evicted),
            .f_evicted_tag(f_evicted_tag)
        );
        
        initial begin
            clk = 1;
            forever #5 clk = ~clk;
        end
        initial begin
        
            rst = 1;
            access = 0;
            is_write = 0;
            addr = 0;
        
            #10;
            rst = 0;
            access = 1;
            //========================================================
            // READ MISS
            // Cache empty.
            // Miss.
            // Allocate Way0.
            // Dirty = 0.
            //========================================================
            addr = 16'h0000;
            is_write = 0;
            
            #10;
            //========================================================
            // READ MISS
            // Allocate Way1.
            //========================================================
            addr = 16'h0040;
            is_write = 0;
            
            #10;
            //========================================================
            // READ MISS
            // Allocate Way2.
            //========================================================
            addr = 16'h0080;
            is_write = 0;
            
            #10;
            //========================================================
            // READ MISS
            // Allocate Way3.
            // Cache is now full.
            //========================================================
            addr = 16'h00C0;
            is_write = 0;
            
            #10;
            //========================================================
            // READ HIT
            // Tag already exists.
            // No dirty bit change.
            // PLRU updated.
            //========================================================
            addr = 16'h0000;
            is_write = 0;
            
            #10;
            //========================================================
            // WRITE HIT
            // Tag exists.
            // Dirty bit becomes 1.
            // PLRU updated.
            //========================================================
            addr = 16'h0040;
            is_write = 1;
            
            #10;
            //========================================================
            // READ HIT
            // Dirty bit stays 1.
            //========================================================
            addr = 16'h0040;
            is_write = 0;
            
            #10;
            //========================================================
            // WRITE MISS
            // Cache full.
            // PLRU victim selected.
            // If victim clean:
            //      replace directly
            // If victim dirty:
            //      eviction asserted
            // New line allocated
            // New line dirty = 1
            //========================================================
            addr = 16'h0100;
            is_write = 1;
            
            #10;
            //========================================================
            // READ MISS
            // Cache full.
            // Another replacement.
            // Since read miss:
            // dirty = 0
            //========================================================
            addr = 16'h0140;
            is_write = 0;
            
            #10;
            //========================================================
            // WRITE MISS
            // Forces another replacement.
            // If dirty victim selected
            // eviction asserted.
            //========================================================
            addr = 16'h0180;
            is_write = 1;
            
            #10;
            //========================================================
            // READ HIT
            // One of the surviving lines.
            //========================================================
            addr = 16'h0000;
            is_write = 0;
            #10
            access = 0;
        
            #50;
            $finish;
        
        end
        
        initial begin
            $monitor("T=%0t Addr=%h Hit=%b Evicted=%b EvictedTag=%h",
                      $time, addr, hit, evicted, f_evicted_tag);
        end

endmodule
