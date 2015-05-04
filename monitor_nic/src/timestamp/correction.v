`timescale 1ns/1ps
/////////////////////////////////////////////////////////////////////////////
// 
// Module: timestamp.v
// Project: NetFPGA Rev 2.1
// 
//
///////////////////////////////////////////////////////////////////////////////
  
  module correction
    #(parameter DATA_WIDTH = 64,
      parameter CTRL_WIDTH=DATA_WIDTH/8,
      parameter ENABLE_HEADER = 0,
      parameter STAGE_NUMBER = 'hff
     )
   

   (// RX packet
    input [63:0]                     Time_sync,
    input                            sync_valid,

    // output time stamps
    output reg [31:0]                DDS_rate,
    output reg                       DDS_valid,

    // misc
    input                            reset,
    input                            clk
    );
          
  
     reg [2:0]    state;
     reg [2:0]    state_next;
     reg [63:0]   Time_prev;
     reg [63:0]   Time_prev_next;
     reg [31:0]   DDS_rate_next;
     reg          DDS_valid_next;
     reg [63:0]   error_signed;
     reg [63:0]   error_signed_next;
    

     localparam WAIT_FIRST_SYNC    = 1;
     localparam WAIT_SYNC          = 2;
     localparam UPDATE_AND_RESTORE = 4;

     localparam DRIFT_CORRECTION   = 118;
   // synthesis attribute ASYNC_REG of reset_long is TRUE ;

    always @(*) begin
     state_next = state;
     DDS_valid_next = 0;
     DDS_rate_next = DDS_rate;
     Time_prev_next = Time_prev;
     error_signed_next = Time_sync - Time_prev_next;  


     case(state)
        WAIT_FIRST_SYNC: begin
           if(sync_valid) begin
                Time_prev_next  = Time_sync;
                state_next = WAIT_SYNC;
           end
        end

	WAIT_SYNC: begin
           if(sync_valid) begin
                //error_signed_next = (Time_sync - Time_prev_next);
                state_next = UPDATE_AND_RESTORE;
           end
        end

        UPDATE_AND_RESTORE: begin
            if(error_signed[63:32])
               DDS_rate_next = DDS_rate - (error_signed[31:0]>>10) - DRIFT_CORRECTION;
	    else
               DDS_rate_next = DDS_rate + ((~error_signed[31:0])>>10) - DRIFT_CORRECTION;
	    DDS_valid_next = 1;
            Time_prev_next = Time_sync;
            state_next = WAIT_SYNC;
         end
       endcase
   end


   always @(posedge clk) begin
        if(reset) begin
             DDS_valid   <= 0;
             //DDS_rate    <= 32'h8970f531;
             //DDS_rate    <=32'h89705f41;
	     DDS_rate    <=32'h896f750b;
             error_signed<= 0;
             Time_prev   <= 0;
             state       <= WAIT_FIRST_SYNC;
        end
	else begin
             error_signed <= error_signed_next;
             Time_prev <= Time_prev_next;
             DDS_rate  <= DDS_rate_next;
             DDS_valid <= DDS_valid_next;            
             state <= state_next;
        end
   end

endmodule // correction
