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
reg [7:0] cur_ram;
wire [7:0] prev_ram;
wire [7:0] temp;

wire [8:0] read_value_adj = (read_value>> 1)+ 6'd32;



dffre #(8) rap(.clk(clk),.d(cur_ram),.q(prev_ram),.r(reset),.en(compare));
always @(*) begin
if(valid_pixel) begin
cur_ram <= read_value_adj;
end

end
//need to address gooing down tooo
wire prevvp;
assign r =( valid&& prevvp && valid_pixel &&( (y[9:1]< cur_ram  && y[9:1] > prev_ram) | (y[9:1]> cur_ram  && y[9:1] < prev_ram)))? 8'b11111111: 8'b0;
assign g =( valid && prevvp && valid_pixel &&( (y[9:1]< cur_ram  && y[9:1] > prev_ram) | (y[9:1]> cur_ram  && y[9:1] < prev_ram)))? 8'b11111111: 8'b0;
assign b =( valid&& prevvp && valid_pixel &&( (y[9:1]< cur_ram  && y[9:1] > prev_ram) | (y[9:1]> cur_ram  && y[9:1] < prev_ram)))? 8'b11111111: 8'b0;




dffr ihateths(.clk(clk),.d(valid_pixel),.q(prevvp),.r(reset));


////////////////
//Detect change of read_addr
reg [7:0] read_addr;
wire [7:0] prev_addr;
dffre #(8) tu(.clk(clk),.d(read_addr),.q(prev_addr),.r(1'b0),.en(valid_pixel));


assign compare = ((read_addr != prev_addr)  );

////////////


assign read_address = read_addr;

//read adress

always @(*) begin
    casex({valid,x})
        12'b0xxxxxxxxxxx: read_addr <= read_addr;
        12'b1000xxxxxxxx: read_addr <= {read_index, 7'bx};
        12'b1001xxxxxxxx: read_addr <= {read_index, x[7:1]};
        12'b1010xxxxxxxx: read_addr <= {read_index, x[7:1]} ;
        12'b1011xxxxxxxx: read_addr <= {read_index,7'bx} ;
        default: read_addr = read_addr;
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
