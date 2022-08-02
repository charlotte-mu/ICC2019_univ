/******************************************************************/
//MODULE:		CONV
//FILE NAME:	CONV.v
//VERSION:		1.0
//DATE:			March,2020
//AUTHOR: 		charlotte-mu
//CODE TYPE:	RTL
//DESCRIPTION:	2019 IC Design Contest Preliminary
//
//MODIFICATION HISTORY:
// VERSION Date Description
// 1.0 03/17/2020 testpattern all pass
// 1.1 08/02/2022 Multiplier update to two-stage pipelined multiplier
/******************************************************************/

module  CONV(
	input						clk,
	input						reset,
	output	reg			busy,	
	input						ready,	
			
	output			[11:0]iaddr,
	input				signed [19:0]idata,	
	
	output	reg			cwr,
	output	reg	[11:0]caddr_wr,
	output	reg	signed [19:0]cdata_wr,
	
	output	reg			crd,
	output			[11:0]caddr_rd,
	input	 			signed [19:0]cdata_rd,
	
	output	reg 	[2:0]csel
	);

//iadd x,y
reg [5:0]iadd_x,iadd_y;
reg [11:0]iadd_reg,iadd_reg_next;
reg [5:0]crd_x,crd_y;

//multiplication
reg signed[39:0]multiplication_reg;
wire signed [39:0]multiplication_out;
reg signed [39:0]add_reg,add_reg_next;
reg signed [19:0]multiplication_inA,multiplication_inB;
reg signed multiplication_reg_w;

DW02_mult_2_stage #(20, 20) U1(
.A(multiplication_inA), 
.B(multiplication_inB), 
.TC(1'b1), 
.CLK(clk),
.PRODUCT(multiplication_out) 
);

//fsm
reg [7:0]fsm,fsm_next;
reg [3:0]conter,conter_next;
reg iadd_read;

//
assign iaddr = (iadd_read)? {iadd_y,iadd_x} : 12'd0;
assign caddr_rd = (crd)? {crd_y,crd_x} : 12'd0;

always@(*)
begin
	case(conter)
		4'd0:
		begin
			iadd_y = iadd_reg[11:6] - 6'd1;
			iadd_x = iadd_reg[5:0] - 6'd1;
		end
		4'd1:
		begin
			iadd_y = iadd_reg[11:6] - 6'd1;
			iadd_x = iadd_reg[5:0];
		end
		4'd2:
		begin
			iadd_y = iadd_reg[11:6] - 6'd1;
			iadd_x = iadd_reg[5:0] + 6'd1;
		end
		4'd3:
		begin
			iadd_y = iadd_reg[11:6];
			iadd_x = iadd_reg[5:0] - 6'd1;
		end
		4'd4:
		begin
			iadd_y = iadd_reg[11:6];
			iadd_x = iadd_reg[5:0];
		end
		4'd5:
		begin
			iadd_y = iadd_reg[11:6];
			iadd_x = iadd_reg[5:0] + 6'd1;
		end
		4'd6:
		begin
			iadd_y = iadd_reg[11:6] + 6'd1;
			iadd_x = iadd_reg[5:0] - 6'd1;
		end
		4'd7:
		begin
			iadd_y = iadd_reg[11:6] + 6'd1;
			iadd_x = iadd_reg[5:0];
		end
		4'd8:
		begin
			iadd_y = iadd_reg[11:6] + 6'd1;
			iadd_x = iadd_reg[5:0] + 6'd1;
		end
		default:
		begin
			iadd_y = 6'd0;
			iadd_x = 6'd0;
		end
	endcase
end

