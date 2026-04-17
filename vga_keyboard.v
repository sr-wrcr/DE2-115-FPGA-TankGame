module vga_keyboard(
    input CLOCK_50,

    input p1_up, p1_down, p1_left, p1_right,
    input p1_action,
    input p2_up, p2_down, p2_left, p2_right, 
    input p2_action,
    input start_pause,

    input reset_game,

    output reg [7:0] VGA_R,
    output reg [7:0] VGA_G,
    output reg [7:0] VGA_B,
    output VGA_HS,
    output VGA_VS,
    output VGA_CLK,
    output VGA_BLANK_N,
    output VGA_SYNC_N,
    
    output reg p1_bullet_hit,     
    output reg p1_tank_move,        
    output reg p1_shoot_sound,    
    output reg p2_bullet_hit,     
    output reg p2_tank_move,        
    output reg p2_shoot_sound,     
    
    output reg [3:0] p1_health,    
    output reg [3:0] p2_health,    
    
    input [3:0] game_speed_level,     
    input [2:0] bullet_speed_level,   
    input [2:0] shoot_cooldown_level, 
    input map_type,                   
    input enable_obstacles,           
	 
	 input health_mode_switch          

);

parameter H_SYNC = 96;
parameter H_BACK = 48;
parameter H_ACTIVE = 640;
parameter H_FRONT = 16;
parameter H_TOTAL = 800;

parameter V_SYNC = 2;
parameter V_BACK = 33;
parameter V_ACTIVE = 480;
parameter V_FRONT = 10;
parameter V_TOTAL = 525;

reg [23:0] p1_sound_duration, p2_sound_duration;

reg p1_bullet_hit_trigger, p1_tank_move_trigger, p1_shoot_trigger;
reg p2_bullet_hit_trigger, p2_tank_move_trigger, p2_shoot_trigger;

reg [9:0] h_count = 0;
reg [9:0] v_count = 0;

reg clk_25 = 0;

reg [9:0] p1_x = 100;
reg [9:0] p1_y = 240;
reg [9:0] p2_x = 500;
reg [9:0] p2_y = 240;

parameter P1_BULLET_SIZE = 4;
parameter P1_MAX_BULLETS = 8;
parameter P1_TANK_SIZE = 20;  

parameter P2_BULLET_SIZE = 4;
parameter P2_MAX_BULLETS = 8; 
parameter P2_TANK_SIZE = 20;  

reg [3:0] P1_MAX_HEALTH_REG;
reg [3:0] P2_MAX_HEALTH_REG;

parameter INVINCIBLE_TIME = 100000000; 

reg [P1_MAX_BULLETS-1:0] p1_bullet_active = 0;
reg [9:0] p1_bullet_x [0:P1_MAX_BULLETS-1];
reg [9:0] p1_bullet_y [0:P1_MAX_BULLETS-1];
reg p1_bullet_dir [0:P1_MAX_BULLETS-1]; 

reg [P2_MAX_BULLETS-1:0] p2_bullet_active = 0;
reg [9:0] p2_bullet_x [0:P2_MAX_BULLETS-1];
reg [9:0] p2_bullet_y [0:P2_MAX_BULLETS-1];
reg p2_bullet_dir [0:P2_MAX_BULLETS-1]; 

reg p1_can_shoot = 1;
reg p2_can_shoot = 1;
reg [24:0] p1_shoot_timer = 0;
reg [24:0] p2_shoot_timer = 0;

reg [24:0] P1_SHOOT_COOLDOWN; 
reg [24:0] P2_SHOOT_COOLDOWN; 
reg [19:0] MOVE_SPEED_DIVIDER;
reg [16:0] BULLET_SPEED_DIVIDER; 

always @(*) begin

    P1_SHOOT_COOLDOWN = 30000000 - (shoot_cooldown_level * 2500000);
    P2_SHOOT_COOLDOWN = 30000000 - (shoot_cooldown_level * 2500000);


	 if (P1_SHOOT_COOLDOWN < 12500000) P1_SHOOT_COOLDOWN = 12500000;
	 if (P2_SHOOT_COOLDOWN < 12500000) P2_SHOOT_COOLDOWN = 12500000;
	
    MOVE_SPEED_DIVIDER = 1000000 - (game_speed_level * 60000);
    if (MOVE_SPEED_DIVIDER < 100000) MOVE_SPEED_DIVIDER = 100000;
    
    BULLET_SPEED_DIVIDER = 200000 - (bullet_speed_level * 25000);
    if (BULLET_SPEED_DIVIDER < 50000) BULLET_SPEED_DIVIDER = 50000;
	 
	 if (health_mode_switch) begin
        P1_MAX_HEALTH_REG = 4'd15;  // 拨码为1时，最大血量15
        P2_MAX_HEALTH_REG = 4'd15;
    end else begin
        P1_MAX_HEALTH_REG = 4'd5;   // 拨码为0时，最大血量5
        P2_MAX_HEALTH_REG = 4'd5;
    end
	 
