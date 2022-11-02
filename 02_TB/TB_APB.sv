//////////////////////////////////////////////////////////////////////////
//  Copyright 2022 CastLab, KAIST. All rights reserved.
//
//  Name: TB_APB.sv
//  Description: This module testbench for freshman project 1.
//  Authors: JaeUk Kim <kju5789@kaist.ac.kr>
//  Version: 1.0
//  Date: 2022-01-04
//
//////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps

module TB_APB();
	import dma_pkg::*;

///////////////////////////////////////////////////////////////////
// Parameter
///////////////////////////////////////////////////////////////////
// Configuration register addr
parameter SRC_ADDR                  = 32'h00000000;
parameter DEST_ADDR                 = 32'h00000004;
parameter SIZE_ADDR                 = 32'h00000008;
parameter MODE_ADDR                 = 32'h0000000c;
parameter INT_ADDR                  = 32'h00000010;

// Clock period
parameter CLK_PERIOD                = 5; // 200 MHz


///////////////////////////////////////////////////////////////////
// Internal Signal Declaration
///////////////////////////////////////////////////////////////////
// APB module declaration
logic                               clk;
logic                               resetn;
logic [REG_ADDR_WIDTH-1:0]          apb_paddr;
logic                               apb_penable;
logic [REG_DATA_WIDTH-1:0]          apb_prdata;
logic                               apb_pready;
logic                               apb_psel;
logic                               apb_pslverr;
logic [REG_DATA_WIDTH-1:0]          apb_pwdata;
logic                               apb_pwrite;
logic                               apb_done;
logic [1:0]                         apb_verify;

// APB module interface declaration
logic [REG_DATA_WIDTH-1:0]          read_apb_prdata;
logic [REG_ADDR_WIDTH-1:0]          apb_addr;

// Memory
// Memory 0 Signal
logic								mem0_en;
logic [MEM_STRB_WIDTH	-1:0]		mem0_we;
logic [MEM_ADDR_WIDTH	-1:0]		mem0_addr;
logic [MEM_DATA_WIDTH	-1:0]		mem0_wdata;
logic [MEM_DATA_WIDTH	-1:0]		mem0_rdata;

// Memory 1 Signal
logic								mem1_en;
logic [MEM_STRB_WIDTH	-1:0]		mem1_we;
logic [MEM_ADDR_WIDTH	-1:0]		mem1_addr;
logic [MEM_DATA_WIDTH	-1:0]		mem1_wdata;
logic [MEM_DATA_WIDTH	-1:0]		mem1_rdata;


///////////////////////////////////////////////////////////////////
// APB Master
///////////////////////////////////////////////////////////////////
APB_master_intf apb_master
(
    .clk							( clk						),
    .m_apb_paddr					( apb_paddr					),
    .m_apb_penable					( apb_penable				),
    .m_apb_prdata					( apb_prdata				),
    .m_apb_pready					( apb_pready				),
    .m_apb_psel						( apb_psel					),
    .m_apb_pwdata					( apb_pwdata				),
    .m_apb_pwrite					( apb_pwrite				)
);

///////////////////////////////////////////////////////////////////
// DUT
///////////////////////////////////////////////////////////////////
DUT u_DUT (
	.CLK							( clk						),
    .RSTN							( resetn					),
    .INTR							( apb_done					),

    .PSEL							( apb_psel					),
    .PENABLE						( apb_penable				),
    .PREADY							( apb_pready				),
    .PWRITE							( apb_pwrite				),
    .PADDR							( apb_paddr					),
    .PWDATA							( apb_pwdata				),
    .PRDATA							( apb_prdata				),
	
	.mem0_en						( mem0_en					),
	.mem0_we						( mem0_we					),
	.mem0_addr						( mem0_addr					),
	.mem0_wdata						( mem0_wdata				),
	.mem0_rdata						( mem0_rdata				),
                                                 
	.mem1_en						( mem1_en					),
	.mem1_we						( mem1_we					),
	.mem1_addr						( mem1_addr					),
	.mem1_wdata						( mem1_wdata				),
	.mem1_rdata						( mem1_rdata				)

// FPGA Only, 00: Idle, 10: Success, 01: Fail
	,.led							( apb_verify				)
);


