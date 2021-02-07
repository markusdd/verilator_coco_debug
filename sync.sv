//NOT FOR REDISTRIBUTION AND PRACTICAL USE IN ANY DESIGNS, ONLY FOR COCOTB/VERILTOR INTERACTION DEGUGGING

module sync #(
  parameter RST_VAL = 1'b0
) (
  input logic clk_i,
  input logic rst_an_i,
  input logic d_i,
  output logic d_o
);

  logic d0_r;
  logic d1_r;

  always_ff @(posedge clk_i or negedge rst_an_i) begin : sync_proc
    if (rst_an_i == 1'b0) begin
      d0_r <= RST_VAL;
      d1_r <= RST_VAL;
    end else begin
      d0_r <= d_i;
      d1_r <= d0_r;
    end
  end

  assign d_o = d1_r;

endmodule
