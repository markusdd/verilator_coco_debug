module debug_verilator_coco (
  input clk_w_i,
  input rst_w_an_i,
  input wen_i,
  input [31:0] wdata_i,
  input clk_r_i,
  input rst_r_an_i,
  input ren_i,
  output full_o,
  output [31:0] rdata_o,
  output empty_o
);

  //THIS IS A DEBUG DESIGN, NOT A FUNCTIONAL FIFO!!!

  localparam DATA_WIDTH = 32;
  localparam DEPTH = 16;
  localparam RDATA_REG = 1;
  localparam ADDR_WIDTH_P = $clog2(DEPTH);

  logic [DATA_WIDTH-1:0] fifo_mem_r [DEPTH-1:0];
  logic [DATA_WIDTH-1:0] rdata_r;

  logic full_s;
  logic full_r;
  logic empty_s;
  logic empty_r;

  logic [ADDR_WIDTH_P:0] wpointer_next_s;
  logic [ADDR_WIDTH_P:0] wpointer_r;

  logic [ADDR_WIDTH_P:0] rpointer_next_s;
  logic [ADDR_WIDTH_P:0] rpointer_r;

  assign empty_o = 1'b0;
  assign full_o = 1'b0;

  always @(posedge clk_w_i) begin : fifo_mem_w_proc
    if (wen_i == 1'b1) begin
      fifo_mem_r[wpointer_r[ADDR_WIDTH_P-1:0]] <= wdata_i;
    end
  end

  always @(posedge clk_r_i) begin : fifo_mem_r_proc
    if (ren_i == 1'b1) begin
      rdata_r <= fifo_mem_r[rpointer_r[ADDR_WIDTH_P-1:0]];
    end
  end

  assign rdata_o = rdata_r;

  always @(*) begin : pointer_next_proc
    rpointer_next_s = rpointer_r + {{ADDR_WIDTH_P{1'b0}}, 1'b1 & ren_i};
    wpointer_next_s = wpointer_r + {{ADDR_WIDTH_P{1'b0}}, 1'b1 & wen_i};
  end

  always @(posedge clk_w_i or negedge rst_w_an_i) begin : w_pointer_proc
    if (rst_w_an_i == 1'b0) begin
      wpointer_r <= {ADDR_WIDTH_P+1{1'b0}};
    end else if (wen_i == 1'b1) begin
      wpointer_r <= wpointer_next_s;
    end
  end

  always @(posedge clk_r_i or negedge rst_r_an_i) begin : r_pointer_proc
    if (rst_r_an_i == 1'b0) begin
      rpointer_r <= {ADDR_WIDTH_P+1{1'b0}};
    end else if (ren_i == 1'b1) begin
      rpointer_r <= rpointer_next_s;
    end
  end

endmodule