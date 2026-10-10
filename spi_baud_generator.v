module spi_baud_generator(
    input                       PCLK,
    input                       PRESET_n,
    input [1:0]                 spi_mode_i,    // indicates run_mode, wait_mode and stop_mode
    input                       spiswai_i,
    input [2:0]                 sppr_i,        // SPI Baud Rate Preselection Bits
    input [2:0]                 spr_i,         // SPI Baud Rate Selection Bits
    input                       cpol_i,        // 0 - Idle Low, 1- Idle High
    input                       cpha_i,
    input                       ss_i,          // Slave Selection
    output reg                  sclk_o,
    output reg                  miso_receive_sclk_o,
    output reg                  miso_receive_sclk0_o,
    output reg                  mosi_send_sclk0_o,
    output reg                  mosi_send_sclk_o,
	output wire [11:0]          BaudRateDivisor
  
);

wire                           pre_sclk_s;
reg  [11:0]                    count_s;
reg  [11:0]                    count1_s;


// Baud Rate Divisor
assign BaudRateDivisor = ((sppr_i+1)*(2**(spr_i+1)));


// Logic to generate pre_sclk based on the cpol
assign pre_sclk_s = cpol_i ? 1'b1 : 1'b0;

// Logic to generate the Sclk
always @(posedge PCLK or negedge PRESET_n)
begin
    if(!PRESET_n)
    begin
        count_s <= 12'b0;
        sclk_o  <= pre_sclk_s;
    end
    else if((~ss_i) && (spi_mode_i == 2'b00 || (spi_mode_i == 2'b01 && (~spiswai_i))))
    begin
        if(count_s == (BaudRateDivisor/2 - 1'b1))
        begin
            count_s <= 12'b0;
            sclk_o  <= ~sclk_o;
        end
        else
            count_s <= count_s + 1'b1;
    end
    else
    begin
        sclk_o  <= pre_sclk_s;
        count_s <= 12'b0;
    end
end

// Logic to generate the flag to receive miso data
always @(posedge PCLK or negedge PRESET_n)
begin
    if(!PRESET_n)
    begin
        miso_receive_sclk_o  <= 1'b0;
        miso_receive_sclk0_o <= 1'b0;
    end
    else
    begin
        if((!cpha_i && cpol_i) || (cpha_i && !cpol_i)) // falling edge sampling data on miso
        begin
            if(sclk_o)
                if(count_s == (BaudRateDivisor/2 - 2'b01))
                    miso_receive_sclk0_o <= 1'b1;
                else
                    miso_receive_sclk0_o <= 1'b0;
            else
                miso_receive_sclk0_o <= 1'b0;
        end
        else // rising edge sampling data on miso
        begin
            if(~sclk_o)
                if(count_s == (BaudRateDivisor/2 - 2'b01))
                    miso_receive_sclk_o <= 1'b1;
                else
                    miso_receive_sclk_o <= 1'b0;
            else
                miso_receive_sclk_o <= 1'b0;
        end
    end
end

// Logic to generate the flag to send mosi data
always @(posedge PCLK or negedge PRESET_n)
begin
    if(!PRESET_n)
    begin
        mosi_send_sclk0_o <= 1'b0;
        mosi_send_sclk_o  <= 1'b0;
    end
    else
    begin
        if((!cpha_i && cpol_i)|| (cpha_i && !cpol_i))
        begin
            if(sclk_o)
                if(count_s == (BaudRateDivisor/2 - 2'b10))
                    mosi_send_sclk0_o <= 1'b1;
                else
                    mosi_send_sclk0_o <= 1'b0;
            else
                mosi_send_sclk0_o <= 1'b0;
        end
        else
        begin
            if(~sclk_o)
                if(count_s == (BaudRateDivisor/2 - 2'b10))
                    mosi_send_sclk_o <= 1'b1;
                else
                    mosi_send_sclk_o <= 1'b0;
            else
                mosi_send_sclk_o <= 1'b0;
        end
    end
end

endmodule
