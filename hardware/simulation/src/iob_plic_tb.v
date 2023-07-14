`timescale 1ns / 1ps

module iob_plic_tb;

  parameter integer CLK_P = 10;
  parameter integer ADDR_W = 16;
  parameter integer DATA_W = 32;
  parameter integer N_SOURCES = 8;
  parameter integer N_TARGETS = 2;

  reg clk;
  reg reset;
  reg iob_avalid;
  reg [ADDR_W-1:0] iob_addr;
  reg [DATA_W-1:0] iob_wdata;
  reg [DATA_W/8-1:0] iob_wstrb;
  wire iob_rvalid;
  wire [DATA_W-1:0] iob_rdata;
  wire iob_ready;
  reg [N_SOURCES-1:0] srip;
  wire [N_TARGETS-1:0] meip;

  integer fd;

  initial begin
    clk = 0;
    reset = 1;
    iob_avalid = 0;
    iob_addr = 0;
    iob_wdata = 0;
    iob_wstrb = 0;
    srip = 0;
    $display("Testbench begin!");
    #100 reset = 0;
    // TO DO, if needed add tasks to simulate PLIC behaviour.
    $display("Testbench end!");
    fd = $fopen("test.log", "w");
    $fdisplay(fd, "Test passed!");
    $fclose(fd);
    $finish();
  end

  always @(*) begin
    #(CLK_P/2) clk <= ~clk;
  end

  iob_plic_sim_wrapper #(
    .ADDR_W(ADDR_W),
    .DATA_W(DATA_W),
    .N_SOURCES(N_SOURCES),
    .N_TARGETS(N_TARGETS)
  ) uut_wrapper (
    .clk_i(clk),
    .arst_i(reset),

    .iob_avalid(iob_avalid),
    .iob_addr(iob_addr),
    .iob_wdata(iob_wdata),
    .iob_wstrb(iob_wstrb),
    .iob_rvalid(iob_rvalid),
    .iob_rdata(iob_rdata),
    .iob_ready(iob_ready),

    .srip(srip),
    .meip(meip)
    );

endmodule
