module game(
    input CLOCK_50,
    input PS2_CLK,
    input PS2_DAT,
    output [7:0] VGA_R, VGA_G, VGA_B,
    output VGA_HS, VGA_VS, VGA_CLK, VGA_BLANK_N, VGA_SYNC_N,

    input AUD_ADCDAT,
    inout AUD_ADCLRCK,
    inout AUD_BCLK,
    output AUD_DACDAT,
    inout AUD_DACLRCK,
    output AUD_XCK,
    
    output I2C_SCLK,
    inout I2C_SDAT,
    
    input [3:0] KEY,
    input [17:0] SW,  
    
    output [6:0] hex7, hex6, hex5, hex4,  
    output [6:0] hex3, hex2, hex1, hex0   
);

wire p1_up, p1_down, p1_left, p1_right;
wire p1_action, p2_up, p2_down, p2_left, p2_right, p2_action, start_pause;  

wire p1_bullet_hit, p1_tank_move, p1_shoot_sound;
wire p2_bullet_hit, p2_tank_move, p2_shoot_sound;

wire [3:0] p1_health, p2_health;

wire [3:0] game_speed_level;    
wire [2:0] bullet_speed_level;  
wire [2:0] shoot_cooldown_level; 
wire map_type;                  
wire enable_obstacles;          

wire health_mode_switch = SW[12];      
assign game_speed_level = SW[11:8];      
assign bullet_speed_level = SW[7:5];    
assign shoot_cooldown_level = SW[4:2];  
assign map_type = SW[1];               
assign enable_obstacles = SW[0];       

keyboard keyboard_inst(  
    .CLOCK_50(CLOCK_50),
    .PS2_CLK(PS2_CLK),
    .PS2_DAT(PS2_DAT),
    .p1_up(p1_up), 
    .p1_down(p1_down),
    .p1_left(p1_left),
    .p1_right(p1_right),
    .p1_action(p1_action),
    .p2_up(p2_up),
    .p2_down(p2_down), 
    .p2_left(p2_left),
    .p2_right(p2_right),
    .p2_action(p2_action), 
    .start_pause(start_pause)
); 

vga_keyboard vga_inst(
    .CLOCK_50(CLOCK_50),
    .p1_up(p1_up),
    .p1_down(p1_down), 
    .p1_left(p1_left),
    .p1_right(p1_right),
    .p1_action(p1_action),
    .p2_up(p2_up),
    .p2_down(p2_down),
    .p2_left(p2_left),
    .p2_right(p2_right),
    .p2_action(p2_action),
    .start_pause(start_pause),
    .reset_game(~KEY[0]),  
    .VGA_R(VGA_R),
    .VGA_G(VGA_G),
    .VGA_B(VGA_B),
    .VGA_HS(VGA_HS),
    .VGA_VS(VGA_VS),
    .VGA_CLK(VGA_CLK),
    .VGA_BLANK_N(VGA_BLANK_N),
    .VGA_SYNC_N(VGA_SYNC_N),

    .p1_bullet_hit(p1_bullet_hit),
    .p1_tank_move(p1_tank_move), 
    .p1_shoot_sound(p1_shoot_sound),
    .p2_bullet_hit(p2_bullet_hit),
    .p2_tank_move(p2_tank_move),
    .p2_shoot_sound(p2_shoot_sound),
    .p1_health(p1_health),
    .p2_health(p2_health),
    
    .game_speed_level(game_speed_level),
    .bullet_speed_level(bullet_speed_level),
    .shoot_cooldown_level(shoot_cooldown_level),
    .map_type(map_type),
    .enable_obstacles(enable_obstacles),
	 .health_mode_switch(health_mode_switch)  

);

Synthesizer audio_inst(

    .CLOCK_50(CLOCK_50),
    .KEY(KEY),
    .SW(SW),
    
    .AUD_ADCDAT(AUD_ADCDAT),
    .AUD_ADCLRCK(AUD_ADCLRCK),
    .AUD_BCLK(AUD_BCLK),
    .AUD_DACDAT(AUD_DACDAT),
    .AUD_DACLRCK(AUD_DACLRCK),
    .AUD_XCK(AUD_XCK),
    
    .I2C_SCLK(I2C_SCLK),
    .I2C_SDAT(I2C_SDAT),
    
    .p1_bullet_hit(p1_bullet_hit),
    .p1_tank_move(p1_tank_move), 
    .p1_shoot_sound(p1_shoot_sound),
    .p2_bullet_hit(p2_bullet_hit),
    .p2_tank_move(p2_tank_move),
    .p2_shoot_sound(p2_shoot_sound)
);

wire [3:0] p1_health_ten, p1_health_one;
bin2bcd p1_health_bcd(
    .bin(p1_health),
    .bcd_ten(p1_health_ten),
    .bcd_one(p1_health_one)
);

wire [3:0] p2_health_ten, p2_health_one;
bin2bcd p2_health_bcd(
    .bin(p2_health),
    .bcd_ten(p2_health_ten),
    .bcd_one(p2_health_one)
);


seg seg_p1_ten(          
    .d_in(p1_health_ten),
    .seg_out(hex7)
);

seg seg_p1_one(          
    .d_in(p1_health_one),
    .seg_out(hex6)
);

seg seg_p2_ten(          
    .d_in(p2_health_ten),
    .seg_out(hex5)
);

seg seg_p2_one(          
    .d_in(p2_health_one),
    .seg_out(hex4)
);

seg seg_game_speed(     
    .d_in(game_speed_level),
    .seg_out(hex3)
);

wire [3:0] bullet_speed_display = {1'b0, bullet_speed_level};
seg seg_bullet_speed(    
    .d_in(bullet_speed_display),
    .seg_out(hex2)
);

wire [3:0] shoot_cooldown_display = {1'b0, shoot_cooldown_level};
seg seg_shoot_cooldown(  
    .d_in(shoot_cooldown_display),
    .seg_out(hex1)
);

wire [3:0] map_display = {2'b00, map_type, enable_obstacles};
seg seg_map_status(      
    .d_in(map_display),
    .seg_out(hex0)
);

endmodule