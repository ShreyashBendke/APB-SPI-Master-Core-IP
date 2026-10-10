`define SPI_APB_DATA_WIDTH 8
`define SPI_REG_WIDTH      8
`define SPI_APB_ADDR_WIDTH 3

module spi_core_tb();

    reg PCLK;
    reg PRESET_n;

    reg [2:0] PADDR_i;
    reg PWRITE_i, PSEL_i, PENABLE_i;

    reg [7:0] PWDATA_i;
    reg miso_i;

    wire ss_o;
    wire sclk_o;
    wire spi_interrupt_request_o;
    wire mosi_o;

    wire [7:0] PRDATA_o;
    wire PREADY_o;
    wire PSLVERR_o;

    integer k;

    spi_core DUT (
        .PCLK(PCLK),
        .PRESET_n(PRESET_n),

        .PADDR_i(PADDR_i),
        .PWRITE_i(PWRITE_i),
        .PSEL_i(PSEL_i),
        .PENABLE_i(PENABLE_i),

        .PWDATA_i(PWDATA_i),

        .PRDATA_o(PRDATA_o),
        .PREADY_o(PREADY_o),
        .PSLVERR_o(PSLVERR_o),

        .miso_i(miso_i),

        .ss_o(ss_o),
        .sclk_o(sclk_o),
        .spi_interrupt_request_o(spi_interrupt_request_o),
        .mosi_o(mosi_o)
    );

    initial
        PCLK = 1'b0;

    always
        #5 PCLK = ~PCLK;


    task reset;
        begin
            PRESET_n = 1'b0;
            #15;
            PRESET_n = 1'b1;
        end
    endtask


    task spi_config_reg(input [7:0] data, input [2:0] addr);
        begin
            @(negedge PCLK);

            PADDR_i  = addr;
            PWDATA_i = data;
            PSEL_i   = 1'b1;
            PENABLE_i = 1'b0;
            PWRITE_i = 1'b1;

            @(negedge PCLK);

            PENABLE_i = 1'b1;

            wait(!PREADY_o);

            @(negedge PCLK);

            PSEL_i    = 1'b0;
            PENABLE_i = 1'b0;

            @(negedge PCLK);
        end
    endtask


    task spi_config_SR(input [2:0] addr);
        begin
            @(negedge PCLK);

            PADDR_i   = addr;
            PSEL_i    = 1'b1;
            PENABLE_i = 1'b0;
            PWRITE_i  = 1'b0;

            @(negedge PCLK);

            PENABLE_i = 1'b1;

            wait(!PREADY_o);

            @(negedge PCLK);

            PSEL_i    = 1'b0;
            PENABLE_i = 1'b0;

            @(negedge PCLK);
        end
    endtask


    task serial_input_miso(input [7:0] in);
        begin

            wait(~ss_o);

            for(k = 0; k < 8; k = k + 1)
                begin
                    @(posedge sclk_o);
                    miso_i = in[k];
                end

            @(negedge PCLK);
            @(negedge PCLK);

            PADDR_i   = 3'd5;
            PSEL_i    = 1'b1;
            PENABLE_i = 1'b0;
            PWRITE_i  = 1'b0;

            @(negedge PCLK);
            @(negedge PCLK);
            @(negedge PCLK);

            PENABLE_i = 1'b1;

            wait(!PREADY_o);

            @(negedge PCLK);

            PSEL_i    = 1'b0;
            PENABLE_i = 1'b0;

            @(negedge PCLK);

        end
    endtask


    initial
        begin

            reset;

            spi_config_reg(8'b1111_0111, 3'd0); // CR1

            spi_config_reg(8'b0001_0010, 3'd1); // CR2

            spi_config_reg(8'b0000_0001, 3'd2); // BR-4

            spi_config_SR(3'd3);                 // SR

            spi_config_reg(8'd68, 3'd5);         // DR

            serial_input_miso(8'b10101010);

            #5;

            #500 $finish;

        end

endmodule