///////////////////////////////////////////////////////////////////
// Memory 0
///////////////////////////////////////////////////////////////////
Sram #(
	.AWIDTH							( MEM_ADDR_WIDTH			),
	.DWIDTH							( MEM_DATA_WIDTH			),
	.WSTRB							( MEM_STRB_WIDTH			),
	.INIT_FILE						( "mem0_init.mem"			)
) u_mem0 (
	.clk							( clk						),
	.en								( mem0_en					),
	.we								( mem0_we					),
	.addr							( mem0_addr					),
	.wrdata							( mem0_wdata				),
	.rddata							( mem0_rdata				)
);

///////////////////////////////////////////////////////////////////
// Memory 1
///////////////////////////////////////////////////////////////////
Sram #(
	.AWIDTH							( MEM_ADDR_WIDTH			),
	.DWIDTH							( MEM_DATA_WIDTH			),
	.WSTRB							( MEM_STRB_WIDTH			),
	.INIT_FILE						( "mem1_init.mem"			)
) u_mem1 (
	.clk							( clk						),
	.en								( mem1_en					),
	.we								( mem1_we					),
	.addr							( mem1_addr					),
	.wrdata							( mem1_wdata				),
	.rddata							( mem1_rdata				)
);

///////////////////////////////////////////////////////////////////
// Test
///////////////////////////////////////////////////////////////////
// Testbench clock declaration
initial begin
	clk = 1'b1;
    forever begin
        clk                                                     = #(CLK_PERIOD/2) ~clk;
    end
end

// Reset
initial begin
    resetn                                                      = 'b1;
    @(posedge clk);
    resetn                                                      = 'b0;
    repeat(10) @(posedge clk);
    resetn                                                      = 'b1; 
end

// Testbench
initial begin
    read_apb_prdata                                             = 'b0;
	apb_paddr													= 0;
	apb_penable													= 0;
	apb_psel													= 0;
	apb_pwrite													= 0;
	apb_pwdata													= 0;

	repeat(20) @(posedge clk);
    // [Test 1] APB verification
    // Write and read configuration register
    $display ("[Test 1] APB verification");
    apb_addr                                                    = 32'h00000000;
    for (int i=0; i<5; i++) begin
        apb_master.write(apb_addr, i);
        $display ("[APB] Write %h at %h", i, apb_addr);
        apb_master.read(apb_addr, read_apb_prdata);
        if (read_apb_prdata != i) begin
            $display ("Failure");
            $stop;
        end
        apb_addr                                                = apb_addr + 'd4;
    end
    $display ("Success");

    // Reset configuration register
    apb_addr                                                    = 32'h00000000;
    for (int i=0; i<5; i++) begin
        apb_master.write(apb_addr, 32'h00000000);
        apb_addr                                                = apb_addr + 'd4;
    end

    // [Test 2] DMA verification
    $display ("[Test 2] DMA verification");

    // Configure source register
    apb_master.write(SRC_ADDR, 32'h00100007);
    $display ("[Src Setting] Set source address as %h", 32'h00100007);

    // Configure destination register
    apb_master.write(DEST_ADDR, 32'h00200002);
    $display ("[Dest Setting] Set dest address as %h", 32'h00200002);

    // Configure size register
    apb_master.write(SIZE_ADDR, 11);
    $display ("[Size Setting] Set size as %h", 11);

    // Start DMA normal operation
    apb_master.write(MODE_ADDR, 0);
    apb_master.write(MODE_ADDR, 1);
    $display ("[DMA] Start normal DMA operation");

    wait (apb_done)
    apb_master.read(MODE_ADDR, read_apb_prdata);
    if (read_apb_prdata != 'd0) begin
        $display ("Mode 1 Reset Failure");
        $stop;
    end
   
	// FOR FPGA
    apb_master.write(MODE_ADDR, 2);
    wait (apb_verify)
    if (apb_verify == 'd1) begin
        $display ("DMA Failure");
    end
    else if (apb_verify == 'd2) begin
        $display ("DMA Success");
    end
    else begin
        $display ("DMA Failure");
    end
    apb_master.read(MODE_ADDR, read_apb_prdata);
    if (read_apb_prdata != 'd0) begin
        $display ("Mode 2 Reset Failure");
        $stop;
    end
    
    $finish();

end
 
endmodule