always@(*)
begin
	case(conter)
		4'd0:
		begin
			crd_y = {iadd_reg[11:7],1'b0};
			crd_x = {iadd_reg[5:1],1'b0};
		end
		4'd1:
		begin
			crd_y = {iadd_reg[11:7],1'b0};
			crd_x = {iadd_reg[5:1],1'b1};
		end
		4'd2:
		begin
			crd_y = {iadd_reg[11:7],1'b1};
			crd_x = {iadd_reg[5:1],1'b0};
		end
		4'd3:
		begin
			crd_y = {iadd_reg[11:7],1'b1};
			crd_x = {iadd_reg[5:1],1'b1};
		end
		default:
		begin
			crd_y = 6'd0;
			crd_x = 6'd0;
		end
	endcase
end


always@(posedge clk,posedge reset)
begin
	if(reset)
	begin
		fsm <= 8'd0;
		conter <= 4'd0;
		iadd_reg <= 12'd0;
		add_reg <= 40'd0;
	end
	else
	begin
		fsm <= fsm_next;
		conter <= conter_next;
		iadd_reg <= iadd_reg_next;
		add_reg <= add_reg_next;
		if(multiplication_reg_w == 1'b1)
		begin
			multiplication_reg <= multiplication_out;
		end
		if(fsm != 8'd0)
		begin
			busy = 1'b1;
		end
		else
		begin
			busy = 1'b0;
		end
	end
end

always@(*)
begin
	case(fsm)
		8'd0: //reset
		begin
			fsm_next = fsm;
			iadd_read = 1'b0;
			iadd_reg_next = 12'd0;
			//busy = 1'b0;
			conter_next = 4'd0;
			multiplication_reg_w = 1'b0;
			multiplication_inA = 20'd0;
			multiplication_inB = 20'd0;
			add_reg_next = 40'd0;
			cwr = 1'b0;
			crd = 1'b0;
			caddr_wr = 12'd0;
			cdata_wr = 20'd0;
			csel = 3'b000;
			if(ready == 1'b1)
				fsm_next = 8'b1;
			
		end
		8'd1: //read rom
		begin
			fsm_next = fsm;
			iadd_read = 1'b1;
			iadd_reg_next = iadd_reg;
			//busy = 1'b1;
			conter_next = conter;
			multiplication_reg_w = 1'b0;
			multiplication_inA = 20'd0;
			multiplication_inB = 20'd0;
			add_reg_next = add_reg;
			cwr = 1'b0;
			crd = 1'b0;
			caddr_wr = 12'd0;
			cdata_wr = 20'd0;
			csel = 3'b000;
			fsm_next = 8'd2;
		end
		8'd2: //multiplication 20bit * 20bit
		begin
			fsm_next = fsm;
			iadd_read = 1'b1;
			iadd_reg_next = iadd_reg;
			//busy = 1'b1;
			conter_next = conter;
			multiplication_reg_w = 1'b0;
			multiplication_inA = 20'd0;
			multiplication_inB = 20'd0;
			add_reg_next = add_reg;
			cwr = 1'b0;
			crd = 1'b0;
			caddr_wr = 12'd0;
			cdata_wr = 20'd0;
			csel = 3'b000;
			fsm_next = 8'd20;
			case(conter)
				4'd0:
				begin
					if(iadd_reg[5:0] >= 6'd1 && iadd_reg[11:6] >= 6'd1)
					begin
						multiplication_inA = idata;
						multiplication_inB = 20'h0a89e;
					end
				end
				4'd1:
				begin
					if(iadd_reg[11:6] >= 6'd1)
					begin
						multiplication_inA = idata;
						multiplication_inB = 20'h092d5;
					end
				end
				4'd2:
				begin
					if(iadd_reg[5:0] <= 6'd62 && iadd_reg[11:6] >= 6'd1)
					begin
						multiplication_inA = idata;
						multiplication_inB = 20'h06d43;
					end
				end
				4'd3:
				begin
					if(iadd_reg[5:0] >= 6'd1)
					begin
						multiplication_inA = idata;
						multiplication_inB = 20'h01004;
					end
				end
				4'd4:
				begin
					multiplication_inA = idata;
					multiplication_inB = 20'hf8f71;
				end
				4'd5:
				begin
					if(iadd_reg[5:0] <= 6'd62)
					begin
						multiplication_inA = idata;
						multiplication_inB = 20'hf6e54;
					end
				end
				4'd6:
				begin
					if(iadd_reg[5:0] >= 6'd1 && iadd_reg[11:6] <= 6'd62)
					begin
						multiplication_inA = idata;
						multiplication_inB = 20'hfa6d7;
					end
				end
				4'd7:
				begin
					if(iadd_reg[11:6] <= 6'd62)
					begin
						multiplication_inA = idata;
						multiplication_inB = 20'hfc834;
					end
				end
				4'd8:
				begin
					if(iadd_reg[5:0] <= 6'd62 && iadd_reg[11:6] <= 6'd62)
					begin
						multiplication_inA = idata;
						multiplication_inB = 20'hfac19;
					end
				end
			endcase
		end
                8'd20: //multiplication 20bit * 20bit
		begin
			fsm_next = fsm;
			iadd_read = 1'b0;
			iadd_reg_next = iadd_reg;
			//busy = 1'b1;
			conter_next = conter;
			multiplication_reg_w = 1'b1;
			multiplication_inA = 20'd0;
			multiplication_inB = 20'd0;
			add_reg_next = add_reg;
			cwr = 1'b0;
			crd = 1'b0;
			caddr_wr = 12'd0;
			cdata_wr = 20'd0;
			csel = 3'b000;
			fsm_next = 8'd3;
			case(conter)
				4'd0:
				begin
					if(iadd_reg[5:0] >= 6'd1 && iadd_reg[11:6] >= 6'd1)
					begin
						multiplication_inA = idata;
						multiplication_inB = 20'h0a89e;
					end
				end
				4'd1:
				begin
					if(iadd_reg[11:6] >= 6'd1)
					begin
						multiplication_inA = idata;
						multiplication_inB = 20'h092d5;
					end
				end
				4'd2:
				begin
					if(iadd_reg[5:0] <= 6'd62 && iadd_reg[11:6] >= 6'd1)
					begin
						multiplication_inA = idata;
						multiplication_inB = 20'h06d43;
					end
				end
				4'd3:
				begin
					if(iadd_reg[5:0] >= 6'd1)
					begin
						multiplication_inA = idata;
						multiplication_inB = 20'h01004;
					end
				end
				4'd4:
				begin
					multiplication_inA = idata;
					multiplication_inB = 20'hf8f71;
				end
				4'd5:
				begin
					if(iadd_reg[5:0] <= 6'd62)
					begin
						multiplication_inA = idata;
						multiplication_inB = 20'hf6e54;
					end
				end
				4'd6:
				begin
					if(iadd_reg[5:0] >= 6'd1 && iadd_reg[11:6] <= 6'd62)
					begin
						multiplication_inA = idata;
						multiplication_inB = 20'hfa6d7;
					end
				end
				4'd7:
				begin
					if(iadd_reg[11:6] <= 6'd62)
					begin
						multiplication_inA = idata;
						multiplication_inB = 20'hfc834;
					end
				end
				4'd8:
				begin
					if(iadd_reg[5:0] <= 6'd62 && iadd_reg[11:6] <= 6'd62)
					begin
						multiplication_inA = idata;
						multiplication_inB = 20'hfac19;
					end
				end
			endcase
		end
		8'd3:	//reg add
		begin
			fsm_next = fsm;
			iadd_read = 1'b0;
			iadd_reg_next = iadd_reg;
			//busy = 1'b1;
			conter_next = conter;
			multiplication_reg_w = 1'b0;
			multiplication_inA = 20'd0;
			multiplication_inB = 20'd0;
			add_reg_next = add_reg;
			cwr = 1'b0;
			crd = 1'b0;
			caddr_wr = 12'd0;
			cdata_wr = 20'd0;
			csel = 3'b000;
			add_reg_next = add_reg + multiplication_reg;
			if(conter == 4'd9)
			begin
				conter_next = 4'd0;
				fsm_next = 8'd4;
			end
			else
			begin
				fsm_next = 8'd1;
				conter_next = conter + 4'd1;
			end
		end
		8'd4: //add bias
		begin
			fsm_next = fsm;
			iadd_read = 1'b0;
			iadd_reg_next = iadd_reg;
			//busy = 1'b1;
			conter_next = conter;
			multiplication_reg_w = 1'b0;
			multiplication_inA = 20'd0;
			multiplication_inB = 20'd0;
			add_reg_next = add_reg + 40'h00_1310_8000;
			cwr = 1'b0;
			crd = 1'b0;
			caddr_wr = 12'd0;
			cdata_wr = 20'd0;
			csel = 3'b000;
			fsm_next = 8'd5;
		end
		8'd5: // write L0
		begin
			fsm_next = fsm;
			iadd_read = 1'b0;
			iadd_reg_next = iadd_reg;
			//busy = 1'b1;
			conter_next = conter;
			multiplication_reg_w = 1'b0;
			multiplication_inA = 20'd0;
			multiplication_inB = 20'd0;
			add_reg_next = 40'd0;
			cwr = 1'b1;
			crd = 1'b0;
			caddr_wr = 12'd0;
			cdata_wr = 20'd0;
			csel = 3'b001;
			
			caddr_wr = iadd_reg;
			if(add_reg[39] == 1'b1)
			begin
				cdata_wr = 20'd0;
			end
			else
			begin
				cdata_wr = add_reg[35:16];
			end
			
			if(iadd_reg == 12'hfff)
			begin
				fsm_next = 8'd6;
				iadd_reg_next = 12'd0;
			end
			else
			begin
				iadd_reg_next = iadd_reg + 12'd1;
				fsm_next = 8'd1;
			end
		end
		8'd6: // read L0
		begin
			fsm_next = fsm;
			iadd_read = 1'b0;
			iadd_reg_next = iadd_reg;
			//busy = 1'b1;
			conter_next = conter;
			multiplication_reg_w = 1'b0;
			multiplication_inA = 20'd0;
			multiplication_inB = 20'd0;
			add_reg_next = add_reg;
			cwr = 1'b0;
			crd = 1'b1;
			caddr_wr = 12'd0;
			cdata_wr = 20'd0;
			csel = 3'b001;
			if(conter == 4'd0)
			begin
				fsm_next = 8'd7;
			end
			else
			begin
				fsm_next = 8'd8;
			end
		end
		8'd7: // L0 => add_reg
		begin
			fsm_next = fsm;
			iadd_read = 1'b0;
			iadd_reg_next = iadd_reg;
			//busy = 1'b1;
			conter_next = conter + 4'd1;
			multiplication_reg_w = 1'b0;
			multiplication_inA = 20'd0;
			multiplication_inB = 20'd0;
			add_reg_next = {20'd0,cdata_rd};
			cwr = 1'b0;
			crd = 1'b1;
			caddr_wr = 12'd0;
			cdata_wr = 20'd0;
			csel = 3'b000;
			fsm_next = 8'd6;
		end
		8'd8: //	L0 compare add_reg & write add_reg
		begin
			fsm_next = fsm;
			iadd_read = 1'b0;
			iadd_reg_next = iadd_reg;
			//busy = 1'b1;
			conter_next = conter;
			multiplication_reg_w = 1'b0;
			multiplication_inA = 20'd0;
			multiplication_inB = 20'd0;
			add_reg_next = add_reg;
			cwr = 1'b0;
			crd = 1'b1;
			caddr_wr = 12'd0;
			cdata_wr = 20'd0;
			csel = 3'b000;
			if(cdata_rd > add_reg[19:0])
			begin
				add_reg_next = {20'd0,cdata_rd};
			end
			if(conter == 4'd3)
			begin
				fsm_next = 8'd9;
				conter_next = 4'd0;
			end
			else
			begin
				fsm_next = 8'd6;
				conter_next = conter + 4'd1;
			end
		end
		8'd9: // write L1
		begin
			fsm_next = fsm;
			iadd_read = 1'b0;
			iadd_reg_next = iadd_reg;
			//busy = 1'b1;
			conter_next = conter;
			multiplication_reg_w = 1'b0;
			multiplication_inA = 20'd0;
			multiplication_inB = 20'd0;
			add_reg_next = 40'd0;
			cwr = 1'b1;
			crd = 1'b0;
			caddr_wr = 12'd0;
			cdata_wr = add_reg[19:0];
			csel = 3'b011;
			
			caddr_wr = {iadd_reg[11:7],iadd_reg[5:1]};
			if(iadd_reg == 12'hfbe)
			begin
				fsm_next = 8'd10;
				iadd_reg_next = 12'd0;
			end
			else
			begin
				fsm_next = 8'd6;
				if(iadd_reg[5:0] == 6'd62)
				begin
					iadd_reg_next = {iadd_reg[11:7] + 5'd1,7'd0};
				end
				else
				begin
					iadd_reg_next = {iadd_reg[11:6],iadd_reg[5:1] + 5'd1,iadd_reg[0]};
				end
			end
		end
		default:
		begin
			fsm_next = 8'd0;
			iadd_read = 1'b0;
			iadd_reg_next = 12'd0;
			//busy = 1'b0;
			conter_next = 4'd0;
			multiplication_reg_w = 1'b0;
			multiplication_inA = 20'd0;
			multiplication_inB = 20'd0;
			add_reg_next = 40'd0;
			cwr = 1'b0;
			crd = 1'b0;
			caddr_wr = 12'd0;
			cdata_wr = 20'd0;
			csel = 3'b000;
		end
	endcase
end


endmodule
