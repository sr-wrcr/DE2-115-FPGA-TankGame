module divi_1hz(clk, divi_1hz);
input clk;
output reg divi_1hz;
reg[24:0]count_reg;
always @(posedge clk)
	begin
	if(count_reg==25'd24_999_999)
	begin
	count_reg <= 25'd0;
	divi_1hz <= ~divi_1hz;
	end
	else 
	begin
	count_reg <= count_reg + 1'b1;
	end
	end
endmodule
