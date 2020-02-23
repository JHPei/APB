`include "defines.sv"

module apb_top
       (
           input bit pclk,
           input bit presetn,
           input bit [`D_WIDTH -1: 0] paddr,
           input bit pprot[2:0],
           input bit psel[`SLAVE_SUPPD],
           input bit pwrite,
           input bit [`D_WIDTH -1: 0] pwdata,
           input bit pstrb[4],

           output bit [`D_WIDTH -1: 0] prdata,
           output bit pslverr
       );
  bit pready;
  bit pready_slave[`SLAVE_SUPPD -1: 0];
  bit penable;
  bit [`D_WIDTH -1: 0] paddr_out_slave;
  bit pprot_out_slave[2:0];
  bit pwrite_out_slave;
  bit [`D_WIDTH -1: 0] pwdata_out_slave;
  bit pslverr_out;
  bit pslverr_out_slave[`SLAVE_SUPPD -1: 0];
  bit [`D_WIDTH -1: 0] prdata_out;
  bit [`D_WIDTH -1: 0] prdata_out[`SLAVE_SUPPD -1: 0];
  bit psel_out_slave[`SLAVE_SUPPD -1: 0];

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
                 //signals to go to TOP
                 .pslverr_out(pslverr),
                 .prdata_out(prdata),

                 //Signals to go to SLAVE
                 .penable(penable),
                 .paddr_out_slave(paddr_out_slave),
                 .pprot_out_slave(pprot_out_slave),
                 .psel_out_slave(psel_out_slave),
                 .pwrite_out_slave(pwrite_out_slave),
                 .pwdata_out_slave(pwdata_out_slave)

             );
  genvar i;

  generate
    for(i =0; i< `SLAVE_SUPPD; i++)
    begin
        apb_slave i_apb_slave
                  (
                      .pclk(pclk),
                      .presetn(presetn),
                      .penable(penable),
                      .paddr(paddr_out_slave),
                      .pprot(pprot_out_slave),
                      .psel(psel_out_slave),
                      .pwrite(pwrite_out_slave),
                      .pwdata(pwdata_out_slave),

                      .pslverr(pslverr_out_slave[i]),
                      .pready(pready_slave[i]),
                      .prdata(prdata_out_slave[i])
                  );

    end
  endgenerate

  always @(*)
  begin

      // TODO: known issue: when none of the conditions match, prdata_out ='b0.
      // This is not the correct implementation, previous value should be
      // retained

      for(int j=0; j<`SLAVE_SUPPD; j++)
      begin
          prdata_out = psel_out_slave[j] ? prdata_out_slave[j] : 'b0;

          if(prdata_out)
              break;
      end
      for(int j=0; j<`SLAVE_SUPPD; j++)
      begin
         pslverr_out = psel_out_slave[j] ? pslverr_out_slave[j] : 'b0; 

          if(pslverr_out)
              break;
      end
      for(int j=0; j<`SLAVE_SUPPD; j++)
      begin
          pready = psel_out_slave[j] ? pready_slave[j] : 'b0; 

          if(pready)
              break;
      end
  end
endmodule

