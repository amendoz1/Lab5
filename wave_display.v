module wave_display (
    input clk,
    input reset,
    input [10:0] x,  // [0..1279]
    input [9:0]  y,  // [0..1023]
    input valid,
    input [7:0] read_value,
    input read_index,
    output wire [8:0] read_address,
    output wire valid_pixel,
    output wire [7:0] r,
    output wire [7:0] g,
    output wire [7:0] b
);




wire compare;
//ram value

//read ddre changes is the enable
wire [7:0] cur_ram;
wire [7:0] prev_ram;
assign cur_ram = read_value;

dffre #(8) ra(.clk(clk),.d(cur_ram),.d(prev_ram),.r(reset),.en(compare));
//need to address gooing down tooo
assign r =(valid_pixel && y> cur_ram  && y < prev_ram)? 8'b11111111: 8'b0;
assign g = 0;
assign b = 0;




////////////////
//Detect change of read_addr
reg read_addr;
wire [7:0] prev_addr;
dffr #(8) tu(.clk(clk),.d(read_addr),.q(prev_addr),.r(reset));


assign compare = (read_addr != prev_addr);

////////////


assign read_address = read_addr;

//read adress

always @(*) begin
    casex(x)
        11'b000xxxxxxxx: read_addr = {read_index, 7'b0};
        11'b001xxxxxxxx: read_addr = {read_index, x[7:1]};
        11'b010xxxxxxxx: read_addr = {read_index, x[7:1]} ;
        11'b011xxxxxxxx: read_addr = {read_index,7'b0} ;
        default: read_addr = 1'b0;
        endcase
    end
        
reg validregx;
reg validregy;
//valid check
always @(*) begin
    casex(x)
        11'b000xxxxxxxx: validregx= 0;
        11'b001xxxxxxxx: validregx = 1;
        11'b010xxxxxxxx: validregx = 1;
        11'b011xxxxxxxx: validregx = 0;
        default: validregx = 0;
        endcase
    casex(y)
        10'b1xxxxxxxxx: validregy= 0;
        10'b0xxxxxxxxx: validregy =1;
        default: validregy = 0;
    endcase
end

assign valid_pixel = (validregx == 1 && validregy == 1);

endmodule
