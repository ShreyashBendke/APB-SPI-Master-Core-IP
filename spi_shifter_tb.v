// =========================================================
// APB BASED SPI MASTER CORE
// SPI SHIFTER TESTBENCH
// =========================================================

module spi_shifter_tb();

reg PRESETn;
reg PCLK = 1'b0;
reg ss;
reg lsbfe;
reg cpha;
reg cpol;
reg [7:0] data_mosi;
reg miso;
reg send_data;
reg receive_data;

reg miso_receive_sclk_o,
    miso_receive_sclk0_o,
    mosi_send_sclk0_o,
    mosi_send_sclk_o;

wire [7:0] data_miso;
wire mosi;

///////////////////////////

reg sclk;
reg [11:0] count;
wire pre_sclk;
integer i;

reg [2:0] spi_mode;
reg spiswai;
reg [11:0] BaudRateDivisor;
reg [2:0] sppr = 0; // SPI Baud Rate Preselection Bits
reg [2:0] spr  = 0;

// =========================================================
// DUT INSTANTIATION
// =========================================================

spi_shifter DUT (
    .PRESET_n(PRESETn),
    .PCLK(PCLK),
    .ss_i(ss),
    .lsbfe_i(lsbfe),
    .cpha_i(cpha),
    .cpol_i(cpol),
    .data_mosi_i(data_mosi),
    .miso_i(miso),
    .data_miso_o(data_miso),
    .mosi_o(mosi),
    .send_data_i(send_data),
    .receive_data_i(receive_data),
    .miso_receive_sclk_i(miso_receive_sclk_o),
    .miso_receive_sclk0_i(miso_receive_sclk0_o),
    .mosi_send_sclk0_i(mosi_send_sclk0_o),
    .mosi_send_sclk_i(mosi_send_sclk_o)
);

// =========================================================
// PCLK GENERATION
// =========================================================

always #5 PCLK = ~PCLK;

//always #10 sclk = ~sclk;

// =========================================================
// LOGIC TO GENERATE PRE_SCLK BASED ON CPOL
// =========================================================

assign pre_sclk = cpol ? 1'b1 : 1'b0;

// =========================================================
// BAUD RATE DIVISOR
// =========================================================

always @*
begin
    BaudRateDivisor = ((sppr + 1) * (2**(spr + 1)));
    //BaudRateDivisor = 4;
end

// =========================================================
// LOGIC TO GENERATE THE SCLK
// =========================================================

