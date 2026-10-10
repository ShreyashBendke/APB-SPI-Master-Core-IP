module spi_slave_select_tb();

reg PRESETn;
reg [1:0] spi_mode;
reg mstr;
reg spiswai;
reg PCLK = 1'b0;
reg send_data;
reg [11:0] BaudRateDivisor;

wire ss;
wire receive_data;
wire tip;


spi_slave_select DUT (
    .PRESET_n          (PRESETn),
    .PCLK              (PCLK),
    .spi_mode_i        (spi_mode),
    .mstr_i            (mstr),
    .spiswai_i         (spiswai),
    .BaudRateDivisor_i (BaudRateDivisor),
    .ss_o              (ss),
    .send_data_i       (send_data),
    .receive_data_o    (receive_data),
    .tip_o             (tip)
);


always #5 PCLK = ~PCLK;


task reset;
    begin
        #10;
        PRESETn = 1'b0;
        #10;
        PRESETn = 1'b1;
    end
endtask


// SS selects slave in master mode and when send_data is asserted,
// slave should be selected for a duration BR*16.
// After that slave is deselected, if stop mode is activated
// then slave is deselected.

task ss_generation;
    begin
        spi_mode = 2'b00;
        send_data = 1'b1;
        mstr = 1'b1;
        spiswai = 1'b0;
        BaudRateDivisor = 12'h4;

        #10;

        @(posedge PCLK)
        send_data = 1'b0;
    end
endtask


// Slave is deselected in stopmode

task ss_generation_stop;
    begin
        spi_mode = 2'b10;
        send_data = 1'b0;
    end
endtask


initial
begin
    reset;

    #10;
    ss_generation;

    #500;

    // ss_generation_stop;

    #200 $finish();
end

endmodule
