module spi_slave_select(
    input               PRESET_n,
    input       [1:0]   spi_mode_i,
    input               mstr_i,
    input               spiswai_i,
    input               PCLK,
    input               send_data_i,
    input       [11:0]  BaudRateDivisor_i,
    output reg          ss_o,
    output reg          receive_data_o,
    output              tip_o
);

reg     [15:0]  count_s;
wire    [15:0]  target_s;
reg             rcv_s;

assign target_s = BaudRateDivisor_i * 5'd16;
assign tip_o = (~ss_o);

// Logic to generate the ss as low when new data is received to Data
// Register through PWDATA Bus(send_data signal will become high)
always@(negedge PRESET_n or posedge PCLK)
begin
    if(!PRESET_n)
    begin
        count_s <= 16'hffff;
        ss_o    <= 1'b1;
        rcv_s   <= 1'b0;
    end
    else
    begin
        if(mstr_i && (spi_mode_i == 2'b00 || (spi_mode_i == 2'b01 && (~spiswai_i)))) //Checking if spi in run or wait mode
        begin
            if(send_data_i)
            begin
                ss_o    <= 1'b0;
                count_s <= 16'h0;
            end
            else if(count_s <= (target_s))
            begin
                ss_o    <= 1'b0;
                count_s <= count_s + 1'b1;
                if(count_s == (target_s - 1'b1))
                    rcv_s <= 1'b1;
            end
            else
            begin
                ss_o    <= 1'b1;
                rcv_s   <= 1'b0;
                count_s <= 16'hffff;
            end
        end
        else
        begin
            ss_o    <= 1'b1;
            rcv_s   <= 1'b0;
            count_s <= 16'hffff;
        end
    end
end

// generate receive_data after one clock cycle so all it will to make sure
// MISO is collected properly.
always@(posedge PCLK or negedge PRESET_n)
begin
    if(!PRESET_n)
        receive_data_o <= 1'b0;
    else
        receive_data_o <= rcv_s;
end

endmodule