always @(posedge PCLK or negedge PRESETn)
begin
    if(!PRESETn)
    begin
        count <= 12'b0;
        sclk  <= pre_sclk;
    end

    else if((~ss) &&
            (spi_mode == 2'b00 ||
            (spi_mode == 2'b01 && (~spiswai))))
    begin
        if(count == (BaudRateDivisor/2 - 1'b1))
        begin
            count <= 12'b0;
            sclk  <= ~sclk;
        end

        else
            count <= count + 1'b1;
    end

    else
    begin
        sclk  <= pre_sclk;
        count <= 12'b0;
    end
end

// =========================================================
// LOGIC TO GENERATE THE FLAG TO RECEIVE MISO DATA
// =========================================================

always @(posedge PCLK or negedge PRESETn)
begin
    if(!PRESETn)
    begin
        miso_receive_sclk_o  <= 1'b0;
        miso_receive_sclk0_o <= 1'b0;
    end

    else
    begin

        if((!cpha && cpol) || (cpha && !cpol))
        // falling edge sampling data on MISO
        begin
            if(sclk)
            begin
                if(count == (BaudRateDivisor/2 - 2'b01))
                    miso_receive_sclk0_o <= 1'b1;
                else
                    miso_receive_sclk0_o <= 1'b0;
            end

            else
                miso_receive_sclk0_o <= 1'b0;
        end

        else
        // rising edge sampling data on MISO
        begin
            if(~sclk)
            begin
                if(count == (BaudRateDivisor/2 - 2'b01))
                    miso_receive_sclk_o <= 1'b1;
                else
                    miso_receive_sclk_o <= 1'b0;
            end

            else
                miso_receive_sclk_o <= 1'b0;
        end

    end
end

// =========================================================
// LOGIC TO GENERATE THE FLAG TO SEND MOSI DATA
// =========================================================

always @(posedge PCLK or negedge PRESETn)
begin
    if(!PRESETn)
    begin
        mosi_send_sclk0_o <= 1'b0;
        mosi_send_sclk_o  <= 1'b0;
    end

    else
    begin

        if((!cpha && cpol) || (cpha && !cpol))
        begin
            if(sclk)
            begin
                if(count == (BaudRateDivisor/2 - 2'b10))
                    mosi_send_sclk0_o <= 1'b1;
                else
                    mosi_send_sclk0_o <= 1'b0;
            end

            else
                mosi_send_sclk0_o <= 1'b0;
        end

        else
        begin
            if(~sclk)
            begin
                if(count == (BaudRateDivisor/2 - 2'b10))
                    mosi_send_sclk_o <= 1'b1;
                else
                    mosi_send_sclk_o <= 1'b0;
            end

            else
                mosi_send_sclk_o <= 1'b0;
        end

    end
end

// =========================================================
// RESET TASK
// =========================================================

task reset;
    begin
        #1;
        PRESETn = 1'b0;

        #25;

        PRESETn = 1'b1;
    end
endtask

// =========================================================
// INITIALIZATION TASK
// =========================================================

task initialize;
    begin
        PRESETn = 1'b1;
        ss = 1'b1;
        lsbfe = 1'b1;
        cpha = 1'b0;
        cpol = 1'b1;
        miso = 1'b0;
        send_data = 1'b0;
        receive_data = 1'b0;
		spiswai = 1'b0;
		spi_mode = 3'b1;
		data_mosi = 8'b0;
		
   end
endtask

// =========================================================
// SAMPLE POSEDGE TASK
// =========================================================

task Sample_posedge;
    begin

        PRESETn = 1'b1;

        @(posedge PCLK);

        send_data = 1'b1;
        data_mosi = 8'b1100_0011;

        @(posedge PCLK);
        @(posedge PCLK);

        ss = 1'b0;
        send_data = 1'b0;

        lsbfe = 1'b1;
        cpha = 1'b0;
        cpol = 1'b0;

        repeat(8)
            @(posedge sclk);

        @(posedge PCLK);

        receive_data = 1'b1;
        ss = 1'b1;

        @(posedge PCLK);
        @(posedge PCLK);

        receive_data = 1'b0;

    end
endtask

// =========================================================
// SAMPLE NEGEDGE TASK
// =========================================================

task Sample_negedge;
    begin

        PRESETn = 1'b1;

        @(posedge PCLK);

        send_data = 1'b1;
        data_mosi = 8'b0011_0011;

        @(posedge PCLK);
        @(posedge PCLK);

        ss = 1'b0;
        send_data = 1'b0;

        lsbfe = 1'b0;
        cpha = 1'b0;
        cpol = 1'b1;

        @(posedge PCLK);

        send_data = 1'b0;

        repeat(8)
            @(negedge sclk);

        @(posedge PCLK);

        receive_data = 1'b1;
        ss = 1'b1;

        @(posedge PCLK);
        @(posedge PCLK);

        receive_data = 1'b0;

    end
endtask

// =========================================================
// SEND MISO - NOT CPHA SPECIFIC
// =========================================================

task send_miso_not_cphase;
    begin

        for(i = 0; i <= 7; i = i + 1)
        begin

            @(negedge sclk)
            begin
                miso = 1'b1;
            end

        end

    end
endtask

// =========================================================
// BAUD RATE GENERATION TASK
// =========================================================

task baud_gen(input [2:0] i,
              input [2:0] j,
              input m,
              input n);

    begin

        spi_mode = 2'b00;
        sppr = i;
        spr  = j;
        cpol = m;
        cpha = n;
        ss = 1'b0;
        spiswai = 1'b0;

    end
endtask

// =========================================================
// MAIN TEST
// =========================================================

initial
begin

    initialize;

    #10;

    reset;

    #10;

    fork

        begin

            baud_gen(3'd0, 3'd2, 1'b0, 1'b1);

            Sample_posedge;

        end

        send_miso_not_cphase;

    join

    fork

        begin

            baud_gen(3'd0, 3'd2, 1'b1, 1'b1);

            Sample_negedge;

        end

        send_miso_not_cphase;

    join

    #200 $finish();

end

endmodule