end

reg [16:0] bullet_move_counter = 0;

reg [26:0] p1_invincible_timer = 0;
reg [26:0] p2_invincible_timer = 0;
reg p1_invincible = 0;
reg p2_invincible = 0;

reg p1_alive = 1;
reg p2_alive = 1;
reg game_over = 0;         
reg winner_is_p1 = 0;  

reg [3:0] reset_counter = 0;
wire reset = (reset_counter != 4'b1111);

reg [19:0] move_counter = 0;

parameter OBSTACLE_COUNT = 8;  
parameter OBSTACLE_SIZE = 30;  

parameter P1_START_X = 100;
parameter P1_START_Y = 240;
parameter P2_START_X = 500;
parameter P2_START_Y = 240;
parameter TANK_SIZE = 20;
parameter SAFE_DISTANCE = 50; 

reg [9:0] obstacle_x [0:OBSTACLE_COUNT-1];
reg [9:0] obstacle_y [0:OBSTACLE_COUNT-1];
reg obstacle_active [0:OBSTACLE_COUNT-1];

integer obs_i;
initial begin
    for (obs_i = 0; obs_i < OBSTACLE_COUNT; obs_i = obs_i + 1) begin
        obstacle_x[obs_i] <= 0;
        obstacle_y[obs_i] <= 0;
        obstacle_active[obs_i] <= 0;
    end
end

always @(*) begin
    if (enable_obstacles) begin
        if (map_type) begin 
            
            obstacle_x[0] <= 150; 
            obstacle_y[0] <= 80; 
            obstacle_active[0] <= 1;
            
            obstacle_x[1] <= 220; 
            obstacle_y[1] <= 180; 
            obstacle_active[1] <= 1;
            
            obstacle_x[2] <= 380; 
            obstacle_y[2] <= 100; 
            obstacle_active[2] <= 1;
            
            obstacle_x[3] <= 180; 
            obstacle_y[3] <= 280; 
            obstacle_active[3] <= 1;
            
            obstacle_x[4] <= 420; 
            obstacle_y[4] <= 280; 
            obstacle_active[4] <= 1;
            
            obstacle_x[5] <= 140; 
            obstacle_y[5] <= 380; 
            obstacle_active[5] <= 1;
            
            obstacle_x[6] <= 480; 
            obstacle_y[6] <= 380; 
            obstacle_active[6] <= 1;
            
            obstacle_x[7] <= 520; 
            obstacle_y[7] <= 180; 
            obstacle_active[7] <= 1;
        end else begin 
            obstacle_x[0] <= 180; 
            obstacle_y[0] <= 120; 
            obstacle_active[0] <= 1;
            
            obstacle_x[1] <= 460; 
            obstacle_y[1] <= 140; 
            obstacle_active[1] <= 1;
            
            obstacle_x[2] <= 250; 
            obstacle_y[2] <= 200; 
            obstacle_active[2] <= 1;
            
            obstacle_x[3] <= 390; 
            obstacle_y[3] <= 300; 
            obstacle_active[3] <= 1;
            
            obstacle_x[4] <= 160; 
            obstacle_y[4] <= 360; 
            obstacle_active[4] <= 1;
            
            obstacle_x[5] <= 520; 
            obstacle_y[5] <= 320; 
            obstacle_active[5] <= 1;
            
            obstacle_x[6] <= 320; 
            obstacle_y[6] <= 80; 
            obstacle_active[6] <= 1;
            
            obstacle_x[7] <= 320; 
            obstacle_y[7] <= 400; 
            obstacle_active[7] <= 1;
        end
    end else begin
        for (obs_i = 0; obs_i < OBSTACLE_COUNT; obs_i = obs_i + 1) begin
            obstacle_x[obs_i] <= 0;
            obstacle_y[obs_i] <= 0;
            obstacle_active[obs_i] <= 0;
        end
    end
end

function is_obstacle_collision;
    input [9:0] rect_x, rect_y, rect_w, rect_h;
    integer i;
    reg collision;
    begin
        collision = 0;
        if (enable_obstacles) begin
            for (i = 0; i < OBSTACLE_COUNT; i = i + 1) begin
                if (obstacle_active[i] && is_collision(rect_x, rect_y, rect_w, rect_h,
                                                      obstacle_x[i], obstacle_y[i], OBSTACLE_SIZE, OBSTACLE_SIZE)) begin
                    collision = 1;
                end
            end
        end
        is_obstacle_collision = collision;
    end
endfunction

integer i;
initial begin
    for (i = 0; i < P1_MAX_BULLETS; i = i + 1) begin
        p1_bullet_x[i] <= 0;
        p1_bullet_y[i] <= 0;
        p1_bullet_dir[i] <= 0;
    end
    for (i = 0; i < P2_MAX_BULLETS; i = i + 1) begin
        p2_bullet_x[i] <= 0;
        p2_bullet_y[i] <= 0;
        p2_bullet_dir[i] <= 1;
    end
    p1_health <= P1_MAX_HEALTH_REG;
    p2_health <= P2_MAX_HEALTH_REG;
    p1_alive <= 1;
    p2_alive <= 1;
end

function is_collision;
    input [9:0] rect1_x, rect1_y, rect1_w, rect1_h;
    input [9:0] rect2_x, rect2_y, rect2_w, rect2_h;
    begin
        is_collision = (rect1_x < rect2_x + rect2_w) &&
                      (rect1_x + rect1_w > rect2_x) &&
                      (rect1_y < rect2_y + rect2_h) &&
                      (rect1_y + rect1_h > rect2_y);
    end
endfunction

function [7:0] get_char_pixels; 
    input [2:0] char_code;  
    input [2:0] line;       
    reg [7:0] pixels;
    begin
        case (char_code)
            // W
            3'd0: begin
                case (line)
                    3'd0: pixels = 8'b10000001;
                    3'd1: pixels = 8'b10000001;
                    3'd2: pixels = 8'b10000001;
                    3'd3: pixels = 8'b10011001;
                    3'd4: pixels = 8'b10100101;
                    3'd5: pixels = 8'b10100101;
                    3'd6: pixels = 8'b11000011;
                    3'd7: pixels = 8'b10000001;
                endcase
            end
            // I
            3'd1: begin
                case (line)
                    3'd0: pixels = 8'b01111110;
                    3'd1: pixels = 8'b00011000;
                    3'd2: pixels = 8'b00011000;
                    3'd3: pixels = 8'b00011000;
                    3'd4: pixels = 8'b00011000;
                    3'd5: pixels = 8'b00011000;
                    3'd6: pixels = 8'b00011000;
                    3'd7: pixels = 8'b01111110;
                endcase
            end
            // N
            3'd2: begin
                case (line)
                    3'd0: pixels = 8'b10000001;
                    3'd1: pixels = 8'b10000011;
                    3'd2: pixels = 8'b10000101;
                    3'd3: pixels = 8'b10001001;
                    3'd4: pixels = 8'b10010001;
                    3'd5: pixels = 8'b10100001;
                    3'd6: pixels = 8'b11000001;
                    3'd7: pixels = 8'b10000001;
                endcase
            end
            // L
            3'd3: begin
                case (line)
                    3'd0: pixels = 8'b00000001;
                    3'd1: pixels = 8'b00000001;
                    3'd2: pixels = 8'b00000001;
                    3'd3: pixels = 8'b00000001;
                    3'd4: pixels = 8'b00000001;
                    3'd5: pixels = 8'b00000001;
                    3'd6: pixels = 8'b00000001;
                    3'd7: pixels = 8'b11111111;
                endcase
            end
            // O
            3'd4: begin
                case (line)
                    3'd0: pixels = 8'b01111110;
                    3'd1: pixels = 8'b10000001;
                    3'd2: pixels = 8'b10000001;
                    3'd3: pixels = 8'b10000001;
                    3'd4: pixels = 8'b10000001;
                    3'd5: pixels = 8'b10000001;
                    3'd6: pixels = 8'b10000001;
                    3'd7: pixels = 8'b01111110;
                endcase
            end
            // S
            3'd5: begin
                case (line)
                    3'd0: pixels = 8'b01111110;
                    3'd1: pixels = 8'b00000001;
                    3'd2: pixels = 8'b00000001;
                    3'd3: pixels = 8'b01111110;
                    3'd4: pixels = 8'b10000000;
                    3'd5: pixels = 8'b10000000;
                    3'd6: pixels = 8'b10000000;
                    3'd7: pixels = 8'b11111110;
                endcase
            end
            // E
            3'd6: begin
                case (line)
                    3'd0: pixels = 8'b11111111;
                    3'd1: pixels = 8'b00000001;
                    3'd2: pixels = 8'b00000001;
                    3'd3: pixels = 8'b00111111;
                    3'd4: pixels = 8'b00111111;
                    3'd5: pixels = 8'b00000001;
                    3'd6: pixels = 8'b00000001;
                    3'd7: pixels = 8'b11111111;
                endcase
            end
            default: pixels = 8'b00000000;
        endcase
        get_char_pixels = pixels;
    end
endfunction

wire is_win_text_area, is_lose_text_area;
wire [2:0] win_char_index, lose_char_index;
wire win_char_pixel, lose_char_pixel;

assign is_win_text_area = game_over && 
    ((winner_is_p1 && (pixel_x >= 100 && pixel_x < 100 + 16*3 && pixel_y >= 200 && pixel_y < 200 + 16)) ||  // 红方胜利：WIN在左边
     (!winner_is_p1 && (pixel_x >= 480 && pixel_x < 480 + 16*3 && pixel_y >= 200 && pixel_y < 200 + 16))); // 蓝方胜利：WIN在右边

assign is_lose_text_area = game_over && 
    ((winner_is_p1 && (pixel_x >= 480 && pixel_x < 480 + 16*4 && pixel_y >= 200 && pixel_y < 200 + 16)) ||  // 红方胜利：LOSE在右边
     (!winner_is_p1 && (pixel_x >= 100 && pixel_x < 100 + 16*4 && pixel_y >= 200 && pixel_y < 200 + 16))); // 蓝方胜利：LOSE在左边

assign win_char_index = 
    (winner_is_p1) ? 
        (((pixel_x - 100) < 16) ? 3'd0 :  // W
         ((pixel_x - 100) < 32) ? 3'd1 :  // I
         ((pixel_x - 100) < 48) ? 3'd2 :  // N
         3'd0) :
        (((pixel_x - 480) < 16) ? 3'd0 :  // W
         ((pixel_x - 480) < 32) ? 3'd1 :  // I
         ((pixel_x - 480) < 48) ? 3'd2 :  // N
         3'd0);

assign lose_char_index = 
    (winner_is_p1) ?
        (((pixel_x - 480) < 16) ? 3'd3 :  // L
         ((pixel_x - 480) < 32) ? 3'd4 :  // O
         ((pixel_x - 480) < 48) ? 3'd5 :  // S
         ((pixel_x - 480) < 64) ? 3'd6 :  // E
         3'd0) :
        (((pixel_x - 100) < 16) ? 3'd3 :  // L
         ((pixel_x - 100) < 32) ? 3'd4 :  // O
         ((pixel_x - 100) < 48) ? 3'd5 :  // S
         ((pixel_x - 100) < 64) ? 3'd6 :  // E
         3'd0);

wire [2:0] win_char_line = (pixel_y - 200) / 2;
wire [2:0] lose_char_line = (pixel_y - 200) / 2;

wire [7:0] win_char_pixels = get_char_pixels(win_char_index, win_char_line);
wire [7:0] lose_char_pixels = get_char_pixels(lose_char_index, lose_char_line);

assign win_char_pixel = is_win_text_area ? 
    win_char_pixels[((winner_is_p1 ? (pixel_x - 100) : (pixel_x - 480)) % 16) / 2] : 1'b0;
    
assign lose_char_pixel = is_lose_text_area ? 
    lose_char_pixels[((winner_is_p1 ? (pixel_x - 480) : (pixel_x - 100)) % 16) / 2] : 1'b0;
	 
task reset_game_task;
    integer i;
    begin
        p1_health <= P1_MAX_HEALTH_REG;  
        p2_health <= P2_MAX_HEALTH_REG; 
        p1_alive <= 1;
        p2_alive <= 1;
             game_over <= 0;       
        winner_is_p1 <= 0;    
		  
        p1_x <= 100;
        p1_y <= 240;
        p2_x <= 500;
        p2_y <= 240;
        
        p1_invincible <= 0;
        p2_invincible <= 0;
        p1_invincible_timer <= 0;
        p2_invincible_timer <= 0;
        
        for (i = 0; i < P1_MAX_BULLETS; i = i + 1) begin
            p1_bullet_active[i] <= 0;
        end
        for (i = 0; i < P2_MAX_BULLETS; i = i + 1) begin
            p2_bullet_active[i] <= 0;
        end
        
        p1_can_shoot <= 1;
        p2_can_shoot <= 1;
        p1_shoot_timer <= 0;
        p2_shoot_timer <= 0;
        
        p1_bullet_hit <= 0; 
        p1_tank_move <= 0; 
        p1_shoot_sound <= 0;
        p2_bullet_hit <= 0; 
        p2_tank_move <= 0; 
        p2_shoot_sound <= 0;
        p1_sound_duration <= 0; 
        p2_sound_duration <= 0;
        
    end
endtask

always @(posedge CLOCK_50) begin

    clk_25 <= ~clk_25;
    
    if (reset) begin
        reset_counter <= reset_counter + 1;

        p1_bullet_hit_trigger <= 0; 
        p1_tank_move_trigger <= 0; 
        p1_shoot_trigger <= 0;
        p2_bullet_hit_trigger <= 0; 
        p2_tank_move_trigger <= 0; 
        p2_shoot_trigger <= 0;
        p1_bullet_hit <= 0; 
        p1_tank_move <= 0; 
        p1_shoot_sound <= 0;
        p2_bullet_hit <= 0; 
        p2_tank_move <= 0; 
        p2_shoot_sound <= 0;
        p1_sound_duration <= 0; 
        p2_sound_duration <= 0;

        reset_game_task;
    end
    
    if (reset_game) begin
        reset_game_task;
    end
    
    if (p1_health == 0 && p1_alive) begin
        p1_alive <= 0;
    end
    
    if (p2_health == 0 && p2_alive) begin
        p2_alive <= 0;
    end

if (p1_health == 0 && p1_alive) begin
    p1_alive <= 0;
    if (p2_alive) begin  
        game_over <= 1;
        winner_is_p1 <= 0;  
    end
end

if (p2_health == 0 && p2_alive) begin
    p2_alive <= 0;
    if (p1_alive) begin  
        game_over <= 1;
        winner_is_p1 <= 1; 
    end
end

if (p1_health == 0 && p2_health == 0 && (p1_alive || p2_alive)) begin
    p1_alive <= 0;
    p2_alive <= 0;
    game_over <= 1;
    winner_is_p1 <= 1;  
end

    move_counter <= move_counter + 1;
    
    bullet_move_counter <= bullet_move_counter + 1;
     
    if (!p1_can_shoot) begin
        p1_shoot_timer <= p1_shoot_timer + 1;
        if (p1_shoot_timer >= P1_SHOOT_COOLDOWN) begin
            p1_can_shoot <= 1;
            p1_shoot_timer <= 0;
        end
    end
    
    if (!p2_can_shoot) begin
        p2_shoot_timer <= p2_shoot_timer + 1;
        if (p2_shoot_timer >= P2_SHOOT_COOLDOWN) begin
            p2_can_shoot <= 1;
            p2_shoot_timer <= 0;
        end 
    end
    
    if (p1_invincible && p1_alive) begin
        p1_invincible_timer <= p1_invincible_timer + 1;
        if (p1_invincible_timer >= INVINCIBLE_TIME) begin
            p1_invincible <= 0;
            p1_invincible_timer <= 0;
        end
    end
    
    if (p2_invincible && p2_alive) begin
        p2_invincible_timer <= p2_invincible_timer + 1;
        if (p2_invincible_timer >= INVINCIBLE_TIME) begin
            p2_invincible <= 0;
            p2_invincible_timer <= 0;
        end
    end
    
    if (!reset && move_counter >= MOVE_SPEED_DIVIDER) begin
        move_counter <= 0;
        
        if (p1_alive) begin
            reg can_move_up, can_move_down, can_move_left, can_move_right;
            
            can_move_up = (p1_y > 20) && !is_obstacle_collision(p1_x, p1_y - 2, P1_TANK_SIZE, P1_TANK_SIZE);
            can_move_down = (p1_y < 460) && !is_obstacle_collision(p1_x, p1_y + 2, P1_TANK_SIZE, P1_TANK_SIZE);
            can_move_left = (p1_x > 20) && !is_obstacle_collision(p1_x - 2, p1_y, P1_TANK_SIZE, P1_TANK_SIZE);
            can_move_right = (p1_x < 290) && !is_obstacle_collision(p1_x + 2, p1_y, P1_TANK_SIZE, P1_TANK_SIZE);
            
            if (p1_up && can_move_up) p1_y <= p1_y - 2;
            if (p1_down && can_move_down) p1_y <= p1_y + 2;
            if (p1_left && can_move_left) p1_x <= p1_x - 2;
            if (p1_right && can_move_right) p1_x <= p1_x + 2;
        end
        
        if (p2_alive) begin
            reg can_move_up, can_move_down, can_move_left, can_move_right;
            
            can_move_up = (p2_y > 20) && !is_obstacle_collision(p2_x, p2_y - 2, P2_TANK_SIZE, P2_TANK_SIZE);
            can_move_down = (p2_y < 460) && !is_obstacle_collision(p2_x, p2_y + 2, P2_TANK_SIZE, P2_TANK_SIZE);
            can_move_left = (p2_x > 340) && !is_obstacle_collision(p2_x - 2, p2_y, P2_TANK_SIZE, P2_TANK_SIZE);
            can_move_right = (p2_x < 620) && !is_obstacle_collision(p2_x + 2, p2_y, P2_TANK_SIZE, P2_TANK_SIZE);
            
            if (p2_up && can_move_up) p2_y <= p2_y - 2;
            if (p2_down && can_move_down) p2_y <= p2_y + 2;
            if (p2_left && can_move_left) p2_x <= p2_x - 2;
            if (p2_right && can_move_right) p2_x <= p2_x + 2;
        end
        
        if (p1_alive && (p1_up || p1_down || p1_left || p1_right)) begin
            p1_tank_move_trigger <= 1;  
        end
        if (p2_alive && (p2_up || p2_down || p2_left || p2_right)) begin
            p2_tank_move_trigger <= 1;  
        end
    end
    
    if (!reset) begin

	 if (p1_action && p1_can_shoot && p1_alive) begin

			reg found_slot;
            found_slot = 0;
            for (i = 0; i < P1_MAX_BULLETS && !found_slot; i = i + 1) begin
                if (!p1_bullet_active[i]) begin
                    p1_bullet_active[i] <= 1;
                    p1_bullet_x[i] <= p1_x + 25; 
                    p1_bullet_y[i] <= p1_y + 10; 
                    p1_bullet_dir[i] <= 0; 
                    p1_can_shoot <= 0;
                    found_slot = 1;
                    p1_shoot_trigger <= 1;  
                end
            end
        end
        
        if (p2_action && p2_can_shoot && p2_alive) begin
            reg found_slot;
            found_slot = 0;
            for (i = 0; i < P2_MAX_BULLETS && !found_slot; i = i + 1) begin
                if (!p2_bullet_active[i]) begin
                    p2_bullet_active[i] <= 1;
                    p2_bullet_x[i] <= p2_x - 5; 
                    p2_bullet_y[i] <= p2_y + 10; 
                    p2_bullet_dir[i] <= 1; 
                    p2_can_shoot <= 0;
                    found_slot = 1;
                    p2_shoot_trigger <= 1;  
                end
            end
        end
    end
    
    if (!reset && bullet_move_counter >= BULLET_SPEED_DIVIDER) begin
        bullet_move_counter <= 0;
        
        for (i = 0; i < P1_MAX_BULLETS; i = i + 1) begin
            if (p1_bullet_active[i]) begin

				if (enable_obstacles && is_obstacle_collision(p1_bullet_x[i], p1_bullet_y[i], P1_BULLET_SIZE, P1_BULLET_SIZE)) begin
                    p1_bullet_active[i] <= 0; 
                end
                
                else if (p1_bullet_dir[i] == 0) begin
                    p1_bullet_x[i] <= p1_bullet_x[i] + 1; 
                end else begin
                    p1_bullet_x[i] <= p1_bullet_x[i] - 1; 
                end
                
                if (p1_bullet_x[i] < 5 || p1_bullet_x[i] > 635 || 
                    p1_bullet_y[i] < 5 || p1_bullet_y[i] > 475) begin
                    p1_bullet_active[i] <= 0;
                end

                else if (p2_alive && !p2_invincible && is_collision(p1_bullet_x[i], p1_bullet_y[i], P1_BULLET_SIZE, P1_BULLET_SIZE,
                                     p2_x, p2_y, P2_TANK_SIZE, P2_TANK_SIZE)) begin
                    p1_bullet_active[i] <= 0; 
                    p1_bullet_hit_trigger <= 1;  
                    
                    if (p2_health > 0) begin
                        p2_health <= p2_health - 1;
                        p2_invincible <= 1; 
                    end
                end
            end
        end
        
        for (i = 0; i < P2_MAX_BULLETS; i = i + 1) begin
            if (p2_bullet_active[i]) begin
                if (enable_obstacles && is_obstacle_collision(p2_bullet_x[i], p2_bullet_y[i], P2_BULLET_SIZE, P2_BULLET_SIZE)) begin
                    p2_bullet_active[i] <= 0; 
                end
               
                else if (p2_bullet_dir[i] == 0) begin
                    p2_bullet_x[i] <= p2_bullet_x[i] + 1; // 向右
                end else begin
                    p2_bullet_x[i] <= p2_bullet_x[i] - 1; // 向左
                end
                
                if (p2_bullet_x[i] < 5 || p2_bullet_x[i] > 635 || 
                    p2_bullet_y[i] < 5 || p2_bullet_y[i] > 475) begin
                    p2_bullet_active[i] <= 0;
                end
                else if (p1_alive && !p1_invincible && is_collision(p2_bullet_x[i], p2_bullet_y[i], P2_BULLET_SIZE, P2_BULLET_SIZE,
                                     p1_x, p1_y, P1_TANK_SIZE, P1_TANK_SIZE)) begin
                    p2_bullet_active[i] <= 0; 
                    p2_bullet_hit_trigger <= 1;  
                    
                    if (p1_health > 0) begin
                        p1_health <= p1_health - 1;
                        p1_invincible <= 1; 
                    end
                end
            end
        end
    end
    
    if (p1_bullet_hit_trigger || p1_shoot_trigger || p1_tank_move_trigger) begin

		  p1_sound_duration <= 24'd100_000;  

		  p1_bullet_hit <= p1_bullet_hit_trigger;
        p1_shoot_sound <= p1_shoot_trigger;
        p1_tank_move <= p1_tank_move_trigger;

        p1_bullet_hit_trigger <= 0;
        p1_shoot_trigger <= 0;
        p1_tank_move_trigger <= 0;
    end else if (p1_sound_duration > 0) begin
        p1_sound_duration <= p1_sound_duration - 1;
    end else begin
        p1_bullet_hit <= 0;
        p1_shoot_sound <= 0;
        p1_tank_move <= 0;
    end
    
    if (p2_bullet_hit_trigger || p2_shoot_trigger || p2_tank_move_trigger) begin
        p2_sound_duration <= 24'd100_000; 

        p2_bullet_hit <= p2_bullet_hit_trigger;
        p2_shoot_sound <= p2_shoot_trigger;
        p2_tank_move <= p2_tank_move_trigger;
        
        p2_bullet_hit_trigger <= 0;
        p2_shoot_trigger <= 0;
        p2_tank_move_trigger <= 0;
    end else if (p2_sound_duration > 0) begin
        
        p2_sound_duration <= p2_sound_duration - 1;
    end else begin
        
        p2_bullet_hit <= 0;
        p2_shoot_sound <= 0;
        p2_tank_move <= 0;
    end
end

always @(posedge clk_25) begin
    if (reset) begin
        h_count <= 0;
        v_count <= 0;
    end else begin
        if (h_count < H_TOTAL - 1)
            h_count <= h_count + 1;
        else begin
            h_count <= 0;
            if (v_count < V_TOTAL - 1)
                v_count <= v_count + 1;
            else
                v_count <= 0;
        end
    end
end

assign VGA_HS = (h_count < H_SYNC) ? 1'b0 : 1'b1;
assign VGA_VS = (v_count < V_SYNC) ? 1'b0 : 1'b1;
assign VGA_CLK = clk_25;
assign VGA_BLANK_N = (h_count >= H_SYNC + H_BACK) && (h_count < H_SYNC + H_BACK + H_ACTIVE) && 
                     (v_count >= V_SYNC + V_BACK) && (v_count < V_SYNC + V_BACK + V_ACTIVE);
assign VGA_SYNC_N = 1'b0;

wire [9:0] pixel_x = h_count - (H_SYNC + H_BACK);
wire [9:0] pixel_y = v_count - (V_SYNC + V_BACK);
wire active = (pixel_x < H_ACTIVE) && (pixel_y < V_ACTIVE);

wire is_p1_tank = p1_alive && (pixel_x >= p1_x && pixel_x < p1_x + P1_TANK_SIZE && 
                   pixel_y >= p1_y && pixel_y < p1_y + P1_TANK_SIZE);
wire is_p2_tank = p2_alive && (pixel_x >= p2_x && pixel_x < p2_x + P2_TANK_SIZE && 
                   pixel_y >= p2_y && pixel_y < p2_y + P2_TANK_SIZE);
wire is_p1_gun = p1_alive && (pixel_x >= p1_x + P1_TANK_SIZE && pixel_x < p1_x + P1_TANK_SIZE + 5 && 
                  pixel_y >= p1_y + 7 && pixel_y < p1_y + 13);
wire is_p2_gun = p2_alive && (pixel_x >= p2_x - 5 && pixel_x < p2_x && 
                  pixel_y >= p2_y + 7 && pixel_y < p2_y + 13);
wire is_center_line = (pixel_x > 320 && pixel_x < 330);
wire is_border = (pixel_x < 5 || pixel_x > 634 || pixel_y < 5 || pixel_y > 474);

reg is_obstacle_any;
integer obs_j;
always @(*) begin
    is_obstacle_any = 0;
    if (enable_obstacles) begin
        for (obs_j = 0; obs_j < OBSTACLE_COUNT; obs_j = obs_j + 1) begin
            if (obstacle_active[obs_j] && 
                (pixel_x >= obstacle_x[obs_j] && pixel_x < obstacle_x[obs_j] + OBSTACLE_SIZE && 
                 pixel_y >= obstacle_y[obs_j] && pixel_y < obstacle_y[obs_j] + OBSTACLE_SIZE)) begin
                is_obstacle_any = 1;
            end
        end
    end
end

reg is_p1_bullet_any;
reg is_p2_bullet_any;
integer j;

always @(*) begin
    is_p1_bullet_any = 0;
    is_p2_bullet_any = 0;
    
    for (j = 0; j < P1_MAX_BULLETS; j = j + 1) begin
        if (p1_bullet_active[j] && 
            (pixel_x >= p1_bullet_x[j] && pixel_x < p1_bullet_x[j] + P1_BULLET_SIZE && 
             pixel_y >= p1_bullet_y[j] && pixel_y < p1_bullet_y[j] + P1_BULLET_SIZE)) begin
            is_p1_bullet_any = 1;
        end
    end
    for (j = 0; j < P2_MAX_BULLETS; j = j + 1) begin
        if (p2_bullet_active[j] && 
            (pixel_x >= p2_bullet_x[j] && pixel_x < p2_bullet_x[j] + P2_BULLET_SIZE && 
             pixel_y >= p2_bullet_y[j] && pixel_y < p2_bullet_y[j] + P2_BULLET_SIZE)) begin
            is_p2_bullet_any = 1;
        end
    end
end

always @(posedge clk_25) begin
    if (active) begin
	         if (game_over) begin
            
             if (winner_is_p1) begin
                
                if (is_win_text_area && win_char_pixel) begin
                    VGA_R <= 8'hFF;  // 红色WIN
                    VGA_G <= 8'h00;
                    VGA_B <= 8'h00;
                end else if (is_lose_text_area && lose_char_pixel) begin
                    VGA_R <= 8'h00;  // 蓝色LOSE
                    VGA_G <= 8'h00;
                    VGA_B <= 8'hFF;
                end else begin
                    VGA_R <= 8'h40;  // 暗红色背景
                    VGA_G <= 8'h00;
                    VGA_B <= 8'h00;
                end
            end else begin
                if (is_win_text_area && win_char_pixel) begin
                    VGA_R <= 8'h00;  // 蓝色WIN
                    VGA_G <= 8'h00;
                    VGA_B <= 8'hFF;
                end else if (is_lose_text_area && lose_char_pixel) begin
                    VGA_R <= 8'hFF;  // 红色LOSE
                    VGA_G <= 8'h00;
                    VGA_B <= 8'h00;
                end else begin
                    VGA_R <= 8'h00;  // 暗蓝色背景
                    VGA_G <= 8'h00;
                    VGA_B <= 8'h40;
                end
            end
        end else begin
        if (map_type) begin
            VGA_R <= 8'h20; 
            VGA_G <= 8'h20;
            VGA_B <= 8'h20;
        end else begin
            VGA_R <= 8'h40;  
            VGA_G <= 8'h40;
            VGA_B <= 8'h40;
        end
        
        if (is_p1_bullet_any) begin
            VGA_R <= 8'hFF; VGA_G <= 8'h00; VGA_B <= 8'h00;  
        end else if (is_p2_bullet_any) begin
            VGA_R <= 8'h00; VGA_G <= 8'h00; VGA_B <= 8'hFF; 
        end else if (is_obstacle_any && enable_obstacles) begin
				VGA_R <= 8'hFF; VGA_G <= 8'hA5; VGA_B <= 8'h00;  
        end else if (is_p1_gun || is_p2_gun) begin
            VGA_R <= 8'hFF; VGA_G <= 8'hFF; VGA_B <= 8'hFF;  
        end else if (is_p1_tank) begin
            if (p1_invincible && p1_invincible_timer[22]) begin
                VGA_R <= 8'hFF; VGA_G <= 8'hFF; VGA_B <= 8'h00;  
            end else begin
                VGA_R <= 8'hFF; VGA_G <= 8'h00; VGA_B <= 8'h00; 
            end
        end else if (is_p2_tank) begin
            if (p2_invincible && p2_invincible_timer[22]) begin
                VGA_R <= 8'hFF; VGA_G <= 8'hFF; VGA_B <= 8'h00;  
            end else begin
                VGA_R <= 8'h00; VGA_G <= 8'h00; VGA_B <= 8'hFF;  
            end
        end else if (is_center_line) begin
            VGA_R <= 8'hFF; VGA_G <= 8'hFF; VGA_B <= 8'hFF;  
        end else if (is_border) begin
            VGA_R <= 8'h00; VGA_G <= 8'hFF; VGA_B <= 8'h00; 
        end
		end
    end else begin
        VGA_R <= 8'h00;
        VGA_G <= 8'h00;
        VGA_B <= 8'h00;
    end
end

endmodule
