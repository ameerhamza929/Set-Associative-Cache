`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/02/2026 04:59:29 PM
// Design Name: 
// Module Name: set
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


module set #(
    parameter index_bits = 3,
    parameter offset_bits = 3,
    parameter addr_bits = 16,
    parameter associativity = 4
)( 
    input clk,
    input rst,
//    input mode,
    input access,
    input is_write,
    input [addr_bits-offset_bits-index_bits-1:0] tag,
    output logic hit,
    output logic eviction,
    output logic [addr_bits-offset_bits-index_bits-1:0] evicted_tag
    );

    reg valid [0:associativity-1];
    reg [$clog2(associativity)-1:0] lru;
    reg [addr_bits-offset_bits-index_bits-1:0] tags [0:associativity-1];
    reg dirty[0:associativity-1];
    reg [associativity-2:0]lru_tree;                //b0 is root , b1 (W0,W1)left ,b2(W2,W3) right
    
    
    integer i;
    integer j;
    always@(posedge clk or posedge rst)begin
        if(rst)begin
            for (j=0; j< associativity; j=j+1)begin
                tags[j] <= 0;
                valid[j]<= 0;
                dirty[j]<= 0;
            end
            hit <= 0;
            lru_tree <= 0;
            eviction <= 0;
            evicted_tag <= 0;
        end
        else begin
            hit <= 1'b0;
            eviction <= 0;

            if(access)begin
                  if(valid[0] && (tags[0] == tag))begin
                      hit <= 1'b1; 
                      lru_tree[1] <= 1'b1;
                      lru_tree[0] <= 1'b1;
                      if(is_write)begin
                           dirty[0] <= 1'b1;
                      end
                  end
                  else if(valid[1] && (tags[1] == tag))begin
                      hit <= 1'b1;
                      lru_tree[1] <= 1'b0;
                      lru_tree[0] <= 1'b1;
                      if(is_write)begin
                           dirty[1] <= 1'b1;
                      end
                  end
                  else if(valid[2] && (tags[2] == tag))begin
                      hit <= 1'b1;
                      lru_tree[2] <= 1'b1;
                      lru_tree[0] <= 1'b0;
                      if(is_write)begin
                           dirty[2] <= 1'b1;
                      end
                  end
                  else if(valid[3] && (tags[3] == tag))begin
                      hit <= 1'b1;
                      lru_tree[2] <= 1'b0;
                      lru_tree[0] <= 1'b0;
                      if(is_write)begin 
                           dirty[3] <= 1'b1;
                      end
                  end
                  else if(!valid[0] || !valid[1] || !valid[2] || !valid[3])begin
                        if (!valid[0]) begin
                                tags[0]  <= tag;
                                valid[0] <= 1'b1;
                                dirty[0] <= is_write;
                            
                                lru_tree[1] <= 1'b1;
                                lru_tree[0] <= 1'b1;
                            end
                            else if (!valid[1]) begin
                                tags[1]  <= tag;
                                valid[1] <= 1'b1;
                                dirty[1] <= is_write;
                            
                                lru_tree[1] <= 1'b0;
                                lru_tree[0] <= 1'b1;
                            end
                            else if (!valid[2]) begin
                                tags[2]  <= tag;
                                valid[2] <= 1'b1;
                                dirty[2] <= is_write;
                            
                                lru_tree[2] <= 1'b1;
                                lru_tree[0] <= 1'b0;
                            end
                            else begin
                                tags[3]  <= tag;
                                valid[3] <= 1'b1;
                                dirty[3] <= is_write;
                            
                                lru_tree[2] <= 1'b0;
                                lru_tree[0] <= 1'b0;
                            end
                  end
                  else if(lru_tree[0])begin
                        if(lru_tree[2])begin
                           tags[3] <= tag;
                           dirty[3] <= is_write;
                           if(valid[3])begin
                                if(dirty[3])begin
                                    eviction <= 1;
                                    evicted_tag <= tags[3];
                                end
                           end
                           else begin
                               valid[3] <= 1'b1;
                           end
                           lru_tree[2] <= 1'b0;
                           lru_tree[0] <= 1'b0; 
                        end
                        else begin
                           tags[2] <= tag;
                           dirty[2] <= is_write;
                           if(valid[2])begin
                                if(dirty[2])begin
                                    eviction <= 1;
                                    evicted_tag <= tags[2];
                                end
                           end
                           else begin
                               valid[2] <= 1'b1;
                           end
                           lru_tree[2] <= 1'b1;
                           lru_tree[0] <= 1'b0;  
                        end
                  end
                  else begin
                        if(lru_tree[1])begin
                           tags[1] <= tag;
                           dirty[1] <= is_write;
                           if(valid[1])begin
                                if(dirty[1])begin
                                    eviction <= 1;
                                    evicted_tag <= tags[1];
                                end
                           end
                           else begin
                               valid[1] <= 1'b1;
                           end 
                            lru_tree[1] <= 1'b0;
                            lru_tree[0] <= 1'b1;
                        end
                        else begin
                            tags[0] <= tag;
                            dirty[0] <= is_write;
                            if(valid[0])begin
                                if(dirty[0])begin
                                    eviction <= 1;
                                    evicted_tag <= tags[0];
                                end
                           end
                           else begin
                               valid[0] <= 1'b1;
                           end
                            lru_tree[1] <= 1'b1;
                            lru_tree[0] <= 1'b1;
                        end
                  end
             end
             
//              else if(access && !mode)begin
                    
        
//              end


        end
       
    end

endmodule
