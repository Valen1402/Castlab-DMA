`timescale 1ns / 1ps

module DUT
    import dma_pkg::*;
(
    input  logic                                                    CLK,
    input  logic                                                    RSTN,
    output logic                                                    INTR,
    output logic [1:0]                                              led,

    input  logic                                                    PSEL,
    input  logic                                                    PENABLE,
    output logic                                                    PREADY,
    input  logic                                                    PWRITE,
    input  logic [REG_ADDR_WIDTH-1:0]                               PADDR,
    input  logic [REG_DATA_WIDTH-1:0]                               PWDATA,
    output logic [REG_DATA_WIDTH-1:0]                               PRDATA,

    output logic                                                    mem0_en,
    output logic [MEM_STRB_WIDTH-1:0]                               mem0_we,
    output logic [MEM_ADDR_WIDTH-1:0]                               mem0_addr,
    output logic [MEM_DATA_WIDTH-1:0]                               mem0_wdata,
    input  logic [MEM_DATA_WIDTH-1:0]                               mem0_rdata,

    output logic                                                    mem1_en,
    output logic [MEM_STRB_WIDTH-1:0]                               mem1_we,
    output logic [MEM_ADDR_WIDTH-1:0]                               mem1_addr,
    output logic [MEM_DATA_WIDTH-1:0]                               mem1_wdata,
    input  logic [MEM_DATA_WIDTH-1:0]                               mem1_rdata
);
    logic [1:0]                                                     command_gen_mode,
    logic                                                           command_gen_done,
    logic [MEM_DATA_WIDTH-1:0]                                      r_src_addr,
    logic [MEM_DATA_WIDTH-1:0]                                      r_dest_addr,
    logic [MEM_DATA_WIDTH-1:0]                                      r_size
    logic [REG_DATA_WIDTH-1:0]                                      r_mode;
    logic [REG_DATA_WIDTH-1:0]                                      r_intr;
    logic [1:0]                                                     led_value;

    assign command_gen_mode = r_mode[1:0];

    command_gen u_command_gen 
    (CLK, RSTN, command_gen_mode, command_gen_done, led_value,
    r_src_addr, r_dest_addr, r_size,
    mem0_en, mem0_we, mem0_addr, mem0_wdata, mem0_rdata,
    mem1_en, mem1_we, mem1_addr, mem1_wdata, mem1_rdata);

    always_ff@ (posedge CLK) begin
        if(~RSTN) begin
            INTR            <= 0;
            PREADY          <= 0;
            PRDATA          <= 0;

            r_src_addr      <= 0;
            r_dest_addr     <= 0;
            r_size          <= 0;
            r_mode          <= 0;
            r_intr          <= 0;
            led             <= 0;

        end else begin
            if (PREADY) begin
                PREADY      <= 0;
                if (INTR) begin
                    INTR    <= 0;
                end
            end
            else if (PSEL & PENABLE) begin
                if (PWRITE) begin           //write
                    if          (PADDR == 32'h00000000) begin    // source address
                        r_src_addr  <= PWDATA;
                        PREADY          <= 1;
                    end else if (PADDR == 32'h00000004) begin    // dest addr
                        r_dest_addr <= PWDATA;
                        PREADY          <= 1;
                    end else if (PADDR == 32'h00000008) begin    // size
                        r_size      <= PWDATA;
                        PREADY          <= 1;
                    end else if (PADDR == 32'h0000000c) begin    // mode
                        r_mode      <= PWDATA;
                        PREADY          <= 1;
                    end else if (PADDR == 32'h00000010) begin    // interrupt
                        r_intr      <= PWDATA;
                        PREADY          <= 1;
                    end

                end else begin              //read
                    if          (PADDR == 32'h00000000) begin
                        PRDATA      <= r_src_addr;
                        PREADY          <= 1;
                    end else if (PADDR == 32'h00000004) begin
                        PRDATA      <= r_dest_addr;
                        PREADY          <= 1;
                    end else if (PADDR == 32'h00000008) begin
                        PRDATA      <= r_size;
                        PREADY          <= 1;
                    end else if (PADDR == 32'h0000000c) begin
                        PRDATA      <= r_mode;
                        PREADY          <= 1;
                    end else if (PADDR == 32'h00000010) begin
                        PRDATA      <= r_intr;
                        PREADY          <= 1;
                    end
                end
            end

            else if  (r_mode == 1) begin
                if (command_gen_done) begin
                    INTR        <= 1;
                    PREADY      <= 1;
                    r_mode      <= 0;
                end
            end else if (r_mode == 2) begin
                if (command_gen_done) begin
                    INTR        <= 1;
                    PREADY      <= 1;
                    r_mode      <= 0;
                    led         <= led_value;
                end
            end
        end
    end
endmodule
