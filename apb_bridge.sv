`include "defines.sv"
`include "functions.sv"

module apb_bridge
       (
           input bit pclk,
           input bit presetn,
           input bit [`D_WIDTH -1:0] paddr,
           input bit pprot[2:0] ,
           input bit psel[2], 
           input bit pwrite,
           input bit [`D_WIDTH -1:0] pwdata,
           input bit pstrb[4],
           input bit pready,
           input bit [`D_WIDTH -1:0] prdata,
           input bit pslverr,
           // signals to go to TOP
           output bit pslverr_out,
           output bit [`D_WIDTH -1:0] prdata_out,

           //signals to go to SLAVE
           output bit penable,
           output bit [`D_WIDTH -1:0] paddr_out_slave,
           output bit pprot_out_slave[2:0] ,
           output bit psel_out_slave[2], 
           output pwrite_out_slave,
           output bit [`D_WIDTH -1:0] pwdata_out_slave

       );

 wire clk;
 wire rstn;
 
 parameter WRITE = 8'hFF;
 parameter READ  = 8'hAA;

 parameter IDLE = 4'd0;
 parameter SETUP = 4'd1;
 parameter ACCESS= 4'd2;

 bit [3:0] current_state = IDLE;
 bit [3:0] next_state = SETUP; 
 bit [7:0]opr;
 bit [31:0] concat_pstrb;

 //assigning to these signals for the ease of understanding
 assign clk = pclk;
 assign rstn = presetn;

 assign pwrite_out_slave = pwrite;


 always @(posedge clk)
 begin
     if(rstn)
     begin
         current_state <= next_state;
     end
     else
     begin
         current_state <= IDLE;
         penable <= 1'b0;
         paddr_out_slave <= 'b0;
         for(int i=0; i<2; i++)
         begin
             psel_out_slave[i] <= 'b0;
         end
         pwdata_out_slave <= 'b0;
         for(int i=0; i<3; i++)
         begin
             pprot_out_slave[i] <= 'b0;
         end
     end
 end


 always @(*)
 begin
     psel_out_slave[0] = psel[0];
     psel_out_slave[1] = psel[1];
     case(current_state)
         IDLE:
         begin
             // both slaves are being selected
             if((psel[0] && psel[1]) || (psel[0] =='b0 && psel[1] =='b0))
             begin
                 error_display("BRIDGE","WARNING","Cannot select/unselect both slaves at once");
                 next_state = IDLE;    
             end
             if(psel[0] || psel[1])
             begin
                 next_state = SETUP;
             end
             else
             begin
                 error_display("BRIDGE","DEBUG","No condition to transition from IDLE to SETUP matches, next_state = IDLE");

                 next_state = IDLE;
             end

         end

         SETUP:
         begin
             penable = 'b1; // penable is generated from inside the bridge 
             if(penable)     // TODO redunant
                 next_state = ACCESS;
         end

         ACCESS:
         begin
             // both slaves are being selected
             if((psel[0] && psel[1]) || (psel[0] =='b0 && psel[1] =='b0))
             begin
                error_display("BRIDGE","WARNING","Cannot select/unselect both slaves at once");
                next_state = IDLE;    
             end
             if(pready)
             begin     //TODO signals that are universally connected to be put in assign statment
                 if(pwrite) // WRITE STATE
                 begin
                     opr = WRITE;
                     concat_pstrb = {{8{pstrb[3]}},{8{pstrb[2]}},{8{pstrb[1]}}, {8{pstrb[0]}}}; 
                     pwdata_out_slave = concat_pstrb & pwdata;
                     paddr_out_slave = paddr;
                     pprot_out_slave = pprot;
                     pslverr_out = pslverr;
                 end
                 else      // READ STATE
                 begin
                     opr = READ;
                     paddr_out_slave = paddr;
                     prdata_out = prdata;
                     pprot_out_slave = pprot;
                     pslverr_out = pslverr;
                 end
                 
             end
             else
             begin
                 if(psel[0] || psel[1]) // another txn is going to take place 
                 begin
                     next_state = ACCESS;
                 end

                 else // no more txns 
                 begin
                     next_state = IDLE;
                 end
             end
         end
     endcase
 end
endmodule

