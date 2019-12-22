// TODO make more generic for support of multiple slaves

`include "defines.sv"

module apb_top
       (
           input bit pclk,
           input bit presetn,
           input bit [`D_WIDTH -1:0] paddr,
           input bit pprot[2:0],
           input bit psel[`SLAVE_SUPPD], 
           input bit pwrite,
           input bit [`D_WIDTH -1:0] pwdata,
           input bit pstrb[4],
           
           output bit [`D_WIDTH -1:0] prdata,
           output bit pslverr
       );
  bit pready;
  bit pready_0;
  bit pready_1;
  bit penable;
  bit [`D_WIDTH -1:0] paddr_out_slave;
  bit pprot_out_slave[2:0];
  bit pwrite_out_slave;
  bit [`D_WIDTH -1:0] pwdata_out_slave;
  bit pslverr_out;
  bit pslverr_out_0;
  bit pslverr_out_1;
  bit [`D_WIDTH -1:0] prdata_out_0;
  bit [`D_WIDTH -1:0] prdata_out_1;
  bit [`D_WIDTH -1:0] prdata_out;
  bit psel_out_slave_0; 
  bit psel_out_slave_1; 

  bit [3:0]pstrb_p;
  bit psel_out_slave[2];
      
  
  //assign pslverr = pslverr_out;
  //assign prdata = prdata_out; 
  assign psel_out_slave_0 = psel_out_slave[0];
  assign psel_out_slave_1 = psel_out_slave[1];

  assign prdata_out = psel_out_slave_0 ? prdata_out_0 :(psel_out_slave_1 ? prdata_out_1: 'b0);
  assign pslverr_out = psel_out_slave_0 ? pslverr_out_0 :(psel_out_slave_1 ?pslverr_out_1 : 'b0 );
  assign pready = psel_out_slave_0 ? pready_0:(psel_out_slave_1 ? pready_1: 'b0 );
  
//  always_comb
//  begin
//      for(int i=0; i<4; i++)
//      begin
//          pstrb_p[i] = pstrb[i];
//      end
//
//  end
  
  apb_bridge i_apb_bridge
             (
                 .pclk(pclk),
                 .presetn(presetn),
                 .paddr(paddr),
                 .pprot(pprot),
                 .psel(psel), 
                 .pwrite(pwrite),
                 .pwdata(pwdata),
                 .pstrb(pstrb),
                 .pready(pready),
                 .prdata(prdata_out),
                 .pslverr(pslverr_out),
                 // signals to go to TOP
                 .pslverr_out(pslverr),
                 .prdata_out(prdata),
  
                 //signals to go to SLAVE
                 .penable(penable),
                 .paddr_out_slave(paddr_out_slave),
                 .pprot_out_slave(pprot_out_slave),
                 .psel_out_slave(psel_out_slave), 
                 .pwrite_out_slave(pwrite_out_slave),
                 .pwdata_out_slave(pwdata_out_slave)
  
             );
   
    apb_slave i_apb_slave_0
              (
                  .pclk(pclk),
                  .presetn(presetn),
                  .penable(penable),
                  .paddr(paddr_out_slave),
                  .pprot(pprot_out_slave),
                  .psel(psel_out_slave_0), 
                  .pwrite(pwrite_out_slave),
                  .pwdata(pwdata_out_slave),
  
                  .pslverr(pslverr_out_0),
                  .pready(pready_0),
                  .prdata(prdata_out_0)
              );
    apb_slave i_apb_slave_1
              (
                  .pclk(pclk),
                  .presetn(presetn),
                  .penable(penable),
                  .paddr(paddr_out_slave),
                  .pprot(pprot_out_slave),
                  .psel(psel_out_slave_1), 
                  .pwrite(pwrite_out_slave),
                  .pwdata(pwdata_out_slave),
  
                  .pslverr(pslverr_out_1),
                  .pready(pready_1),
                  .prdata(prdata_out_1)
              );


endmodule

