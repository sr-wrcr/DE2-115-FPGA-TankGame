module tone_generator(
    input clk, rst_n, sw_control,

    input p1_bullet_hit, p1_tank_move, p1_shoot_sound,
    input p2_bullet_hit, p2_tank_move, p2_shoot_sound,

    output reg [15:0] left_channel,   
    output reg [15:0] right_channel   
);

parameter SHOOT_VOLUME = 12;  
parameter HIT_VOLUME = 10;    
parameter MOVE_VOLUME = 4;    

reg [23:0] p1_shoot_duration, p1_hit_duration, p1_move_duration;
reg p1_shoot_active, p1_hit_active, p1_move_active;

reg [23:0] p2_shoot_duration, p2_hit_duration, p2_move_duration;
reg p2_shoot_active, p2_hit_active, p2_move_active;

reg [15:0] p1_shoot_freq, p1_hit_freq, p1_move_freq;
reg [15:0] p2_shoot_freq, p2_hit_freq, p2_move_freq;

reg [15:0] p1_move_counter = 0;
reg [15:0] p2_move_counter = 0;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        p1_shoot_active <= 0; p1_hit_active <= 0; p1_move_active <= 0;
        p2_shoot_active <= 0; p2_hit_active <= 0; p2_move_active <= 0;
        p1_shoot_duration <= 0; p1_hit_duration <= 0; p1_move_duration <= 0;
        p2_shoot_duration <= 0; p2_hit_duration <= 0; p2_move_duration <= 0;
        left_channel <= 0; right_channel <= 0;
        p1_shoot_freq <= 0; p1_hit_freq <= 0; p1_move_freq <= 0;
        p2_shoot_freq <= 0; p2_hit_freq <= 0; p2_move_freq <= 0;
        p1_move_counter <= 0;
        p2_move_counter <= 0;
    end else begin
        if (p1_shoot_sound && !p1_shoot_active) begin
            p1_shoot_active <= 1;
            p1_shoot_duration <= 24'd500_000;  // 10ms
        end
        if (p1_bullet_hit && !p1_hit_active) begin
            p1_hit_active <= 1;
            p1_hit_duration <= 24'd1_000_000;  // 20ms
        end
        if (p1_tank_move && !p1_move_active) begin
            p1_move_active <= 1;
            p1_move_duration <= 24'd500_000; 
            p1_move_counter <= 0; 
        end
        
        if (p2_shoot_sound && !p2_shoot_active) begin
            p2_shoot_active <= 1;
            p2_shoot_duration <= 24'd500_000;  // 10ms
        end
        if (p2_bullet_hit && !p2_hit_active) begin
            p2_hit_active <= 1;
            p2_hit_duration <= 24'd1_000_000;  // 20ms
        end
        if (p2_tank_move && !p2_move_active) begin
            p2_move_active <= 1;
            p2_move_duration <= 24'd500_000; 
            p2_move_counter <= 0; 
        end
        
        p1_shoot_freq <= 0; p1_hit_freq <= 0; p1_move_freq <= 0;
        p2_shoot_freq <= 0; p2_hit_freq <= 0; p2_move_freq <= 0;
        
        if (p1_shoot_active) begin
            if (p1_shoot_duration > 0) begin
                p1_shoot_duration <= p1_shoot_duration - 1;
                p1_shoot_freq <= (1500 - (p1_shoot_duration[15:8] * 5)) * SHOOT_VOLUME;
            end else begin
                p1_shoot_active <= 0;
            end
        end
        
        if (p1_hit_active) begin
            if (p1_hit_duration > 0) begin
                p1_hit_duration <= p1_hit_duration - 1;
                p1_hit_freq <= (400 - (p1_hit_duration[17:10] * 2)) * HIT_VOLUME;
            end else begin
                p1_hit_active <= 0;
            end
        end
        
        if (p1_move_active) begin
            if (p1_move_duration > 0) begin
                p1_move_duration <= p1_move_duration - 1;
                p1_move_counter <= p1_move_counter + 50; 
                p1_move_freq <= (80 + (p1_move_counter[7:0] & 8'h0F)) * MOVE_VOLUME;
            end else begin
                p1_move_active <= 0;
                p1_move_counter <= 0;
            end
        end
        
        if (p2_shoot_active) begin
            if (p2_shoot_duration > 0) begin
                p2_shoot_duration <= p2_shoot_duration - 1;
                p2_shoot_freq <= (1000 - (p2_shoot_duration[15:8] * 3)) * SHOOT_VOLUME;
            end else begin
                p2_shoot_active <= 0;
            end
        end
        
        if (p2_hit_active) begin
            if (p2_hit_duration > 0) begin
                p2_hit_duration <= p2_hit_duration - 1;
                p2_hit_freq <= (250 - (p2_hit_duration[17:10] * 1)) * HIT_VOLUME;
            end else begin
                p2_hit_active <= 0;
            end
        end
        
        if (p2_move_active) begin
            if (p2_move_duration > 0) begin
                p2_move_duration <= p2_move_duration - 1;
                p2_move_counter <= p2_move_counter + 50; 
                p2_move_freq <= (80 + (p2_move_counter[7:0] & 8'h0F)) * MOVE_VOLUME;
            end else begin
                p2_move_active <= 0;
                p2_move_counter <= 0;
            end
        end
        
        left_channel <= (p1_shoot_freq + p1_hit_freq + p1_move_freq) > 32767 ? 
                       32767 : (p1_shoot_freq + p1_hit_freq + p1_move_freq);
        
        right_channel <= (p2_shoot_freq + p2_hit_freq + p2_move_freq) > 32767 ? 
                        32767 : (p2_shoot_freq + p2_hit_freq + p2_move_freq);
    end
end

endmodule