`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/04/2026 12:14:07 PM
// Design Name: 
// Module Name: set_tb
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


module set_tb;

    parameter index_bits = 3;
    parameter offset_bits = 3;
    parameter addr_bits = 16;
    
    reg clk;
    reg rst;
    reg access;
    reg is_write;
    reg [addr_bits-offset_bits-index_bits-1:0] tag;
    
    wire hit;
    wire eviction;
    wire [addr_bits-offset_bits-index_bits-1:0] evicted_tag;
    
    set DUT (
        .clk(clk),
        .rst(rst),
        .access(access),
        .is_write(is_write),
        .tag(tag),
        .hit(hit),
        .eviction(eviction),
        .evicted_tag(evicted_tag)
    );
    
    initial begin
        clk = 1;
        forever #5 clk = ~clk;
    end
    
    initial begin
        rst = 1;
        access = 0;
        is_write = 0;
        tag = 0;
        
        #10
        rst = 0;
        access = 1;
        tag = 10'h001;    // Miss -> Way0
        #10
        tag = 10'h002;    // Miss -> Way1
        #10
        tag = 10'h003;    // Miss -> Way2
        #10
        tag = 10'h004;    // Miss -> Way3
       
        #10
        tag = 10'h001;    // hit -> Way0
        #10
        tag = 10'h002;    // hit -> Way1
        #10
        tag = 10'h003;    // hit -> Way2
        #10
        tag = 10'h004;    // hit -> Way3
        
        #10
        is_write = 1;        // Write hit
        tag = 10'h002;
        
        #10
        is_write = 0;           //force replacement
        tag = 10'h010;
        
        #10
        tag = 10'h020;             //dirty eviction
        
        #10
        is_write = 1; 
        tag = 10'h030;
       #10
        is_write = 0;
        tag = 10'h040;
       
       #10
       tag = 10'h050;
        
        
          
    end
    

endmodule
