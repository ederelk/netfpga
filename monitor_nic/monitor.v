///////////////////////////////////////////////////////////////////////////////
// 
// 
//
// Module: monitor.v
// Project: NF2.1
// 
//  
//
//  
//  
//  
//
// 
//
///////////////////////////////////////////////////////////////////////////////
`timescale 1ns/1ps
module monitor 
   #(
      parameter DATA_WIDTH = 64,
      parameter CTRL_WIDTH = DATA_WIDTH/8,
      parameter UDP_REG_SRC_WIDTH = 2
   )
   (
      // --- data path interface
      output reg [DATA_WIDTH-1:0]        out_data,
      output reg [CTRL_WIDTH-1:0]        out_ctrl,
      output reg                         out_wr,
      input                              out_rdy,
    
      input  [DATA_WIDTH-1:0]            in_data,
      input  [CTRL_WIDTH-1:0]            in_ctrl,
      input                              in_wr,
      output                             in_rdy,
      input [63:0]                        timestamp,
      //input                               timestamp_valid,
      // --- Register interface
      input                              reg_req_in,
      input                              reg_ack_in,
      input                              reg_rd_wr_L_in,
      input  [`UDP_REG_ADDR_WIDTH-1:0]   reg_addr_in,
      input  [`CPCI_NF2_DATA_WIDTH-1:0]  reg_data_in,
      input  [UDP_REG_SRC_WIDTH-1:0]     reg_src_in,

      output                             reg_req_out,
      output                             reg_ack_out,
      output                             reg_rd_wr_L_out,
      output  [`UDP_REG_ADDR_WIDTH-1:0]  reg_addr_out,
      output  [`CPCI_NF2_DATA_WIDTH-1:0] reg_data_out,
      output  [UDP_REG_SRC_WIDTH-1:0]    reg_src_out,
      

      // --- Misc
      input                              clk,
      input                              reset
   );

   `LOG2_FUNC
   
   //--------------------- Internal Parameter-------------------------
   localparam NUM_STATES = 6;

   localparam PROCESS_CTRL_HDR = 1;
   localparam ETH_IP_HDR = 2;
   localparam FINAL_IP_HDR = 4;
   localparam PAYLOAD_ONE = 8;
   localparam PAYLOAD_TWO = 16;
   localparam PAYLOAD_THREE = 32;
   localparam empty_reg      = 16'haaaa;
   localparam FINAL_IP_HDR_WORD = 5;

   //---------------------- Wires and regs----------------------------

   reg                              in_fifo_rd_en;
   wire [CTRL_WIDTH-1:0]            in_fifo_ctrl_dout;
   wire [DATA_WIDTH-1:0]            in_fifo_data_dout;
   wire                             in_fifo_nearly_full;
   wire                             in_fifo_empty;

   wire [`CPCI_NF2_DATA_WIDTH-1:0]  ip_id_number;
   wire [`CPCI_NF2_DATA_WIDTH-1:0]  timestamp_high;
   wire [`CPCI_NF2_DATA_WIDTH-1:0]  timestamp_low;
   wire [`CPCI_NF2_DATA_WIDTH-1:0]   starting;
   reg [NUM_STATES-1:0]             state;
   reg [NUM_STATES-1:0]             state_next;
   reg [2:0]                        count;
   reg [2:0]                        count_next;
   reg [2:0]                        count_two;
   reg [2:0]                        count_next_two;
   reg [15:0] ip_id = 16'hffff;
   reg [15:0] ip_id2 = 16'h0000;
   reg [31:0] timestamp_reg_high= 32'h0;
   reg [31:0] timestamp_reg_low= 32'h0;
   //------------------------- Modules-------------------------------
   fallthrough_small_fifo #(
        .WIDTH(DATA_WIDTH+CTRL_WIDTH), 
        .MAX_DEPTH_BITS(2))
      input_fifo
        (.din ({in_ctrl,in_data}),     // Data in
         .wr_en (in_wr),               // Write enable
         .rd_en (in_fifo_rd_en),       // Read the next word 
         .dout ({in_fifo_ctrl_dout, in_fifo_data_dout}),
         .full (),
         .nearly_full (in_fifo_nearly_full),
         .empty (in_fifo_empty),
         .reset (reset),
         .clk (clk)
         );

   generic_regs
   #( 
      .UDP_REG_SRC_WIDTH   (UDP_REG_SRC_WIDTH),
      .TAG                 (`MONITOR_BLOCK_ADDR),
      .REG_ADDR_WIDTH      (`MONITOR_REG_ADDR_WIDTH),                       // Width of block addresses
      .NUM_COUNTERS        (0),                       // How many counters
      .NUM_SOFTWARE_REGS   (0),                       // How many sw regs
      .NUM_HARDWARE_REGS   (4)                        // How many hw regs
   ) monitor_regs (
      .reg_req_in       (reg_req_in),
      .reg_ack_in       (reg_ack_in),
      .reg_rd_wr_L_in   (reg_rd_wr_L_in),
      .reg_addr_in      (reg_addr_in),
      .reg_data_in      (reg_data_in),
      .reg_src_in       (reg_src_in),

      .reg_req_out      (reg_req_out),
      .reg_ack_out      (reg_ack_out),
      .reg_rd_wr_L_out  (reg_rd_wr_L_out),
      .reg_addr_out     (reg_addr_out),
      .reg_data_out     (reg_data_out),
      .reg_src_out      (reg_src_out),

      // --- counters interface
      .counter_updates  (),
      .counter_decrement(),

      // --- SW regs interface
      .software_regs    (),

      // --- HW regs interface
      .hardware_regs    ({timestamp_high,timestamp_low,ip_id_number,starting}),

      .clk              (clk),
      .reset            (reset)
    );

   //----------------------- Logic -----------------------------

   assign    in_rdy = !in_fifo_nearly_full;

   /*********************************************************************
    * Wait until the ethernet header has been decoded and the output
    * port is found, then write the module header and move the packet
    * to the output
    **********************************************************************/
   always @(*) begin
      out_ctrl = in_fifo_ctrl_dout;
      out_data = in_fifo_data_dout;
      state_next = state;
      count_next = count;
      out_wr = 0;
      in_fifo_rd_en = 0;

      if (reset) begin
         state_next = PROCESS_CTRL_HDR;
         count_next = 'd1;
      end
      else begin
         case(state)
            // Pass all control headers through unmodified
            PROCESS_CTRL_HDR: begin
               // Wait for data to be in the FIFO and the output to be ready
               if (!in_fifo_empty && out_rdy) begin
                  out_wr = 1;
                  in_fifo_rd_en = 1;
                  if (in_fifo_ctrl_dout == 'h0) begin
                     state_next = ETH_IP_HDR;
                     count_next = count + 1;
                     
                    // ip_id[15:0] = in_fifo_data_dout[15:0];
                  end
               end
            end // case: PROCESS_CTRL_HDR
   
            // Pass the ethernet and IP headers through unmodified
            ETH_IP_HDR: begin
               // Wait for data to be in the FIFO and the output to be ready
               if (!in_fifo_empty && out_rdy) begin
                  out_wr = 1;
                  in_fifo_rd_en = 1;
                        if(count == 2) begin
                        ip_id[15:0] = in_fifo_data_dout[47:32];
                        timestamp_reg_high [31:0] = timestamp[63:32];
                        timestamp_reg_low [31:0] = timestamp[31:0];
                      //  new_id_flag = 32'h1;
                        //reg_data_out = {empty_reg[15:0],ip_id[15:0]} ; 
                        end
                  count_next = count + 1;

                  if (count == FINAL_IP_HDR_WORD - 1) begin
                     state_next = FINAL_IP_HDR;
                   //  new_id_flag = 32'h0;
                     //ip_id2[15:0] = in_fifo_data_dout[15:0];
                  end
               end
            end // case: ETH_IP_HDR
   
            // In the final IP header word, touch only the last 2 bytes
            FINAL_IP_HDR: begin
               // Wait for data to be in the FIFO and the output to be ready
               if (!in_fifo_empty && out_rdy) begin
                  out_wr = 1;
                  in_fifo_rd_en = 1;
                  
                  //out_data[63:48] = in_fifo_data_dout[63:48];
                  //out_data[47:0] = in_fifo_data_dout[47:0] ^ {key[15:0], key};
                  state_next = PAYLOAD_ONE;
               end
            end // case: FINAL_IP_HDR
   
            // Process all data
            PAYLOAD_ONE: begin
               // Wait for data to be in the FIFO and the output to be ready
               if (!in_fifo_empty && out_rdy) begin
                  out_wr = 1;
                  in_fifo_rd_en = 1;
			out_data[63:48] = in_fifo_data_dout[63:48];
                  out_data[47:0] = timestamp[63:16];
                 state_next = PAYLOAD_TWO; 
                 end
            end 
               PAYLOAD_TWO: begin
               // Wait for data to be in the FIFO and the output to be ready
               if (!in_fifo_empty && out_rdy) begin
                  out_wr = 1;
                  in_fifo_rd_en = 1;
			out_data[63:48] = timestamp[15:0];
                  out_data[47:0] = in_fifo_data_dout[47:0];
                 state_next = PAYLOAD_THREE; 
                 end
            end 
            PAYLOAD_THREE: begin
                  if (!in_fifo_empty && out_rdy) begin
                  out_wr = 1;
                  in_fifo_rd_en = 1;

                  // Encrypt/decrypt the data
                 // out_data = in_fifo_data_dout ^ {key, key};

                  // Check for EOP
                  if (in_fifo_ctrl_dout != 'h0) begin
                     state_next = PROCESS_CTRL_HDR;
                     count_next = 'd1;
                  end
               end
            end // case: PAYLOAD
   
   
         endcase // case(state)
      end // else
   end // always @ (*)+++++++

 //key[15:0] = ip_id[15:0];
 
    assign timestamp_high[31:0] = timestamp_reg_high [31:0]; 
    assign timestamp_low[31:0]  = timestamp_reg_low [31:0];
    assign ip_id_number[31:0]   = {ip_id2[15:0],ip_id[15:0]} ;
   // assign starting[31:0] =     {ip_id2[15:0],ip_id2[15:0]} ; 
                 
   always @(posedge clk) begin
      state <= state_next;
      count <= count_next;
   end

endmodule // monitor
