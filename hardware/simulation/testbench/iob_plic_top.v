`timescale 1ns / 1ps

module iob_plic_top #(
    parameter ADDR_W  = 16,
    parameter DATA_W  = 32,
    parameter SOURCES = 8,
    parameter TARGETS = 2
    ) (
    input                clk,
    input                rst,

    input                valid,
    input [ADDR_W-1:0]   address,
    input [DATA_W-1:0]   wdata,
    input [DATA_W/8-1:0] wstrb,
    output [DATA_W-1:0]  rdata,
    output               ready,

    input [SOURCES-1:0]  srip,
    output [TARGETS-1:0] meip
    );

`ifdef VCD
    initial begin
        $dumpfile("iob_plic.vcd");
        $dumpvars();
    end
`endif

    iob_plic #(
        //IOb-bus Parameters
        .ADDR_W(ADDR_W),
        .DATA_W(DATA_W),

        //PLIC Parameters
        .SOURCES          (SOURCES),
        .TARGETS          (TARGETS),
        .PRIORITIES       (8),
        .MAX_PENDING_COUNT(8),
        .HAS_THRESHOLD    (1),
        .HAS_CONFIG_REG   (1)
        )
    plic_ut (
        .clk(clk),
        .rst(rst),

        .valid(valid),
        .address(address),
        .wdata(wdata),
        .wstrb(wstrb),
        .rdata(rdata),
        .ready(ready),

        .src(srip),
        .irq(meip)
        );

endmodule
