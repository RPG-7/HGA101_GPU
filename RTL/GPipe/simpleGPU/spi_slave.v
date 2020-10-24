`timescale 1ns / 1ps

//inspired by https://www.fpga4fun.com/SPI2.html

module SPI_slave(i_base_clock, i_SCK, i_MOSI, i_EN, o_WORDVALID,o_DATA,o_COUNTER);


input i_base_clock;
input i_SCK, i_EN,i_MOSI;
parameter n = 32;

output reg o_WORDVALID;
output wire [n-1:0] o_DATA;
output [7:0] o_COUNTER;

assign o_COUNTER = counter;

reg[2:0] sck_samples = 0;
reg[2:0] en_samples = 0;
reg[1:0] mosi_samples = 0;

wire validInputData = mosi_samples[1];
wire enableActive = ~en_samples[1]; //active low

always @(posedge i_base_clock) begin
    
    sck_samples <= {sck_samples[1:0],i_SCK};
    en_samples <= {en_samples[1:0],i_EN};
    mosi_samples <= {mosi_samples[0],i_MOSI};
    
    end

//recieve data from avr
//parameterize this better...
reg [7:0] counter = 0;
reg [n-1:0] dataInputRegister = 0;
assign o_DATA = dataInputRegister;


always@(posedge i_base_clock) begin
    //if enable is true, and serial clock is rising
    //read data
    if(enableActive && sck_samples[2:1] == 2'b01) begin
        counter <= counter +1;
        //read a bit of the data into the register
        dataInputRegister <= {dataInputRegister[n-2:0],validInputData};
    end //if
    else
        if (enableActive == 0) begin
            counter <= 0;
        end
        
    end
    
//TODO does this need more constraints?
always@(posedge i_base_clock) begin
    if( (counter == n-1) && enableActive && (sck_samples[2:1] == 2'b01) ) begin
        o_WORDVALID <= 1;
    end
    else begin
        o_WORDVALID <= 0;
    end
end

endmodule