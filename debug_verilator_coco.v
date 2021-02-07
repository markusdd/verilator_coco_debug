//NOT FOR REDISTRIBUTION AND PRACTICAL USE IN ANY DESIGNS, ONLY FOR COCOTB/VERILTOR INTERACTION DEGUGGING

module debug_verilator_coco #(
  parameter DATA_WIDTH = 42,
  parameter DEPTH = 16,
  parameter RDATA_REG = 1
) (
  //write side
  input logic clk_w_i,
  input logic rst_w_an_i,
  input logic wen_i,
  input logic [DATA_WIDTH-1:0] wdata_i,
  output logic full_o,
  output logic werr_o,
  //read side
  input logic clk_r_i,
  input logic rst_r_an_i,
  input logic ren_i,
  output logic [DATA_WIDTH-1:0] rdata_o,
  output logic empty_o,
  output logic rerr_o
);

  //declarations
  localparam ADDR_WIDTH_P = $clog2(DEPTH);

  logic [DATA_WIDTH-1:0] fifo_mem_r [DEPTH-1:0];
  logic [DATA_WIDTH-1:0] rdata_r;

  logic full_s;
  logic full_r;
  logic empty_s;
  logic empty_r;

  logic [ADDR_WIDTH_P:0] bin_wpointer_next_s;
  logic [ADDR_WIDTH_P:0] gray_wpointer_next_s;
  logic [ADDR_WIDTH_P:0] bin_wpointer_r;
  logic [ADDR_WIDTH_P:0] gray_wpointer_r;
  logic [ADDR_WIDTH_P:0] gray_wpointer_sync_s;

  logic [ADDR_WIDTH_P:0] bin_rpointer_next_s;
  logic [ADDR_WIDTH_P:0] gray_rpointer_next_s;
  logic [ADDR_WIDTH_P:0] bin_rpointer_r;
  logic [ADDR_WIDTH_P:0] gray_rpointer_r;
  logic [ADDR_WIDTH_P:0] gray_rpointer_sync_s;

  always_ff @(posedge clk_w_i) begin : fifo_mem_w_proc
    if ((wen_i == 1'b1) && (full_r == 1'b0)) begin
      fifo_mem_r[bin_wpointer_r[ADDR_WIDTH_P-1:0]] <= wdata_i;
    end
  end

  if (RDATA_REG == 1) begin
    always_ff @(posedge clk_r_i) begin : fifo_mem_r_proc
      if (ren_i == 1'b1) begin
         rdata_r <= fifo_mem_r[bin_rpointer_r[ADDR_WIDTH_P-1:0]];
      end
    end

    assign rdata_o = rdata_r;
  end else if (RDATA_REG == 0) begin
    assign rdata_o = fifo_mem_r[bin_rpointer_r[ADDR_WIDTH_P-1:0]];
  end else begin
    $error("SVB IP ERROR: RDATA_REG parameter has to be either 0 or 1.");
  end

  always_comb begin : pointer_next_proc
      bin_rpointer_next_s = bin_rpointer_r + {{ADDR_WIDTH_P{1'b0}}, 1'b1 & ren_i & ~empty_r};
      gray_rpointer_next_s = (bin_rpointer_next_s>>1) ^ bin_rpointer_next_s;
      bin_wpointer_next_s = bin_wpointer_r + {{ADDR_WIDTH_P{1'b0}}, 1'b1 & wen_i & ~full_r};
      gray_wpointer_next_s = (bin_wpointer_next_s>>1) ^ bin_wpointer_next_s;
      empty_s = (gray_rpointer_next_s == gray_wpointer_sync_s);
      full_s = (gray_wpointer_next_s == {~gray_rpointer_sync_s[ADDR_WIDTH_P:ADDR_WIDTH_P-1],
                                          gray_rpointer_sync_s[ADDR_WIDTH_P-2:0]});
  end

  always_ff @(posedge clk_w_i or negedge rst_w_an_i) begin : w_pointer_proc
    if (rst_w_an_i == 1'b0) begin
      bin_wpointer_r <= {ADDR_WIDTH_P+1{1'b0}};
      gray_wpointer_r <= {ADDR_WIDTH_P+1{1'b0}};
    end else if ((wen_i == 1'b1) && (full_r == 1'b0)) begin
      bin_wpointer_r <= bin_wpointer_next_s;
      gray_wpointer_r <= gray_wpointer_next_s;
    end
  end

  always_ff @(posedge clk_r_i or negedge rst_r_an_i) begin : r_pointer_proc
    if (rst_r_an_i == 1'b0) begin
      bin_rpointer_r <= {ADDR_WIDTH_P+1{1'b0}};
      gray_rpointer_r <= {ADDR_WIDTH_P+1{1'b0}};
    end else if ((ren_i == 1'b1) && (empty_r == 1'b0)) begin
      bin_rpointer_r <= bin_rpointer_next_s;
      gray_rpointer_r <= gray_rpointer_next_s;
    end
  end

  always_ff @(posedge clk_r_i or negedge rst_r_an_i) begin : proc_empty
    if(rst_r_an_i == 1'b0) begin
      empty_r <= 1'b1;
      rerr_o <= 1'b0;
    end else begin
      empty_r <= empty_s;
      rerr_o <= ren_i & empty_r;
    end
  end

  assign empty_o = empty_r;

  always_ff @(posedge clk_w_i or negedge rst_w_an_i) begin : proc_full
    if(rst_w_an_i == 1'b0) begin
      full_r <= 1'b0;
      werr_o <= 1'b0;
    end else begin
      full_r <= full_s;
      werr_o <= wen_i & full_r;
    end
  end

  assign full_o = full_r;

  genvar i;
  generate
    for (i = 0; i<=ADDR_WIDTH_P; i++) begin : pointer_sync_gen

      sync #(
        .RST_VAL (1'b0)
      ) u_svb_sync_gray_wpointer (
        .clk_i    (clk_r_i                ),
        .rst_an_i (rst_r_an_i             ),
        .d_i      (gray_wpointer_r[i]     ),
        .d_o      (gray_wpointer_sync_s[i])
      );

      sync #(
        .RST_VAL (1'b0)
      ) u_svb_sync_gray_rpointer (
        .clk_i    (clk_w_i                ),
        .rst_an_i (rst_w_an_i             ),
        .d_i      (gray_rpointer_r[i]     ),
        .d_o      (gray_rpointer_sync_s[i])
      );

    end
  endgenerate

endmodule