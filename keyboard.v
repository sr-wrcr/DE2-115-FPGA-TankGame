module keyboard(
    input CLOCK_50,
    input PS2_CLK,
    input PS2_DAT,
    
    output reg p1_up = 0,      // W键
    output reg p1_down = 0,    // S键  
    output reg p1_left = 0,    // A键
    output reg p1_right = 0,   // D键
    output reg p1_action = 0,  // 空格键
    
    output reg p2_up = 0,      // 上箭头
    output reg p2_down = 0,    // 下箭头
    output reg p2_left = 0,    // 左箭头
    output reg p2_right = 0,   // 右箭头
    output reg p2_action = 0,  // 0键
    
    // 没用
    output reg start_pause = 0 
);

reg [7:0] scan_code;
reg [3:0] bit_count = 0;
reg [10:0] shift_reg;
reg data_ready = 0;

reg key_release = 0;

reg ps2_clk_sync = 1, ps2_clk_prev = 1;
reg ps2_dat_sync = 1;

always @(posedge CLOCK_50) begin
    ps2_clk_sync <= PS2_CLK;
    ps2_clk_prev <= ps2_clk_sync;
    ps2_dat_sync <= PS2_DAT;
end 

wire ps2_clk_falling = (ps2_clk_prev && !ps2_clk_sync);
 
always @(posedge CLOCK_50) begin

    if (ps2_clk_falling) begin
        if (bit_count == 0) begin
            if (!ps2_dat_sync) begin  
                bit_count <= 1;
                shift_reg <= 0;
            end
        end else if (bit_count <= 8) begin
            shift_reg[bit_count-1] <= ps2_dat_sync;
            bit_count <= bit_count + 1;
        end else begin
            scan_code <= shift_reg[7:0];
            data_ready <= 1'b1;
            bit_count <= 0;
        end
    end
    
    if (data_ready) begin
        data_ready <= 1'b0;
        
        if (scan_code == 8'hF0) begin
            key_release <= 1'b1;  
        end else begin

            case (scan_code)
                8'h1D: p1_up    <= ~key_release;    // W
                8'h1B: p1_down  <= ~key_release;    // S
                8'h1C: p1_left  <= ~key_release;    // A  
                8'h23: p1_right <= ~key_release;    // D
                8'h29: p1_action<= ~key_release;    // 空格
                
                8'h75: p2_up    <= ~key_release;    // ↑
                8'h72: p2_down  <= ~key_release;    // ↓
                8'h6B: p2_left  <= ~key_release;    // ←
                8'h74: p2_right <= ~key_release;    // →
                8'h70: p2_action<= ~key_release;    // 小键盘0
                
                // 没用
                8'h76: start_pause <= ~key_release; // ESC
                
                default: ;  
            endcase 
            
            key_release <= 1'b0;
        end
    end
end

endmodule