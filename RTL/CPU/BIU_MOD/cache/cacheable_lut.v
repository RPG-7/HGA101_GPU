module cacheable_lut
(
    input [31:0]addr,
    output cacheable
);

assign cacheable=addr[31]==1;
endmodule