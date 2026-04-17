module Synthesizer(
    input           CLOCK_50,
    input  [3:0]    KEY,
    input  [17:0]   SW,
    
    input           AUD_ADCDAT,
    inout           AUD_ADCLRCK,
    inout           AUD_BCLK,
    output          AUD_DACDAT,
    inout           AUD_DACLRCK,
    output          AUD_XCK,
    
    output          I2C_SCLK,
    inout           I2C_SDAT,
    
    input           p1_bullet_hit,      
    input           p1_tank_move,       
    input           p1_shoot_sound,     
    input           p2_bullet_hit,        
    input           p2_tank_move,       
    input           p2_shoot_sound      
);

wire            I2C_END;
wire            AUD_CTRL_CLK;
wire    [15:0]  sound1;  // 左声道 - 玩家1
wire    [15:0]  sound2;  // 右声道 - 玩家2

I2C_AV_Config u_i2c_config(
    .iCLK       (CLOCK_50),
    .iRST_N     (KEY[0]),
    .o_I2C_END  (I2C_END),
    .I2C_SCLK   (I2C_SCLK),
    .I2C_SDAT   (I2C_SDAT)	
);

VGA_Audio_PLL u_audio_pll(	
    .areset     (~I2C_END),
    .inclk0     (CLOCK_50),      
    .c1         (AUD_CTRL_CLK)	
);

assign AUD_ADCLRCK = AUD_DACLRCK; 
assign AUD_XCK     = AUD_CTRL_CLK;

tone_generator u_tone_gen(
    .clk(CLOCK_50),
    .rst_n(KEY[0]),
    .sw_control(SW[17]),
    .p1_bullet_hit(p1_bullet_hit),
    .p1_tank_move(p1_tank_move), 
    .p1_shoot_sound(p1_shoot_sound),
    .p2_bullet_hit(p2_bullet_hit),
    .p2_tank_move(p2_tank_move),
    .p2_shoot_sound(p2_shoot_sound),
    .left_channel(sound1),  // 左声道 - 玩家1
    .right_channel(sound2)  // 右声道 - 玩家2
);

adio_codec u_audio_codec(
    .oAUD_BCK       (AUD_BCLK),
    .oAUD_DATA      (AUD_DACDAT),
    .oAUD_LRCK      (AUD_DACLRCK),
    .iCLK_18_4      (AUD_CTRL_CLK),
    
    .key1_on        (SW[17] && (p1_bullet_hit || p1_tank_move || p1_shoot_sound)), // 左声道
    .key2_on        (SW[17] && (p2_bullet_hit || p2_tank_move || p2_shoot_sound)), // 右声道
    .key3_on        (1'b0),
    .key4_on        (1'b0),
    
    .iRST_N         (KEY[0]),
    .iSrc_Select    (2'b00),
    
    .sound1         (sound1),  
    .sound2         (sound2),  
    .sound3         (16'h0000),
    .sound4         (16'h0000),
    
    .instru         (1'b0)
);
endmodule