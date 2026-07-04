`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/04/2026 12:48:13 PM
// Design Name: 
// Module Name: cache
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


module set_associative_cache #(
    parameter index_bits = 3,
    parameter offset_bits = 3,
    parameter addr_bits = 16,
    parameter associativity = 4,
    parameter DATA_WIDTH = 1 << offset_bits
)( 
    input clk,
    input rst,
    input access,
    input is_write,
    input [addr_bits-1:0] addr,
    output logic hit,
    output logic evicted,
    output logic [addr_bits-offset_bits-index_bits-1:0] f_evicted_tag
    );
    
    
    localparam NUM_SETS = 1 << index_bits;
  
    wire [offset_bits-1:0]offset;
    wire [index_bits -1:0]index;
    wire [addr_bits-offset_bits-index_bits-1:0] tag; 
    
    assign offset = addr[offset_bits-1:0];
    assign index = addr[offset_bits + index_bits - 1:offset_bits];
    assign tag = addr [addr_bits+offset_bits+index_bits-1:offset_bits + index_bits];
    
    wire [0:NUM_SETS-1] eviction;
    wire [addr_bits-offset_bits-index_bits-1:0] evicted_tag [0:NUM_SETS-1];
    wire [0:NUM_SETS-1]hits;
    assign hit = |hits;   //reduction OR operator
    assign evicted = |eviction;
    
    always_comb begin
        f_evicted_tag = '0;
    
        for (int i = 0; i < NUM_SETS; i++) begin
            if (eviction[i])
                f_evicted_tag = evicted_tag[i];
        end
    end
   
   genvar i;
   generate
       for(i = 0; i<NUM_SETS; i=i+1)begin
            set #(
                .index_bits(index_bits),
                .offset_bits(offset_bits),
                .addr_bits(addr_bits),
                .associativity(associativity)
            ) DUT (
                .clk(clk),
                .rst(rst),
                .access(access && (index==i)),
                .is_write(is_write),
                .tag(tag),
                .hit(hits[i]),
                .eviction(eviction[i]),
                .evicted_tag(evicted_tag[i])
            );
       end
   endgenerate 


endmodule