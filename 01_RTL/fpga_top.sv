// +FHDR------------------------------------------------------------
//                 Copyright (c) 2022 .
//                       ALL RIGHTS RESERVED
// -----------------------------------------------------------------
// Filename      : fpga_top.sv
// Author        : 
// Created On    : 2022-01-11 11:02
// Last Modified : 
// -----------------------------------------------------------------
// Description:
//
//
// -FHDR------------------------------------------------------------

module fpga_top
	import dma_pkg::*;
(
	input	logic 					pcie_refclk_clk_n,
	input	logic 					pcie_refclk_clk_p,
	input	logic					pcie_perstn,
	
	input	logic [16	-1:0]		pci_express_x16_rxn,
	input	logic [16	-1:0]		pci_express_x16_rxp,
	output	logic [16	-1:0]		pci_express_x16_txn,
	output	logic [16	-1:0]		pci_express_x16_txp,

	output	logic [3	-1:0]		led						// [0]: Operation Finish, [1]: Test Mode Fail, [2]: Test Mode Success
);


///////////////////////////////////////////////////////////////////
// Internal Signal Declaration
///////////////////////////////////////////////////////////////////
// Internal Clock & Reset
// Clock Frequency : 200MHz
logic								w_clock;
logic								w_rstn;

// APB Bus Signal
logic [REG_ADDR_WIDTH	-1:0]		w_apb_paddr;
logic								w_apb_penable;
logic [REG_DATA_WIDTH	-1:0]		w_apb_prdata;
logic								w_apb_pready;
logic								w_apb_psel;
logic [REG_DATA_WIDTH	-1:0]		w_apb_pwdata;
logic								w_apb_pwrite;

// Memory
// Memory 0 Signal
logic								w_mem0_en;
logic [MEM_STRB_WIDTH	-1:0]		w_mem0_we;
logic [MEM_ADDR_WIDTH	-1:0]		w_mem0_addr;
logic [MEM_DATA_WIDTH	-1:0]		w_mem0_wdata;
logic [MEM_DATA_WIDTH	-1:0]		w_mem0_rdata;

// Memory 1 Signal
logic								w_mem1_en;
logic [MEM_STRB_WIDTH	-1:0]		w_mem1_we;
logic [MEM_ADDR_WIDTH	-1:0]		w_mem1_addr;
logic [MEM_DATA_WIDTH	-1:0]		w_mem1_wdata;
logic [MEM_DATA_WIDTH	-1:0]		w_mem1_rdata;


///////////////////////////////////////////////////////////////////
// SHELL
///////////////////////////////////////////////////////////////////
shell_wrapper u_shell_wrapper (
	.pci_express_x16_rxn			( pci_express_x16_rxn		),		// i
	.pci_express_x16_rxp			( pci_express_x16_rxp		),		// i
	.pci_express_x16_txn			( pci_express_x16_txn		),		// o
	.pci_express_x16_txp			( pci_express_x16_txp		),		// o
	.pcie_perstn					( pcie_perstn				),		// i
	.pcie_refclk_clk_n				( pcie_refclk_clk_n			),		// i
	.pcie_refclk_clk_p				( pcie_refclk_clk_p			),		// i
	.usr_irq_req_0					( 1'b0						),		// i
	.usr_rtl_apb_paddr				( w_apb_paddr				),		// o
	.usr_rtl_apb_penable			( w_apb_penable				),		// o
	.usr_rtl_apb_pprot				(							),		// o, NOT SUPPORTED
	.usr_rtl_apb_prdata				( w_apb_prdata				),		// i
	.usr_rtl_apb_pready				( w_apb_pready				),		// i
	.usr_rtl_apb_psel				( w_apb_psel				),		// o
	.usr_rtl_apb_pslverr			( 1'b0						),		// i, NOT SUPPORTED
	.usr_rtl_apb_pstrb				(							),		// o, NOT SUPPORTED
	.usr_rtl_apb_pwdata				( w_apb_pwdata				),		// o
	.usr_rtl_apb_pwrite				( w_apb_pwrite				),		// o
	.usr_rtl_clock					( w_clock					),		// o
	.usr_rtl_rstn					( w_rstn					)		// o
);


///////////////////////////////////////////////////////////////////
// DUT
///////////////////////////////////////////////////////////////////
DUT u_DUT (
	.CLK							( w_clock					),		// i
    .RSTN							( w_rstn					),		// i
    .INTR							( led[0]					),		// o

    .PSEL							( w_apb_psel				),		// i
    .PENABLE						( w_apb_penable				),		// i
    .PREADY							( w_apb_pready				),		// o
    .PWRITE							( w_apb_pwrite				),		// i
    .PADDR							( w_apb_paddr				),		// i
    .PWDATA							( w_apb_pwdata				),		// i
    .PRDATA							( w_apb_prdata				),		// o
	
	.mem0_en						( w_mem0_en					),		// o
	.mem0_we						( w_mem0_we					),		// o
	.mem0_addr						( w_mem0_addr				),		// o
	.mem0_wdata						( w_mem0_wdata				),		// o
	.mem0_rdata						( w_mem0_rdata				),		// i
                                                 
	.mem1_en						( w_mem1_en					),		// o
	.mem1_we						( w_mem1_we					),		// o
	.mem1_addr						( w_mem1_addr				),		// o
	.mem1_wdata						( w_mem1_wdata				),		// o
	.mem1_rdata						( w_mem1_rdata				),		// i

	.led							( led[2:1]					)		// o
);


///////////////////////////////////////////////////////////////////
// Memory 0
///////////////////////////////////////////////////////////////////
blk_mem_gen_0 u_mem0 (
	.clka							( w_clock					),
	.ena							( w_mem0_en					),
	.wea							( w_mem0_we					),
	.addra							( w_mem0_addr				),
	.dina							( w_mem0_wdata				),
	.douta							( w_mem0_rdata				)
);

///////////////////////////////////////////////////////////////////
// Memory 1
///////////////////////////////////////////////////////////////////
blk_mem_gen_1 u_mem1 (
	.clka							( w_clock					),
	.ena							( w_mem1_en					),
	.wea							( w_mem1_we					),
	.addra							( w_mem1_addr				),
	.dina							( w_mem1_wdata				),
	.douta							( w_mem1_rdata				)
);



endmodule
