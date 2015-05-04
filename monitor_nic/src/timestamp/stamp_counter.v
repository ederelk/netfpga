

/////////////////////////////////////////////////////////////////////////////
// Time stamp counter
// 
// 
//
/////////////////////////////////////////////////////////////////////////////

`timescale 1 ns/1 ps
module stamp_counter #(
		       parameter COUNTER_WIDTH = 64,
                       parameter OVERFLOW = 32'hffffffff,
		       parameter NUM_QUEUES       = 8
		       )
   (
    output  [64-1:0]                         counter_val,

    input                                    start_monitoring,
    input [31:0]                             ntp_timestamp_high,
    input [31:0]                             ntp_timestamp_low,
    input                                    clk_time,
    input                                    clk_correction,
    input                                    reset);



   /////////////////////////////////////////////////////////////////////////

   reg [64-1:6] 		             temp;
   reg [64-1:0]                              Time_sync;
   reg                                       sync_valid;
   reg [31:0]                                accumulator;
   reg [31:0]                                DDS_reg;
   reg [26:0]                                sync;
   reg                                       reset_clk_correction;
   reg                                       reset_clk_correction_sync;

   wire [64-1:0]                             Time_sync_in;
   wire                                      sync_valid_in;
   wire                                      reset_clk_correction_in;
   
   wire [31:0]                                DDS_rate;
   wire                                       DDS_valid;

  
   assign counter_val = {temp,6'b0};
   assign Time_sync_in = Time_sync;
   assign sync_valid_in = sync_valid;
   assign reset_clk_correction_in = reset_clk_correction;

   always @(posedge clk_correction)
   begin
      reset_clk_correction_sync <= reset;
      reset_clk_correction <= reset_clk_correction_sync;
   end

   always @(posedge clk_correction) begin
      sync <= sync + 1;
      sync_valid <= 0;
      if(sync==27'h3B9ACA0) begin
         sync <= 0;
         sync_valid <= 1;
         Time_sync <= {temp,6'b0};
      end
      if(DDS_valid)
         DDS_reg <= DDS_rate;
      if (reset_clk_correction) begin
            Time_sync <= 0;
            DDS_reg <= DDS_rate;
            sync <= 0;
      end
   end   

   always @(posedge clk_time) begin
        if(reset) begin
             temp     <= 0;
             accumulator <= 0;
        end
        else  if(start_monitoring)
             temp<= {ntp_timestamp_high,ntp_timestamp_low[31:6]};
        else begin
             if(OVERFLOW-accumulator<DDS_reg)
                  temp <= temp + 1;
              accumulator <= accumulator + DDS_reg;
        end
   end
 



    correction #(
                  .DATA_WIDTH(64)
                ) correction

    (// input
        .Time_sync                          (Time_sync_in),
        .sync_valid                         (sync_valid_in),
     // output
        .DDS_rate                           (DDS_rate),
        .DDS_valid                          (DDS_valid),
     // misc
        .reset                              (reset_clk_correction_in),
        .clk                                (clk_correction)
    );




endmodule // stamp_counter




