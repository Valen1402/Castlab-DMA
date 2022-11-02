//////////////////////////////////////////////////////////////////////////
//  Copyright 2022 CastLab, KAIST. All rights reserved.
//
//  Name: APB_master.sv
//  Description: This module is APB master for freshman project 1.
//  Authors: JaeUk Kim <kju5789@kaist.ac.kr>
//  Version: 1.0
//  Date: 2022-01-04
//
//////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps

interface APB_master_intf
	import dma_pkg::*;
(
    input  logic                                                    clk,
    output logic [REG_ADDR_WIDTH-1:0]                               m_apb_paddr,
    output logic                                                    m_apb_penable,
    input  logic [REG_DATA_WIDTH-1:0]                               m_apb_prdata,
    input  logic                                                    m_apb_pready,
    output logic                                                    m_apb_psel,
    output logic [REG_DATA_WIDTH-1:0]                               m_apb_pwdata,
    output logic                                                    m_apb_pwrite
);

    task automatic write (
        input  logic [REG_ADDR_WIDTH-1:0]                           apb_paddr,
        input  logic [REG_DATA_WIDTH-1:0]                           apb_pwdata
    );

        @(posedge clk);
        // SETUP state
        m_apb_psel                                                  = 'b1;
        m_apb_pwrite                                                = 'b1;
        m_apb_paddr                                                 = apb_paddr;
        m_apb_pwdata                                                = apb_pwdata;

        @(posedge clk);
        // ACCESS state
        m_apb_penable                                               = 'b1;

        wait(m_apb_pready);

        @(posedge clk);
        m_apb_psel                                                  = 'b0;
        m_apb_penable                                               = 'b0;
        //$display ("APB: [%0dns] Inst: write    Addr: %h    Data: %h", $time, apb_paddr, apb_pwdata);

    endtask

    task automatic read (
        input  logic [REG_ADDR_WIDTH-1:0]                           apb_paddr,
        output logic [REG_DATA_WIDTH-1:0]                           apb_prdata
    );

        @(posedge clk);
        // SETUP state
        m_apb_psel                                                  = 'b1;
        m_apb_pwrite                                                = 'b0;
        m_apb_paddr                                                 = apb_paddr;

        @(posedge clk);
        m_apb_penable                                               = 'b1;

        wait(m_apb_pready);

        @(posedge clk);
        apb_prdata                                                  = m_apb_prdata;
        m_apb_psel                                                  = 'b0;
        m_apb_penable                                               = 'b0;
        //$display ("APB: [%0dnx] Inst: read    Addr: %h    Data: %h", $time, apb_paddr, apb_prdata);

    endtask

endinterface
