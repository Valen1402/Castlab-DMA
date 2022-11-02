module command_gen
    import dma_pkg::*;
(
    input  logic                                                    CLK,
    input  logic                                                    RSTN,
    input  logic [1:0]                                              MODE,
    output logic                                                    READY,

    output logic [1:0]                                              led,

    input  logic [REG_DATA_WIDTH-1:0]                               src_addr,
    input  logic [REG_DATA_WIDTH-1:0]                               dest_addr,
    input  logic [REG_DATA_WIDTH-1:0]                               size,

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
    logic                                                           mem0_en_nxt;
    logic                                                           mem1_en_nxt;
    logic [MEM_STRB_WIDTH-1:0]                                      mem0_we_nxt;
    logic [MEM_STRB_WIDTH-1:0]                                      mem1_we_nxt;
    logic [MEM_ADDR_WIDTH-1:0]                                      mem0_addr_nxt;
    logic [MEM_ADDR_WIDTH-1:0]                                      mem1_addr_nxt;

    logic  [REG_DATA_WIDTH-17:0]                                    src_end;
    logic  [REG_DATA_WIDTH-17:0]                                    dest_end;
    logic  [1:0]                                                    src_offset;
    logic  [1:0]                                                    src_offset_pre;
    logic  [1:0]                                                    dest_offset;
    logic  [1:0]                                                    dest_offset_nxt;
    logic  [1:0]                                                    dest_offset_nxtnxt;
    logic                                                           src_read_start;
    logic                                                           dest_write_start;
    logic                                                           src_read_done;
    logic                                                           dest_write_done;

    logic  [3*REG_DATA_WIDTH-1: 0]                                  EXPECTED_DATA;

    always_ff@ (posedge CLK) begin

        if (~RSTN) begin // re do
            READY           <= 0;

            mem0_en         <= 0;   mem0_en_nxt     <= 0;
            mem0_addr       <= 0;   mem0_addr_nxt   <= 0;
            mem0_wdata      <= 0;
            mem1_en         <= 0;   mem1_en_nxt     <= 0;
            mem1_addr       <= 0;   mem1_addr_nxt   <= 0;
            mem1_wdata      <= 0;

            src_end         <= 0;
            src_offset      <= 0;   src_offset_pre  <= 0;
            dest_end        <= 0;
            dest_offset     <= 0;   dest_offset_nxt <= 0;   dest_offset_nxtnxt <= 0;

            src_read_start  <= 0;
            dest_write_start<= 0;
            src_read_done   <= 0;
            dest_write_done <= 0;
            led             <= 0;
            EXPECTED_DATA   <= 'h00005f5e5d5c5b5a595857;

        end else if (MODE == 2'b01) begin
            src_end         <= src_addr[REG_DATA_WIDTH-17:0] + size -1;
            dest_end        <= dest_addr[REG_DATA_WIDTH-17:0] + size -1;
            src_offset_pre  <= src_offset;
            dest_offset     <= dest_offset_nxt;
            dest_offset_nxt <= dest_offset_nxtnxt;
            src_read_start  <= 1;
            READY           <= 0;


                // mem0 to mem 1 transfer
            if (src_addr [REG_DATA_WIDTH-1:REG_DATA_WIDTH-16] == 16'h0010
                    && dest_addr [REG_DATA_WIDTH-1:REG_DATA_WIDTH-16] == 16'h0020) begin
                
                if(~src_read_start) begin  //enable mem0 next cycle - setup first mem0
                    mem0_en                     <= 1;
                    mem0_we                     <= 0;
                    mem0_addr                   <= src_addr[REG_DATA_WIDTH-17:2];
                    src_offset                  <= src_addr[1:0];
                    dest_offset_nxtnxt          <= dest_addr[1:0];

                end else begin          //mem0 is enable                    
                    mem1_en                     <= mem1_en_nxt;
                    mem1_we                     <= mem1_we_nxt;
                    mem1_addr                   <= mem1_addr_nxt;

                    if (dest_write_start) begin
                    /*    if (src_offset_pre == dest_offset_nxt)
                            mem1_wdata          <= mem0_rdata;
                        else if (src_offset_pre > dest_offset_nxt) begin
                            mem1_wdata          <= (mem0_rdata >> 8*(src_offset_pre - dest_offset_nxt));
            
                        end else begin
                            mem1_wdata          <= (mem0_rdata << 8*(dest_offset_nxt - src_offset_pre));
                            
                        end */
                        case (src_offset_pre)
                        2'b00:
                            case (dest_offset_nxt)
                                2'b00: mem1_wdata   <= mem0_rdata;
                                2'b01: mem1_wdata   <= {mem0_rdata[23:0], 8'b0};
                                2'b10: mem1_wdata   <= {mem0_rdata[15:0], 16'b0};
                                2'b11: mem1_wdata   <= {mem0_rdata[7:0], 24'b0};
                            endcase
                        2'b01:
                            case (dest_offset_nxt)
                                2'b00: mem1_wdata   <= mem0_rdata[31:8];
                                2'b01: mem1_wdata   <= mem0_rdata;
                                2'b10: mem1_wdata   <= {mem0_rdata[23:0], 8'b0};
                                2'b11: mem1_wdata   <= {mem0_rdata[15:0], 16'b0};
                            endcase
                        2'b10:
                            case (dest_offset_nxt)
                                2'b00: mem1_wdata   <= mem0_rdata[31:16];
                                2'b01: mem1_wdata   <= mem0_rdata[31:8];
                                2'b10: mem1_wdata   <= mem0_rdata;
                                2'b11: mem1_wdata   <= {mem0_rdata[23:0], 8'b0};
                            endcase
                        2'b11:
                            case (dest_offset_nxt)
                                2'b00: mem1_wdata   <= mem0_rdata[31:24];
                                2'b01: mem1_wdata   <= mem0_rdata[31:16];
                                2'b10: mem1_wdata   <= mem0_rdata[31:8];
                                2'b11: mem1_wdata   <= mem0_rdata;
                            endcase
                        endcase
                        

                    end

                    if (src_offset == dest_offset_nxtnxt) begin
                        if(~dest_write_start) begin
                            dest_write_start        <= 1;

                            mem1_en_nxt             <= 1;
                            mem1_addr_nxt           <= dest_addr[REG_DATA_WIDTH-17:2];
                            /*
                            if(size > MEM_STRB_WIDTH - dest_offset_nxtnxt) begin
                                mem0_addr           <= mem0_addr + 1;
                                src_offset          <= 2'b00;
                                dest_offset_nxtnxt  <= 2'b00;
                                //mem1_we_nxt         <= 4'b1111 << dest_offset_nxtnxt;
                                case(dest_offset_nxtnxt)
                                2'b00: mem1_we_nxt  <= 4'b1111;
                                2'b01: mem1_we_nxt  <= 4'b1110;
                                2'b10: mem1_we_nxt  <= 4'b1100;
                                2'b11: mem1_we_nxt  <= 4'b1000;
                                endcase
                            end else begin
                                src_read_done       <= 1;
                                mem0_en             <= 0;
                                mem0_addr           <= 0;
                            mem1_we_nxt         <= 4'b1111 >>(MEM_STRB_WIDTH-size) <<dest_offset_nxtnxt;
                            end
                            */
                            case(dest_offset_nxtnxt)
                                2'b00: case (size)
                                    'd1: begin 
                                        mem1_we         <= 4'b0001;
                                        src_read_done   <= 1;
                                        mem0_en         <= 0;
                                        mem0_addr       <= 0;
                                    end
                                    'd2: begin 
                                        mem1_we         <= 4'b0011;
                                        src_read_done   <= 1;
                                        mem0_en         <= 0;
                                        mem0_addr       <= 0;
                                    end
                                    'd3: begin
                                        mem1_we         <= 4'b0111;
                                        src_read_done   <= 1;
                                        mem0_en         <= 0;
                                        mem0_addr       <= 0;
                                    end
                                    'd4: begin
                                        mem1_we         <= 4'b1111;
                                        src_read_done   <= 1;
                                        mem0_en         <= 0;
                                        mem0_addr       <= 0;
                                    end
                                    default: begin
                                        mem0_addr           <= mem0_addr + 1;
                                        src_offset          <= 2'b00;
                                        dest_offset_nxtnxt  <= 2'b00;
                                        mem1_we_nxt         <= 4'b1111;
                                    end
                                    endcase

                                2'b01: case (size)
                                    'd1: begin 
                                        mem1_we         <= 4'b0010;
                                        src_read_done   <= 1;
                                        mem0_en         <= 0;
                                        mem0_addr       <= 0;
                                    end
                                    'd2: begin 
                                        mem1_we         <= 4'b0110;
                                        src_read_done   <= 1;
                                        mem0_en         <= 0;
                                        mem0_addr       <= 0;
                                    end
                                    'd3: begin
                                        mem1_we         <= 4'b1110;
                                        src_read_done   <= 1;
                                        mem0_en         <= 0;
                                        mem0_addr       <= 0;
                                    end
                                    default: begin
                                        mem0_addr           <= mem0_addr + 1;
                                        src_offset          <= 2'b00;
                                        dest_offset_nxtnxt  <= 2'b00;
                                        mem1_we_nxt         <= 4'b1110;
                                    end
                                    endcase

                                2'b10: case (size)
                                    'd1: begin 
                                        mem1_we         <= 4'b0100;
                                        src_read_done   <= 1;
                                        mem0_en         <= 0;
                                        mem0_addr       <= 0;
                                    end
                                    'd2: begin 
                                        mem1_we         <= 4'b1100;
                                        src_read_done   <= 1;
                                        mem0_en         <= 0;
                                        mem0_addr       <= 0;
                                    end
                                    default: begin
                                        mem0_addr           <= mem0_addr + 1;
                                        src_offset          <= 2'b00;
                                        dest_offset_nxtnxt  <= 2'b00;
                                        mem1_we_nxt         <= 4'b1100;
                                    end
                                    endcase

                                2'b11: case(size)
                                    'd1: begin 
                                        mem1_we         <= 4'b1000;
                                        src_read_done   <= 1;
                                        mem0_en         <= 0;
                                        mem0_addr       <= 0;
                                    end
                                    default: begin
                                        mem0_addr           <= mem0_addr + 1;
                                        src_offset          <= 2'b00;
                                        dest_offset_nxtnxt  <= 2'b00;
                                        mem1_we_nxt         <= 4'b1000;
                                    end
                                    endcase
                            endcase


                        end else begin //rdata is ready

                            if (dest_write_done) begin
                                READY               <= 0;
                                dest_write_done     <= 0;
                                src_read_start      <= 0;
                                dest_write_start    <= 0;
                                mem1_wdata          <= 0;

                            end else if (src_read_done) begin
                                mem1_en_nxt         <= 0;
                                mem1_we_nxt         <= 0;
                                mem1_addr_nxt       <= 0;
                                dest_write_done     <= 1;
                                src_read_done       <= 0;
                                READY               <= 1;

                            end else if (mem1_addr_nxt + 1 < dest_end[REG_DATA_WIDTH-17:2]) begin
                                src_offset          <= 2'b00;
                                mem1_addr_nxt       <= mem1_addr_nxt + 1;
                                dest_offset_nxtnxt  <= 2'b00;
                                mem1_we_nxt         <= 4'b1111;
                                mem0_addr           <= mem0_addr + 1; 

                            end else begin
                                mem1_addr_nxt       <= mem1_addr_nxt + 1;
                                src_read_done       <= 1;
                                mem0_en             <= 0;
                                mem0_addr           <= 0;
                                //mem1_we_nxt         <= 4'b1111 >> (MEM_STRB_WIDTH-dest_end[1:0]-1);
                                case (dest_end[1:0])
                                2'b00: mem1_we_nxt  <= 4'b0001;
                                2'b01: mem1_we_nxt  <= 4'b0011;
                                2'b10: mem1_we_nxt  <= 4'b0111;
                                2'b11: mem1_we_nxt  <= 4'b1111;
                                endcase
                            end
                        end



                    end else if (src_offset < dest_offset_nxtnxt) begin
                        if(~dest_write_start) begin
                            dest_write_start        <= 1;
                            mem1_en_nxt             <= 1;
                            mem1_addr_nxt           <= dest_addr[REG_DATA_WIDTH-17:2];
                        /*
                            if(size > MEM_STRB_WIDTH - dest_offset_nxtnxt) begin
                                src_offset          <= src_offset + MEM_STRB_WIDTH - dest_offset_nxtnxt;
                                mem1_we_nxt         <= 4'b1111 << dest_offset_nxtnxt;
                                dest_offset_nxtnxt  <= 2'b00;
                            end else begin
                                mem1_we_nxt         <= 4'b1111 >>(MEM_STRB_WIDTH-size) <<dest_offset_nxtnxt;
                                src_read_done       <= 1;
                                mem0_en             <= 0;
                                mem0_addr           <= 0;
                            end
                        */
                            case(dest_offset_nxtnxt)
                                2'b01: case (size)
                                    'd1: begin 
                                        mem1_we         <= 4'b0010;
                                        src_read_done   <= 1;
                                        mem0_en         <= 0;
                                        mem0_addr       <= 0;
                                    end
                                    'd2: begin 
                                        mem1_we         <= 4'b0110;
                                        src_read_done   <= 1;
                                        mem0_en         <= 0;
                                        mem0_addr       <= 0;
                                    end
                                    'd3: begin
                                        mem1_we         <= 4'b1110;
                                        src_read_done   <= 1;
                                        mem0_en         <= 0;
                                        mem0_addr       <= 0;
                                    end
                                    default: begin
                                        src_offset          <= 2'b01;
                                        dest_offset_nxtnxt  <= 2'b00;
                                        mem1_we_nxt         <= 4'b1110;
                                    end
                                    endcase

                                2'b10: case (size)
                                    'd1: begin 
                                        mem1_we         <= 4'b0100;
                                        src_read_done   <= 1;
                                        mem0_en         <= 0;
                                        mem0_addr       <= 0;
                                    end
                                    'd2: begin 
                                        mem1_we         <= 4'b1100;
                                        src_read_done   <= 1;
                                        mem0_en         <= 0;
                                        mem0_addr       <= 0;
                                    end
                                    default: begin
                                        src_offset          <= src_offset + 2;
                                        dest_offset_nxtnxt  <= 2'b00;
                                        mem1_we_nxt         <= 4'b1100;
                                    end
                                    endcase

                                2'b11: case(size)
                                    'd1: begin 
                                        mem1_we         <= 4'b1000;
                                        src_read_done   <= 1;
                                        mem0_en         <= 0;
                                        mem0_addr       <= 0;
                                    end
                                    default: begin
                                        src_offset          <= src_offset + 1;
                                        dest_offset_nxtnxt  <= 2'b00;
                                        mem1_we_nxt         <= 4'b1000;
                                    end
                                    endcase
                            endcase

                        end else begin //rdata is ready
                            if (dest_write_done) begin
                                READY               <= 0;
                                dest_write_done     <= 0;
                                src_read_start      <= 0;
                                dest_write_start    <= 0;
                                mem1_wdata          <= 0;

                            end else if (src_read_done) begin
                                mem1_en_nxt         <= 0;
                                mem1_we_nxt         <= 0;
                                mem1_addr_nxt       <= 0;
                                dest_write_done     <= 1;
                                src_read_done       <= 0;
                                READY               <= 1;

                            end else if ( mem1_addr_nxt < dest_end[REG_DATA_WIDTH-17:2]) begin
                                src_offset          <= src_offset + MEM_STRB_WIDTH - dest_offset_nxtnxt;
                                dest_offset_nxtnxt  <= 2'b00;
                                //mem1_we_nxt         <= 4'b1111 << dest_offset_nxtnxt;
                                case (dest_offset_nxtnxt)
                                2'b01: mem1_we_nxt  <= 4'b1110;
                                2'b10: mem1_we_nxt  <= 4'b1100;
                                2'b11: mem1_we_nxt  <= 4'b1000;
                                endcase

                            end else begin
                                //mem1_we_nxt         <= 4'b1111 >> (MEM_STRB_WIDTH -src_end[1:0] -1) <<dest_offset_nxtnxt;
                                case (src_end[1:0])
                                2'b00: case(dest_offset_nxtnxt)
                                    2'b01: mem1_we_nxt  <= 4'b0010;
                                    2'b10: mem1_we_nxt  <= 4'b0100;
                                    2'b11: mem1_we_nxt  <= 4'b1000;
                                    endcase
                                2'b01: case(dest_offset_nxtnxt)
                                    2'b01: mem1_we_nxt  <= 4'b0110;
                                    2'b10: mem1_we_nxt  <= 4'b1100;
                                    endcase
                                2'b10: mem1_we_nxt      <= 4'b1110;
                                endcase
                                src_read_done       <= 1;
                                mem0_en             <= 0;
                                mem0_addr           <= 0;
                            end
                        end


                    end else if (src_offset > dest_offset_nxtnxt) begin
                        if(~dest_write_start) begin
                            dest_write_start        <= 1;
                            mem1_en_nxt             <= 1;
                            mem1_addr_nxt           <= dest_addr[REG_DATA_WIDTH-17:2];

                        /*    if(size > MEM_STRB_WIDTH - src_offset) begin
                                mem0_addr           <= mem0_addr + 1;
                                src_offset          <= 2'b00;
                                mem1_we_nxt         <= 4'b1111 >> src_offset << dest_offset_nxtnxt;
                                dest_offset_nxtnxt  <= dest_offset_nxtnxt + MEM_STRB_WIDTH - src_offset;
                            end else begin
                                mem1_we_nxt         <= 4'b1111 >>(MEM_STRB_WIDTH-size) <<dest_offset_nxtnxt;
                                src_read_done       <= 1;
                                mem0_en             <= 0;
                                mem0_addr           <= 0;
                            end*/
                            
                            case(dest_offset_nxtnxt)
                                2'b00: case (size)
                                    'd1: begin 
                                        mem1_we         <= 4'b0001;
                                        src_read_done   <= 1;
                                        mem0_en         <= 0;
                                        mem0_addr       <= 0;
                                    end
                                    'd2: begin 
                                        mem1_we         <= 4'b0011;
                                        src_read_done   <= 1;
                                        mem0_en         <= 0;
                                        mem0_addr       <= 0;
                                    end
                                    'd3: begin
                                        mem1_we         <= 4'b0111;
                                        src_read_done   <= 1;
                                        mem0_en         <= 0;
                                        mem0_addr       <= 0;
                                    end
                                    default: begin
                                        mem0_addr           <= mem0_addr + 1;
                                        src_offset          <= 2'b00;
                                        case (src_offset)
                                        2'b01: begin
                                            mem1_we_nxt         <= 4'b0111;
                                            dest_offset_nxtnxt  <= 3;
                                            end
                                        2'b10: begin
                                            mem1_we_nxt         <= 4'b0011;
                                            dest_offset_nxtnxt  <= 2;
                                            end
                                        2'b11: begin
                                            mem1_we_nxt         <= 4'b0001;
                                            dest_offset_nxtnxt  <= 1;
                                            end
                                        endcase
                                    end
                                    endcase

                                2'b01: case (size)
                                    'd1: begin 
                                        mem1_we         <= 4'b0010;
                                        src_read_done   <= 1;
                                        mem0_en         <= 0;
                                        mem0_addr       <= 0;
                                    end
                                    'd2: begin 
                                        mem1_we         <= 4'b0110;
                                        src_read_done   <= 1;
                                        mem0_en         <= 0;
                                        mem0_addr       <= 0;
                                    end
                                    default: begin
                                        mem0_addr           <= mem0_addr + 1;
                                        src_offset          <= 2'b00;
                                        case (src_offset)
                                        2'b10: begin
                                            mem1_we_nxt         <= 4'b0110;
                                            dest_offset_nxtnxt  <= 3;
                                            end
                                        2'b11: begin
                                            mem1_we_nxt         <= 4'b0010;
                                            dest_offset_nxtnxt  <= 2;
                                            end
                                        endcase
                                    end
                                    endcase

                                2'b10: case (size)
                                    'd1: begin 
                                        mem1_we         <= 4'b0100;
                                        src_read_done   <= 1;
                                        mem0_en         <= 0;
                                        mem0_addr       <= 0;
                                    end
                                    default: begin
                                        mem0_addr           <= mem0_addr + 1;
                                        src_offset          <= 2'b00;
                                        mem1_we_nxt         <= 4'b0100;
                                        dest_offset_nxtnxt  <= 3;
                                    end
                                    endcase
                            endcase

                        end else begin //rdata is ready
                            if (dest_write_done) begin
                                READY               <= 0;
                                dest_write_done     <= 0;
                                src_read_start      <= 0;
                                dest_write_start    <= 0;
                                mem1_wdata          <= 0;

                            end else if (src_read_done) begin
                                mem1_en_nxt         <= 0;
                                mem1_we_nxt         <= 0;
                                mem1_addr_nxt       <= 0;
                                dest_write_done     <= 1;
                                src_read_done       <= 0;
                                READY               <= 1;

                            end else if (mem0_addr < src_end[REG_DATA_WIDTH-17:2]) begin
                                mem1_addr_nxt       <= mem1_addr_nxt + 1;
                                mem0_addr           <= mem0_addr + 1;
                                src_offset          <= 2'b00;
                                dest_offset_nxtnxt  <= dest_offset_nxtnxt + MEM_STRB_WIDTH - src_offset;
                                //mem1_we_nxt         <= 4'b1111 >> src_offset;
                                case (src_offset)
                                2'b01: mem1_we_nxt  <= 4'b0111;
                                2'b10: mem1_we_nxt  <= 4'b0011;
                                2'b11: mem1_we_nxt  <= 4'b0001;
                                endcase

                            end else begin
                                mem1_addr_nxt       <= mem1_addr_nxt + 1;
                                //mem1_we_nxt         <= 4'b1111 >> (MEM_STRB_WIDTH- dest_end[1:0]-1);
                                src_read_done       <= 1;
                                mem0_en             <= 0;
                                mem0_addr           <= 0;
                                case (dest_end[1:0])
                                2'b00: mem1_we_nxt  <= 4'b0001;
                                2'b01: mem1_we_nxt  <= 4'b0011;
                                2'b10: mem1_we_nxt  <= 4'b0111;
                                endcase
                            end
                        end
                    end
                
                end



                // mem1 to mem0 transfer
            end else if (src_addr [REG_DATA_WIDTH-1:REG_DATA_WIDTH-16] == 16'h0020
                        && dest_addr [REG_DATA_WIDTH-1:REG_DATA_WIDTH-16] == 16'h0010) begin
                
                if(~src_read_start) begin  //enable mem1 next cycle - setup first mem1
                    mem1_en                     <= 1;
                    mem1_we                     <= 0;
                    mem1_addr                   <= src_addr[REG_DATA_WIDTH-17:2];
                    src_offset                  <= src_addr[1:0];
                    dest_offset_nxtnxt          <= dest_addr[1:0];

                end else begin          //mem1 is enable                    
                    mem0_en                     <= mem0_en_nxt;
                    mem0_we                     <= mem0_we_nxt;
                    mem0_addr                   <= mem0_addr_nxt;

                    if (dest_write_start) begin
                    /*    if (src_offset_pre == dest_offset_nxt)
                            mem0_wdata          <= mem1_rdata;
                        else if (src_offset_pre > dest_offset_nxt) begin
                            mem0_wdata          <= (mem1_rdata >> 8*(src_offset_pre - dest_offset_nxt));
            
                        end else begin
                            mem0_wdata          <= (mem1_rdata << 8*(dest_offset_nxt - src_offset_pre));
                            
                        end */
                        case (src_offset_pre)
                        2'b00:
                            case (dest_offset_nxt)
                                2'b00: mem0_wdata   <= mem1_rdata;
                                2'b01: mem0_wdata   <= {mem1_rdata[23:0], 8'b0};
                                2'b10: mem0_wdata   <= {mem1_rdata[15:0], 16'b0};
                                2'b11: mem0_wdata   <= {mem1_rdata[7:0], 24'b0};
                            endcase
                        2'b01:
                            case (dest_offset_nxt)
                                2'b00: mem0_wdata   <= mem1_rdata[31:8];
                                2'b01: mem0_wdata   <= mem1_rdata;
                                2'b10: mem0_wdata   <= {mem1_rdata[23:0], 8'b0};
                                2'b11: mem0_wdata   <= {mem1_rdata[15:0], 16'b0};
                            endcase
                        2'b10:
                            case (dest_offset_nxt)
                                2'b00: mem0_wdata   <= mem1_rdata[31:16];
                                2'b01: mem0_wdata   <= mem1_rdata[31:8];
                                2'b10: mem0_wdata   <= mem1_rdata;
                                2'b11: mem0_wdata   <= {mem1_rdata[23:0], 8'b0};
                            endcase
                        2'b11:
                            case (dest_offset_nxt)
                                2'b00: mem0_wdata   <= mem1_rdata[31:24];
                                2'b01: mem0_wdata   <= mem1_rdata[31:16];
                                2'b10: mem0_wdata   <= mem1_rdata[31:8];
                                2'b11: mem0_wdata   <= mem1_rdata;
                            endcase
                        endcase
                        

                    end

                    if (src_offset == dest_offset_nxtnxt) begin
                        if(~dest_write_start) begin
                            dest_write_start        <= 1;

                            mem0_en_nxt             <= 1;
                            mem0_addr_nxt           <= dest_addr[REG_DATA_WIDTH-17:2];
                            /*
                            if(size > MEM_STRB_WIDTH - dest_offset_nxtnxt) begin
                                mem1_addr           <= mem1_addr + 1;
                                src_offset          <= 2'b00;
                                dest_offset_nxtnxt  <= 2'b00;
                                //mem0_we_nxt         <= 4'b1111 << dest_offset_nxtnxt;
                                case(dest_offset_nxtnxt)
                                2'b00: mem0_we_nxt  <= 4'b1111;
                                2'b01: mem0_we_nxt  <= 4'b1110;
                                2'b10: mem0_we_nxt  <= 4'b1100;
                                2'b11: mem0_we_nxt  <= 4'b1000;
                                endcase
                            end else begin
                                src_read_done       <= 1;
                                mem1_en             <= 0;
                                mem1_addr           <= 0;
                            mem0_we_nxt         <= 4'b1111 >>(MEM_STRB_WIDTH-size) <<dest_offset_nxtnxt;
                            end
                            */
                            case(dest_offset_nxtnxt)
                                2'b00: case (size)
                                    'd1: begin 
                                        mem0_we         <= 4'b0001;
                                        src_read_done   <= 1;
                                        mem1_en         <= 0;
                                        mem1_addr       <= 0;
                                    end
                                    'd2: begin 
                                        mem0_we         <= 4'b0011;
                                        src_read_done   <= 1;
                                        mem1_en         <= 0;
                                        mem1_addr       <= 0;
                                    end
                                    'd3: begin
                                        mem0_we         <= 4'b0111;
                                        src_read_done   <= 1;
                                        mem1_en         <= 0;
                                        mem1_addr       <= 0;
                                    end
                                    'd4: begin
                                        mem0_we         <= 4'b1111;
                                        src_read_done   <= 1;
                                        mem1_en         <= 0;
                                        mem1_addr       <= 0;
                                    end
                                    default: begin
                                        mem1_addr           <= mem1_addr + 1;
                                        src_offset          <= 2'b00;
                                        dest_offset_nxtnxt  <= 2'b00;
                                        mem0_we_nxt         <= 4'b1111;
                                    end
                                    endcase

                                2'b01: case (size)
                                    'd1: begin 
                                        mem0_we         <= 4'b0010;
                                        src_read_done   <= 1;
                                        mem1_en         <= 0;
                                        mem1_addr       <= 0;
                                    end
                                    'd2: begin 
                                        mem0_we         <= 4'b0110;
                                        src_read_done   <= 1;
                                        mem1_en         <= 0;
                                        mem1_addr       <= 0;
                                    end
                                    'd3: begin
                                        mem0_we         <= 4'b1110;
                                        src_read_done   <= 1;
                                        mem1_en         <= 0;
                                        mem1_addr       <= 0;
                                    end
                                    default: begin
                                        mem1_addr           <= mem1_addr + 1;
                                        src_offset          <= 2'b00;
                                        dest_offset_nxtnxt  <= 2'b00;
                                        mem0_we_nxt         <= 4'b1110;
                                    end
                                    endcase

                                2'b10: case (size)
                                    'd1: begin 
                                        mem0_we         <= 4'b0100;
                                        src_read_done   <= 1;
                                        mem1_en         <= 0;
                                        mem1_addr       <= 0;
                                    end
                                    'd2: begin 
                                        mem0_we         <= 4'b1100;
                                        src_read_done   <= 1;
                                        mem1_en         <= 0;
                                        mem1_addr       <= 0;
                                    end
                                    default: begin
                                        mem1_addr           <= mem1_addr + 1;
                                        src_offset          <= 2'b00;
                                        dest_offset_nxtnxt  <= 2'b00;
                                        mem0_we_nxt         <= 4'b1100;
                                    end
                                    endcase

                                2'b11: case(size)
                                    'd1: begin 
                                        mem0_we         <= 4'b1000;
                                        src_read_done   <= 1;
                                        mem1_en         <= 0;
                                        mem1_addr       <= 0;
                                    end
                                    default: begin
                                        mem1_addr           <= mem1_addr + 1;
                                        src_offset          <= 2'b00;
                                        dest_offset_nxtnxt  <= 2'b00;
                                        mem0_we_nxt         <= 4'b1000;
                                    end
                                    endcase
                            endcase


                        end else begin //rdata is ready

                            if (dest_write_done) begin
                                READY               <= 0;
                                dest_write_done     <= 0;
                                src_read_start      <= 0;
                                dest_write_start    <= 0;
                                mem0_wdata          <= 0;

                            end else if (src_read_done) begin
                                mem0_en_nxt         <= 0;
                                mem0_we_nxt         <= 0;
                                mem0_addr_nxt       <= 0;
                                dest_write_done     <= 1;
                                src_read_done       <= 0;
                                READY               <= 1;

                            end else if (mem0_addr_nxt + 1 < dest_end[REG_DATA_WIDTH-17:2]) begin
                                src_offset          <= 2'b00;
                                mem0_addr_nxt       <= mem0_addr_nxt + 1;
                                dest_offset_nxtnxt  <= 2'b00;
                                mem0_we_nxt         <= 4'b1111;
                                mem1_addr           <= mem1_addr + 1; 

                            end else begin
                                mem0_addr_nxt       <= mem0_addr_nxt + 1;
                                src_read_done       <= 1;
                                mem1_en             <= 0;
                                mem1_addr           <= 0;
                                //mem0_we_nxt         <= 4'b1111 >> (MEM_STRB_WIDTH-dest_end[1:0]-1);
                                case (dest_end[1:0])
                                2'b00: mem0_we_nxt  <= 4'b0001;
                                2'b01: mem0_we_nxt  <= 4'b0011;
                                2'b10: mem0_we_nxt  <= 4'b0111;
                                2'b11: mem0_we_nxt  <= 4'b1111;
                                endcase
                            end
                        end



                    end else if (src_offset < dest_offset_nxtnxt) begin
                        if(~dest_write_start) begin
                            dest_write_start        <= 1;
                            mem0_en_nxt             <= 1;
                            mem0_addr_nxt           <= dest_addr[REG_DATA_WIDTH-17:2];
                        /*
                            if(size > MEM_STRB_WIDTH - dest_offset_nxtnxt) begin
                                src_offset          <= src_offset + MEM_STRB_WIDTH - dest_offset_nxtnxt;
                                mem0_we_nxt         <= 4'b1111 << dest_offset_nxtnxt;
                                dest_offset_nxtnxt  <= 2'b00;
                            end else begin
                                mem0_we_nxt         <= 4'b1111 >>(MEM_STRB_WIDTH-size) <<dest_offset_nxtnxt;
                                src_read_done       <= 1;
                                mem1_en             <= 0;
                                mem1_addr           <= 0;
                            end
                        */
                            case(dest_offset_nxtnxt)
                                2'b01: case (size)
                                    'd1: begin 
                                        mem0_we         <= 4'b0010;
                                        src_read_done   <= 1;
                                        mem1_en         <= 0;
                                        mem1_addr       <= 0;
                                    end
                                    'd2: begin 
                                        mem0_we         <= 4'b0110;
                                        src_read_done   <= 1;
                                        mem1_en         <= 0;
                                        mem1_addr       <= 0;
                                    end
                                    'd3: begin
                                        mem0_we         <= 4'b1110;
                                        src_read_done   <= 1;
                                        mem1_en         <= 0;
                                        mem1_addr       <= 0;
                                    end
                                    default: begin
                                        src_offset          <= 2'b01;
                                        dest_offset_nxtnxt  <= 2'b00;
                                        mem0_we_nxt         <= 4'b1110;
                                    end
                                    endcase

                                2'b10: case (size)
                                    'd1: begin 
                                        mem0_we         <= 4'b0100;
                                        src_read_done   <= 1;
                                        mem1_en         <= 0;
                                        mem1_addr       <= 0;
                                    end
                                    'd2: begin 
                                        mem0_we         <= 4'b1100;
                                        src_read_done   <= 1;
                                        mem1_en         <= 0;
                                        mem1_addr       <= 0;
                                    end
                                    default: begin
                                        src_offset          <= src_offset + 2;
                                        dest_offset_nxtnxt  <= 2'b00;
                                        mem0_we_nxt         <= 4'b1100;
                                    end
                                    endcase

                                2'b11: case(size)
                                    'd1: begin 
                                        mem0_we         <= 4'b1000;
                                        src_read_done   <= 1;
                                        mem1_en         <= 0;
                                        mem1_addr       <= 0;
                                    end
                                    default: begin
                                        src_offset          <= src_offset + 1;
                                        dest_offset_nxtnxt  <= 2'b00;
                                        mem0_we_nxt         <= 4'b1000;
                                    end
                                    endcase
                            endcase

                        end else begin //rdata is ready
                            if (dest_write_done) begin
                                READY               <= 0;
                                dest_write_done     <= 0;
                                src_read_start      <= 0;
                                dest_write_start    <= 0;
                                mem0_wdata          <= 0;

                            end else if (src_read_done) begin
                                mem0_en_nxt         <= 0;
                                mem0_we_nxt         <= 0;
                                mem0_addr_nxt       <= 0;
                                dest_write_done     <= 1;
                                src_read_done       <= 0;
                                READY               <= 1;

                            end else if ( mem0_addr_nxt < dest_end[REG_DATA_WIDTH-17:2]) begin
                                src_offset          <= src_offset + MEM_STRB_WIDTH - dest_offset_nxtnxt;
                                dest_offset_nxtnxt  <= 2'b00;
                                //mem0_we_nxt         <= 4'b1111 << dest_offset_nxtnxt;
                                case (dest_offset_nxtnxt)
                                2'b01: mem0_we_nxt  <= 4'b1110;
                                2'b10: mem0_we_nxt  <= 4'b1100;
                                2'b11: mem0_we_nxt  <= 4'b1000;
                                endcase

                            end else begin
                                //mem0_we_nxt         <= 4'b1111 >> (MEM_STRB_WIDTH -src_end[1:0] -1) <<dest_offset_nxtnxt;
                                case (src_end[1:0])
                                2'b00: case(dest_offset_nxtnxt)
                                    2'b01: mem0_we_nxt  <= 4'b0010;
                                    2'b10: mem0_we_nxt  <= 4'b0100;
                                    2'b11: mem0_we_nxt  <= 4'b1000;
                                    endcase
                                2'b01: case(dest_offset_nxtnxt)
                                    2'b01: mem0_we_nxt  <= 4'b0110;
                                    2'b10: mem0_we_nxt  <= 4'b1100;
                                    endcase
                                2'b10: mem0_we_nxt      <= 4'b1110;
                                endcase
                                src_read_done       <= 1;
                                mem1_en             <= 0;
                                mem1_addr           <= 0;
                            end
                        end


                    end else if (src_offset > dest_offset_nxtnxt) begin
                        if(~dest_write_start) begin
                            dest_write_start        <= 1;
                            mem0_en_nxt             <= 1;
                            mem0_addr_nxt           <= dest_addr[REG_DATA_WIDTH-17:2];

                        /*    if(size > MEM_STRB_WIDTH - src_offset) begin
                                mem1_addr           <= mem1_addr + 1;
                                src_offset          <= 2'b00;
                                mem0_we_nxt         <= 4'b1111 >> src_offset << dest_offset_nxtnxt;
                                dest_offset_nxtnxt  <= dest_offset_nxtnxt + MEM_STRB_WIDTH - src_offset;
                            end else begin
                                mem0_we_nxt         <= 4'b1111 >>(MEM_STRB_WIDTH-size) <<dest_offset_nxtnxt;
                                src_read_done       <= 1;
                                mem1_en             <= 0;
                                mem1_addr           <= 0;
                            end*/
                            
                            case(dest_offset_nxtnxt)
                                2'b00: case (size)
                                    'd1: begin 
                                        mem0_we         <= 4'b0001;
                                        src_read_done   <= 1;
                                        mem1_en         <= 0;
                                        mem1_addr       <= 0;
                                    end
                                    'd2: begin 
                                        mem0_we         <= 4'b0011;
                                        src_read_done   <= 1;
                                        mem1_en         <= 0;
                                        mem1_addr       <= 0;
                                    end
                                    'd3: begin
                                        mem0_we         <= 4'b0111;
                                        src_read_done   <= 1;
                                        mem1_en         <= 0;
                                        mem1_addr       <= 0;
                                    end
                                    default: begin
                                        mem1_addr           <= mem1_addr + 1;
                                        src_offset          <= 2'b00;
                                        case (src_offset)
                                        2'b01: begin
                                            mem0_we_nxt         <= 4'b0111;
                                            dest_offset_nxtnxt  <= 3;
                                            end
                                        2'b10: begin
                                            mem0_we_nxt         <= 4'b0011;
                                            dest_offset_nxtnxt  <= 2;
                                            end
                                        2'b11: begin
                                            mem0_we_nxt         <= 4'b0001;
                                            dest_offset_nxtnxt  <= 1;
                                            end
                                        endcase
                                    end
                                    endcase

                                2'b01: case (size)
                                    'd1: begin 
                                        mem0_we         <= 4'b0010;
                                        src_read_done   <= 1;
                                        mem1_en         <= 0;
                                        mem1_addr       <= 0;
                                    end
                                    'd2: begin 
                                        mem0_we         <= 4'b0110;
                                        src_read_done   <= 1;
                                        mem1_en         <= 0;
                                        mem1_addr       <= 0;
                                    end
                                    default: begin
                                        mem1_addr           <= mem1_addr + 1;
                                        src_offset          <= 2'b00;
                                        case (src_offset)
                                        2'b10: begin
                                            mem0_we_nxt         <= 4'b0110;
                                            dest_offset_nxtnxt  <= 3;
                                            end
                                        2'b11: begin
                                            mem0_we_nxt         <= 4'b0010;
                                            dest_offset_nxtnxt  <= 2;
                                            end
                                        endcase
                                    end
                                    endcase

                                2'b10: case (size)
                                    'd1: begin 
                                        mem0_we         <= 4'b0100;
                                        src_read_done   <= 1;
                                        mem1_en         <= 0;
                                        mem1_addr       <= 0;
                                    end
                                    default: begin
                                        mem1_addr           <= mem1_addr + 1;
                                        src_offset          <= 2'b00;
                                        mem0_we_nxt         <= 4'b0100;
                                        dest_offset_nxtnxt  <= 3;
                                    end
                                    endcase
                            endcase

                        end else begin //rdata is ready
                            if (dest_write_done) begin
                                READY               <= 0;
                                dest_write_done     <= 0;
                                src_read_start      <= 0;
                                dest_write_start    <= 0;
                                mem0_wdata          <= 0;

                            end else if (src_read_done) begin
                                mem0_en_nxt         <= 0;
                                mem0_we_nxt         <= 0;
                                mem0_addr_nxt       <= 0;
                                dest_write_done     <= 1;
                                src_read_done       <= 0;
                                READY               <= 1;

                            end else if (mem1_addr < src_end[REG_DATA_WIDTH-17:2]) begin
                                mem0_addr_nxt       <= mem0_addr_nxt + 1;
                                mem1_addr           <= mem1_addr + 1;
                                src_offset          <= 2'b00;
                                dest_offset_nxtnxt  <= dest_offset_nxtnxt + MEM_STRB_WIDTH - src_offset;
                                //mem0_we_nxt         <= 4'b1111 >> src_offset;
                                case (src_offset)
                                2'b01: mem0_we_nxt  <= 4'b0111;
                                2'b10: mem0_we_nxt  <= 4'b0011;
                                2'b11: mem0_we_nxt  <= 4'b0001;
                                endcase

                            end else begin
                                mem0_addr_nxt       <= mem0_addr_nxt + 1;
                                //mem0_we_nxt         <= 4'b1111 >> (MEM_STRB_WIDTH- dest_end[1:0]-1);
                                src_read_done       <= 1;
                                mem1_en             <= 0;
                                mem1_addr           <= 0;
                                case (dest_end[1:0])
                                2'b00: mem0_we_nxt  <= 4'b0001;
                                2'b01: mem0_we_nxt  <= 4'b0011;
                                2'b10: mem0_we_nxt  <= 4'b0111;
                                endcase
                            end
                        end
                    end
                end
            end
        



        end else if (MODE == 2'b10) begin
            if (dest_addr[REG_DATA_WIDTH-1: REG_DATA_WIDTH-16] == 16'h0010) begin
                if (~mem0_en & ~|led) begin        //first cycle
                    mem0_en         <= 1;
                    mem0_we         <= 0;
                    mem0_addr       <= dest_addr[REG_DATA_WIDTH-17:2];
                    dest_end        <= dest_addr[REG_DATA_WIDTH-17:0] + size - 1;
                    dest_offset     <= dest_addr[1:0];
                    src_read_start  <= 1;

                end else if (src_read_start) begin  //second cycle
                    src_read_start  <= 0;
                    dest_write_start<= 1;
                    mem0_addr       <= mem0_addr + 1;

                end else if (dest_end[REG_DATA_WIDTH-17:2] >= mem0_addr) begin
                    mem0_addr       <= mem0_addr + 1;
                    dest_offset     <= 2'b00;

                    if (dest_write_start) begin   //first comparison
                        dest_write_start    <= 0;
                        //EXPECTED_DATA       <= EXPECTED_DATA >> ((4-dest_offset)*8);
                        case (dest_offset)
                            2'b00 : begin
                                EXPECTED_DATA   <= EXPECTED_DATA >> 32;
                                if (EXPECTED_DATA[31:0] != mem0_rdata)  begin
                                    led         <= 2'b01;
                                    READY       <= 1;
                                    mem0_en     <= 0;
                                    mem0_addr   <= 0;
                                    dest_end    <= 0;
                                end
                            end                           
                            2'b01 : begin
                                EXPECTED_DATA   <= EXPECTED_DATA >> 24;
                                if (EXPECTED_DATA[23:0] != mem0_rdata[31:8]) begin
                                    led         <= 2'b01;
                                    READY       <= 1;
                                    mem0_en     <= 0;
                                    mem0_addr   <= 0;
                                    dest_end    <= 0;
                                end
                            end
                            2'b10 : begin
                                EXPECTED_DATA   <= EXPECTED_DATA >> 16;
                                if (EXPECTED_DATA[15:0] != mem0_rdata[31:16]) begin
                                    led         <= 2'b01;
                                    READY       <= 1;
                                    mem0_en     <= 0;
                                    mem0_addr   <= 0;
                                    dest_end    <= 0;
                                end
                            end
                            2'b11 : begin
                                EXPECTED_DATA   <= EXPECTED_DATA >> 8;
                                if (EXPECTED_DATA[7:0] != mem0_rdata[31:24]) begin
                                    led         <= 2'b01;
                                    READY       <= 1;
                                    mem0_en     <= 0;
                                    mem0_addr   <= 0;
                                    dest_end    <= 0;
                                end
                            end
                        endcase

                    end else begin      //more comparisons
                        EXPECTED_DATA       <= EXPECTED_DATA >> 32;
                        //$display ("more compare %h # %h", EXPECTED_DATA[31:0], mem0_rdata);
                        if ( EXPECTED_DATA[31:0] != mem0_rdata) begin
                            led             <= 2'b01;
                            READY           <= 1;
                            mem0_en         <= 0;
                            mem0_addr       <= 0;
                            dest_end        <= 0;
                        end
                    end

                end else begin          // final comparison
                    READY                   <= 1;
                    mem0_addr               <= 0;
                    mem0_en                 <= 0;
                    dest_offset             <= 0;
                    dest_end                <= 0;

                    /*if(dest_offset) begin
                        //$display ("first & last, %h -> %h", dest_offset, dest_end[1:0]);
                        if ( EXPECTED_DATA != (mem0_rdata >> dest_offset*8))
                            led             <= 2'b01;
                        else led            <= 2'b10;
                    end */
                    case (dest_offset)
                    2'b01 : begin
                        if ( EXPECTED_DATA != (mem0_rdata >> 8))
                            led             <= 2'b01;
                        else led            <= 2'b10;
                    end
                    2'b10 : begin
                        if ( EXPECTED_DATA != (mem0_rdata >> 16))
                            led             <= 2'b01;
                        else led            <= 2'b10;
                    end
                    2'b11 : begin
                        if ( EXPECTED_DATA != (mem0_rdata >> 24))
                            led             <= 2'b01;
                        else led            <= 2'b10;
                    end
                    2'b00 : begin
                        case (dest_end[1:0])
                        2'b00 : begin
                            if (EXPECTED_DATA[7:0] != mem0_rdata[7:0]) 
                                led         <= 2'b01;
                            else led        <= 2'b10;
                        end
                        2'b01 : begin
                            if (EXPECTED_DATA[15:0] != mem0_rdata[15:0]) 
                                led         <= 2'b01;
                            else led        <= 2'b10;
                        end
                        2'b10 : begin
                            if (EXPECTED_DATA[23:0] != mem0_rdata[23:0]) 
                                led         <= 2'b01;
                            else led        <= 2'b10;
                        end
                        2'b11 : begin
                            //$display ("last, 03");
                            if (EXPECTED_DATA[31:0] != mem0_rdata) 
                                led         <= 2'b01;
                            else led        <= 2'b10;
                        end
                        endcase
                    end
                    endcase
                end 


            end else if (dest_addr[REG_DATA_WIDTH-1: REG_DATA_WIDTH-16] == 16'h0020) begin
                if (~mem1_en & ~|led) begin        //first cycle
                    mem1_en         <= 1;
                    mem1_we         <= 0;
                    mem1_addr       <= dest_addr[REG_DATA_WIDTH-17:2];
                    dest_end        <= dest_addr[REG_DATA_WIDTH-17:0] + size - 1;
                    dest_offset     <= dest_addr[1:0];
                    src_read_start  <= 1;

                end else if (src_read_start) begin  //second cycle
                    src_read_start  <= 0;
                    dest_write_start<= 1;
                    mem1_addr       <= mem1_addr + 1;

                end else if (dest_end[REG_DATA_WIDTH-17:2] >= mem1_addr) begin
                    dest_offset             <= 2'b00;
                    mem1_addr               <= mem1_addr + 1;
                    if (dest_write_start) begin   //first comparison
                        dest_write_start    <= 0;
                        //EXPECTED_DATA       <= EXPECTED_DATA >> ((4-dest_offset)*8);
                        case (dest_offset)
                            2'b00 : begin
                                EXPECTED_DATA   <= EXPECTED_DATA >> 32;
                                if (EXPECTED_DATA[31:0] != mem1_rdata)  begin
                                    led         <= 2'b01;
                                    READY       <= 1;
                                    mem1_en     <= 0;
                                    mem1_addr   <= 0;
                                    dest_end    <= 0;
                                end
                            end                           
                            2'b01 : begin
                                EXPECTED_DATA   <= EXPECTED_DATA >> 24;
                                if (EXPECTED_DATA[23:0] != mem1_rdata[31:8]) begin
                                    led         <= 2'b01;
                                    READY       <= 1;
                                    mem1_en     <= 0;
                                    mem1_addr   <= 0;
                                    dest_end    <= 0;
                                end
                            end
                            2'b10 : begin
                                EXPECTED_DATA   <= EXPECTED_DATA >> 16;
                                if (EXPECTED_DATA[15:0] != mem1_rdata[31:16]) begin
                                    led         <= 2'b01;
                                    READY       <= 1;
                                    mem1_en     <= 0;
                                    mem1_addr   <= 0;
                                    dest_end    <= 0;
                                end
                            end
                            2'b11 : begin
                                EXPECTED_DATA   <= EXPECTED_DATA >> 8;
                                if (EXPECTED_DATA[7:0] != mem1_rdata[31:24]) begin
                                    led         <= 2'b01;
                                    READY       <= 1;
                                    mem1_en     <= 0;
                                    mem1_addr   <= 0;
                                    dest_end    <= 0;
                                end
                            end
                        endcase

                    end else begin      //more comparisons
                        EXPECTED_DATA       <= EXPECTED_DATA >> 32;
                        //$display ("more compare %h # %h", EXPECTED_DATA[31:0], mem1_rdata);
                        if ( EXPECTED_DATA[31:0] != mem1_rdata) begin
                            led             <= 2'b01;
                            READY           <= 1;
                            mem1_en         <= 0;
                            mem1_addr       <= 0;
                            dest_end        <= 0;
                        end
                    end

                end else begin          // final comparison
                    //$display ("final");
                    READY                   <= 1;
                    mem1_addr               <= 0;
                    mem1_en                 <= 0;
                    dest_offset             <= 0;
                    dest_end                <= 0;

                    /*if(dest_offset) begin
                        //$display ("first & last, %h -> %h", dest_offset, dest_end[1:0]);
                        if ( EXPECTED_DATA != (mem1_rdata >> dest_offset*8))
                            led             <= 2'b01;
                        else led            <= 2'b10;
                    end */
                    case (dest_offset)
                    2'b01 : begin
                        if ( EXPECTED_DATA != (mem1_rdata >> 8))
                            led             <= 2'b01;
                        else led            <= 2'b10;
                    end
                    2'b10 : begin
                        if ( EXPECTED_DATA != (mem1_rdata >> 16))
                            led             <= 2'b01;
                        else led            <= 2'b10;
                    end
                    2'b11 : begin
                        if ( EXPECTED_DATA != (mem1_rdata >> 24))
                            led             <= 2'b01;
                        else led            <= 2'b10;
                    end
                    2'b00 : begin
                        case (dest_end[1:0])
                        2'b00 : begin
                            //$display ("last, 00");
                            if (EXPECTED_DATA[7:0] != mem1_rdata[7:0]) 
                                led         <= 2'b01;
                            else led        <= 2'b10;
                        end
                        2'b01 : begin
                            //$display ("last, 01");
                            if (EXPECTED_DATA[15:0] != mem1_rdata[15:0]) 
                                led         <= 2'b01;
                            else led        <= 2'b10;
                        end
                        2'b10 : begin
                            //$display ("last, 02");
                            if (EXPECTED_DATA[23:0] != mem1_rdata[23:0]) 
                                led         <= 2'b01;
                            else led        <= 2'b10;
                        end
                        2'b11 : begin
                            //$display ("last, 03");
                            if (EXPECTED_DATA[31:0] != mem1_rdata) 
                                led         <= 2'b01;
                            else led        <= 2'b10;
                        end
                        endcase
                    end
                    endcase
                end 

            end
        end
    end

endmodule