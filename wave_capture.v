`define ARMED 3'b001
`define ACTIVE 3'b010
`define WAIT 3'b100

module wave_capture (
    input clk,
    input reset,
    input new_sample_ready,
    input [15:0] new_sample_in,
    input wave_display_idle,
    output wire [8:0] write_address,
    output wire write_enable,
    output wire [7:0] write_sample,
    output wire read_index 
);
// Implement me!

// internal signals
wire [2:0] state;
reg [2:0] next_state;
wire [7:0] count;
reg[7:0] next_count;
reg final_sample_written;
wire pos_zero_cross;
reg tempIndex;
reg temp_address;
reg [15:0] next_sample;
reg [15:0] current_sample;
reg [7:0] temp_written;
reg temp_enable_in;
wire temp_enable_out;

dff  #(3) ffState(.clk(clk), .d(next_state), .q(state)); //change enable (might not need one)
dff ffIndex (.clk(clk), .d(tempIndex), .q(read_index));

// state logic, index, and address logic
always @(*) begin
    casex({reset, state})
    4'b1xxx : {next_state, tempIndex} = {`ARMED, 1'b0}; 
    4'b0001: next_state = pos_zero_cross ? `ACTIVE : `ARMED; //armed
    4'b0010: {next_state, temp_address} = {{final_sample_written ? `WAIT : `ACTIVE}, {~read_index, count} };     //active
    4'b0100: {next_state, tempIndex} = { {wave_display_idle ? `ARMED : `WAIT}, {wave_display_idle ? ~read_index : read_index} };    //wait
    default: {next_state, temp_address, tempIndex} = {`ARMED, 8'd0, 1'b0};    //ARMED
    endcase
end

dffre #(8) ffCount(.clk(clk), .d(next_count), .q(count), .r(1'b0), .en(new_sample_ready)); // change enable (definitley need one here)
// counter logic
always @(*) begin
    casex({reset, state})
    4'b1xxx : {next_count, final_sample_written} = {8'd0, 1'b0};
    4'b0001 : {next_count, final_sample_written} = {8'd0, 1'b0};
    4'b0010 : 
    if (count == 8'd255)
        begin
            next_count = 8'd0;
            final_sample_written = 1'b1;
        end
        else begin
            next_count = count + 1;
            final_sample_written = 1'b0;
        end 
    4'b0100: {next_count, final_sample_written} = {8'd0, 1'b0};
    endcase
    end

assign write_address = temp_address;

// pos zero cross logic
dffr #(16) sampleFF(.clk(clk), .d(new_sample_in), .q(current_sample), .r(rst)); // need enable?

assign pos_zero_cross = (next_sample > 0 && current_sample < 0) ? 1'b1 : 1'b0; // this might be garbage at first because current_sample is also prolly gonna be garb
// writing address logic

dff #(8) writtenSampleFF(.clk(clk), .d(temp_written), .q(write_sample)); // delete, will be writing the 8MSB of actual sample to write_sample, use assign 
always @(*) begin
    casex({reset, state})
    4'b1xxx :   {temp_written, temp_enable_in} = {8'd0, 1'b0};
    4'b0010:   {temp_written, temp_enable_in} = {current_sample[7:0], 1'b1}; // (which sample should i grab the 8 bits from?), u
    default:   {temp_written, temp_enable_in} = {8'd0, 1'b0};
    endcase
end

// want write_enable = 1 when we have a new write_sample
dffre write_enableFF(.clk(clk), .d(temp_enable_in), .q(temp_enable_out), .r(rst), .en(new_sample_ready));

assign write_enable = one_pulse oneEnable(temp_enable_out);
endmodule

// Latest Version
`define ARMED 3'b001
`define ACTIVE 3'b010
`define WAIT 3'b100

module wave_capture (
    input clk,
    input reset,
    input new_sample_ready,
    input [15:0] new_sample_in,
    input wave_display_idle, //when high, flip RAM writing section and move from wait to armed
    output wire [8:0] write_address,
    output wire write_enable,
    output wire [7:0] write_sample,
    output wire read_index 
);
// internal signals
wire [2:0] state;
reg [2:0] next_state;
wire [7:0] count;
reg[7:0] next_count;
reg final_sample_written;
wire pos_zero_cross;
reg tempIndex;
reg [8:0] temp_address;
wire [15:0] intermediate_sample;
wire [15:0] previous_sample;
reg [7:0] temp_written;
reg temp_enable_in;

dff  #(3) ffState(.clk(clk), .d(next_state), .q(state)); //change enable (might not need one)
dffre ffIndex (.clk(clk), .d(~read_index), .q(read_index), .r(rst), .en(wave_display_idle && state == `WAIT)); // revisit

// state logic, index, and address logic
always @(*) begin
    casex({reset, state})
    4'b1xxx : {next_state} = {`ARMED}; 
    4'b0001: next_state = pos_zero_cross ? `ACTIVE : `ARMED; //armed
    4'b0010: {next_state, temp_address} = {{final_sample_written ? `WAIT : `ACTIVE}, {~read_index, count} };     //active
    4'b0100: {next_state} = { {wave_display_idle ? `ARMED : `WAIT} };    //wait
    default: {next_state, temp_address} = {`ARMED, 8'd0};    //ARMED
    endcase
end
dffre #(8) ffCount(.clk(clk), .d(next_count), .q(count), .r(1'b0), .en(new_sample_ready)); // change enable (definitley need one here)
// counter logic
always @(*) begin
    casex({reset, state})
    4'b1xxx : {next_count, final_sample_written} = {8'd0, 1'b0};
    4'b0001 : {next_count, final_sample_written} = {8'd0, 1'b0};
    4'b0010 : 
    if (count == 8'd255)
        begin
            next_count = 8'd0;
            final_sample_written = 1'b1;
        end
        else begin
            next_count = count + 1;
            final_sample_written = 1'b0;
        end 
    4'b0100: {next_count, final_sample_written} = {8'd0, 1'b0};
    endcase
    end
 
 //final_sample_written should be in a flip flop

assign write_address = temp_address;

// pos zero cross logic
dffre #(16) sampleFF1(.clk(clk), .d(new_sample_in), .q(intermediate_sample), .r(reset), .en(new_sample_ready)); // need enable? &&(state == `ACTIVE) under the assumption that we are only comparing the current sample to the previous sample, and we do not need to hold any of the samples (skipping samples is okay)
dffre #(16) sampleFF2(.clk(clk), .d(intermediate_sample), .q(previous_sample), .r(reset), .en(new_sample_ready));
assign pos_zero_cross =  (new_sample_in[15] != 1'b1 && previous_sample[15] == 1'b1);

//wondering if this is an issue because current sample is determined

// writing address logic
//dff #(8) writtenSampleFF(.clk(clk), .d(temp_written), .q(write_sample)); // delete, will be writing the 8MSB of actual sample to write_sample, use assign (DONT NEED FF?)
always @(*) begin
    casex({reset, state})
    4'b1xxx :   {temp_written, temp_enable_in} = {8'd0, 1'b0};
    4'b0010:   {temp_written, temp_enable_in} = {new_sample_in[15:8] + 8'd128, 1'b1}; // (which sample should i grab the 8 bits from?), u
    default:   {temp_written, temp_enable_in} = {8'd0, 1'b0};
    endcase
end
assign write_sample = temp_written;
// want write_enable = 1 when we have a new write_sample
//dffre write_enableFF(.clk(clk), .d(temp_enable_in), .q(write_enable), .r(reset), .en(new_sample_ready )); // enable because if a sample takes long to be sent, we should not enable writing of the same sample

assign write_enable = temp_enable_in && new_sample_ready;
endmodule
// End of Latest Version
