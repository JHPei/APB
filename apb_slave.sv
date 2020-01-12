`include "defines.sv"
`include "functions.sv"

module apb_slave
       (
           input bit pclk,
           input bit presetn,
           input bit penable,
           input bit [`D_WIDTH -1:0] paddr,
           input bit pprot[2:0] ,
           input bit psel, 
           input bit pwrite,
           input bit [`D_WIDTH -1:0] pwdata,

           output bit pslverr,
           output bit pready,
           output bit [`D_WIDTH -1:0] prdata
       );

 wire clk;
 wire rstn;
 
 parameter IDLE  = 4'd10;
 parameter SETUP = 4'd11;
 parameter WRITE = 4'd12;
 parameter READ  = 4'd13;
 
 bit [3:0] current_state = IDLE;
 bit [3:0] next_state = SETUP; 

 bit [`D_WIDTH -1 :0] mem [`MEM_DEPTH -1 :0];


 assign clk = pclk;
 assign rstn = presetn;

 always @(posedge clk)
 begin
     if(rstn)
     begin
         current_state <= next_state;
     end
     else
     begin
         current_state <= IDLE;
         pready <= 'b0;
         prdata <= 'b0;
     end

 end

 always @(*)   
 begin
     case(current_state)
         IDLE:
         begin
             pready = 1'b0;
             next_state = psel ? SETUP : IDLE;
         end

         SETUP:
         begin
             pready = penable ? 1'b1 : 1'b0;
             if(paddr > `MEM_DEPTH -1)
             begin
                 pslverr = 1'b1;
                 error_display("SLAVE","ERROR","Address out of range");
                 next_state = SETUP;
             end
             else 
             begin
                 pslverr = 1'b0;
                 next_state = pready ?(pwrite ? WRITE : READ) : SETUP;
             end

             //if(pready)
             //begin
             //    if(pwrite)
             //    begin
             //        next_state = WRITE;
             //    end
             //    else
             //    begin
             //        next_state = READ;
             //    end
             //end
             //else
             //begin
             //    next_state = SETUP;
             //    //pslverr    = 1'b1; // cannot be. according to spec pg 3-6 
             //end
         end
         WRITE:
         begin
             mem[paddr] = pwdata;

             // printing pprot.since impl is still unclear
             // will use later
             for(int i =0; i<3; i++)
             begin
                 $display("pprot[i] = %b",i,pprot[i]);
             end

             if(psel) // anpther txn is going to take place 
             begin
                 next_state = SETUP;
             end
             else // no more txns 
             begin
                 next_state = IDLE;
             end
         end
         READ:
         begin
             prdata = mem[paddr];
             // printing pprot.since impl is still unclear
             // will use later
             for(int i =0; i<3; i++)
             begin
                 $display("pprot[i] = %b",i,pprot[i]);
             end
             if(psel) // anpther txn is going to take place 
             begin
                 next_state = SETUP;
             end
             else // no more txns 
             begin
                 next_state = IDLE;
             end
         end
     endcase

 end

endmodule
