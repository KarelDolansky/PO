library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.video_package.all;

entity top is
    port(
        clk                          : in  std_logic;
        rstn                         : in  std_logic;
        SW                           : in  std_logic_vector(15 downto 0);
        LED                          : out std_logic_vector(15 downto 0);
        segments                     : out std_logic_vector(7 downto 0);
        displays                     : out std_logic_vector(7 downto 0);
        LED_RGB                      : out std_logic_vector(5 downto 0);
        btnc, btnu, btnl, btnr, btnd : in  std_logic;
        VGA_R, VGA_G, VGA_B          : out std_logic_vector(3 downto 0);
        VGA_HS, VGA_VS               : out std_logic;
        audio_PWM, audio_SD          : out std_logic
    );
end top;

architecture Behavioral of top is

    component clock_generator
        port(                           -- Clock in ports
                                        -- Clock out ports
            video_clk : out std_logic;
            -- Status and control signals
            resetn    : in  std_logic;
            locked    : out std_logic;
            clk_in1   : in  std_logic
        );
    end component;

    -- video constants and types
    constant C_TIMING             : video_timing_t := TIMING_768p;
    constant VIDEO_COUNTERS_WIDTH : integer        := video_get_counters_width(C_TIMING);

    -- will hold sprite and player positions
    type position_t is record
        X : unsigned(VIDEO_COUNTERS_WIDTH - 1 downto 0);
        Y : unsigned(VIDEO_COUNTERS_WIDTH - 1 downto 0);
    end record;

    -- player/sprite speeds
    type speed_t is record
        X : signed(2 downto 0);
        Y : signed(2 downto 0);
    end record;

    -- sprite types/constants related
    constant C_NUM_SPRITES : integer := 64;
    -- sprite RGB, position, speed data buses/registers
    type colors_t is array (C_NUM_SPRITES - 1 downto 0) of color_t;
    type positions_t is array (C_NUM_SPRITES - 1 downto 0) of position_t;
    type speeds_t is array (C_NUM_SPRITES - 1 downto 0) of speed_t;

    -- sprite definitisons
    constant S_PLAYER : sprite_t := (
        ROM_FILE    => "C:\Users\baron\skola\data\5_semestr\PO\lab08\python\video\player.mem",
        WIDTH       => 64,
        HEIGHT      => 4,
        FRAMES      => 1,
        TRANSPARENT => COLOR_TRANSPARENT
    );

    constant S_BALL : sprite_t := (
        ROM_FILE    => "C:\Users\baron\skola\data\5_semestr\PO\lab08\python\video\ball.mem",
        WIDTH       => 16,
        HEIGHT      => 16,
        FRAMES      => 4,
        TRANSPARENT => COLOR_TRANSPARENT
    );
    constant S_BULLET : sprite_t := (
        ROM_FILE    => "C:\Users\baron\skola\data\5_semestr\PO\lab08\python\video\anim.mem",
        WIDTH       => 32,
        HEIGHT      => 32,
        FRAMES      => 8,
        TRANSPARENT => COLOR_TRANSPARENT
    );

    /*
        compile time random number generator for initial sprite positions
    */
    function generate_initial_positions(timing : video_timing_t) return positions_t is
        variable retval       : positions_t;
    begin
        for i in 0 to C_NUM_SPRITES/8 - 1 loop
            for j in 0 to 7 loop
                retval(i*8+j).X := to_unsigned(i * (timing.H_ACTIVE / (C_NUM_SPRITES/8)) + i, retval(i*8+j).X'length);
                retval(i*8+j).Y := to_unsigned(j * (S_BULLET.HEIGHT) + j, retval(i*8+j).Y'length);
            end loop;
        end loop;
        return retval;
    end function;

    /*
        compile time random number generator for initial sprite speeds
    */
    function generate_initial_speeds return speeds_t is
        variable retval       : speeds_t;
    begin
        for i in 0 to C_NUM_SPRITES - 1 loop
            retval(i).X := to_signed(0, retval(i).X'length);
            retval(i).Y := to_signed(0, retval(i).Y'length);
        end loop;
        return retval;
    end function;
    function generate_initial_speed return speed_t is
        variable retval       : speed_t;
        variable seed1, seed2 : positive;
        variable rand         : real;
        variable speed        : integer := 0;
    begin
        seed1 := 1234;
        seed2 := 5678;
        speed := integer(round(2 * (rand - 0.5) * 3));
        retval.X := to_signed(speed, retval.X'length);
        speed := integer(round(2 * (rand - 0.5) * 3));
        retval.Y := to_signed(speed, retval.Y'length);
        return retval;
    end function;

    -- random start speed and positions for sprites
    constant sprite_positions_init : positions_t := generate_initial_positions(C_TIMING);
    constant sprite_speeds_init    : speeds_t    := generate_initial_speeds;
    constant ball_speed_init       : speed_t     := generate_initial_speed;

    -- timeout counters
    type timeout_t is array (3 downto 0) of unsigned(3 downto 0);
    type timeouts_t is array (3 downto 0) of timeout_t;
    constant time_min             : timeout_t  := (others => (others => '0'));
    constant timeout_easy         : timeout_t  := (X"2", X"0", X"0", X"0");
    constant timeout_medium       : timeout_t  := (X"1", X"3", X"0", X"0");
    constant timeout_hard         : timeout_t  := (X"1", X"0", X"0", X"0");
    constant timeout_insane       : timeout_t  := (X"0", X"3", X"0", X"0");
    constant time_max             : timeout_t  := (X"9", X"5", X"9", X"9");
    constant timeout_difficulties : timeouts_t := (timeout_insane, timeout_hard, timeout_medium, timeout_easy);

    -- generator signals
    signal video_clk  : std_logic;
    signal locked     : std_logic;
    signal active     : std_logic;
    signal hsync      : std_logic;
    signal vsync      : std_logic;
    signal video_pos  : position_t;
    signal frame      : unsigned(FRAME_CNT_WIDTH - 1 downto 0);
    signal active_end : std_logic;
    signal frame_end  : std_logic;

    -- background signals
    signal bckg_sel      : std_logic_vector(1 downto 0) := (others => '0');
    signal backgroud_RGB : color_t;
    signal bckg_VGA_HS   : std_logic;
    signal bckg_VGA_VS   : std_logic;

    -- player signals
    signal player_pos         : position_t;
    signal player_speed       : speed_t;
    signal player_RGB         : color_t;
    signal player_transparent : std_logic;
    signal player_active      : std_logic;

    -- ball signals
    signal ball_pos         : position_t;
    signal ball_speed       : speed_t;
    signal ball_RGB         : color_t;
    signal ball_transparent : std_logic;
    signal ball_active      : std_logic;

    -- sprite signals
    signal sprite_RGB_s         : colors_t;
    signal sprite_transparent_s : std_logic_vector(C_NUM_SPRITES - 1 downto 0);
    signal sprite_positions     : positions_t;
    signal sprite_speeds        : speeds_t;
    signal sprite_active        : std_logic_vector(C_NUM_SPRITES - 1 downto 0) := (others => '1');

    -- 7segment display
    signal timeout_done     : std_logic;
    signal ss_display_value : std_logic_vector(31 downto 0);
    signal timeout          : timeout_t;

    -- Game control state machine
    type state_t is (SIdle,  SControls, SPlayerBounce, SPlayerPosition, SPlayerColision, SGameState,SBallBounce,SBallPosition,BPlayerColision);
    signal state       : state_t := SIdle;
    signal win_counter : unsigned(log2i(C_NUM_SPRITES + 1) - 1 downto 0);
    signal play_hit    : std_logic;
    signal play_tick   : std_logic;
    signal play_tock   : std_logic;
    signal PWM         : std_logic;

begin

    clock_generator_inst : component clock_generator
        port map(
            video_clk => video_clk,
            resetn    => rstn,
            locked    => locked,
            clk_in1   => clk
        );

    -- video generator generates position, synchronizations, positions, etc.
    video_generator_inst : entity work.video_generator
        generic map(
            C_TIMING => C_TIMING
        )
        port map(
            clk        => video_clk,
            rst        => not locked,
            active     => active,
            hsync      => hsync,
            vsync      => vsync,
            pos_x      => video_pos.X,
            pos_y      => video_pos.Y,
            frame      => frame,
            active_end => active_end,
            frame_end  => frame_end
        );

    -- background generator
    pattern_generator_inst : entity work.pattern_generator
        generic map(
            C_TIMING => C_TIMING
        )
        port map(
            clk        => video_clk,
            rst        => not locked,
            active     => active,
            hsync      => hsync,
            vsync      => vsync,
            pos_x      => video_pos.X,
            pos_y      => video_pos.Y,
            active_end => active_end,
            frame_end  => frame_end,
            bckg_color => vec2color(SW(11 downto 0)),
            bckg_sel   => bckg_sel,
            VGA_RGB    => backgroud_RGB,
            VGA_HS     => bckg_VGA_HS,
            VGA_VS     => bckg_VGA_VS
        );

    -- sprites reads from sprite rom and displays self on required position
    sprites : for i in C_NUM_SPRITES - 1 downto 0 generate
        sprite_inst : entity work.sprite
            generic map(
                C_TIMING => C_TIMING,
                C_SPRITE => S_BULLET
            )
            port map(
                clk          => video_clk,
                rst          => not locked,
                video_pos_x  => video_pos.X,
                video_pos_y  => video_pos.Y,
                video_frame  => frame,
                active       => active,
                sprite_pos_x => sprite_positions(i).X,
                sprite_pos_y => sprite_positions(i).Y,
                RGB          => sprite_RGB_s(i),
                transparent  => sprite_transparent_s(i)
            );
    end generate;

    -- player is just another sprite
    player : entity work.sprite
        generic map(
            C_TIMING => C_TIMING,
            C_SPRITE => S_PLAYER
        )
        port map(
            clk          => video_clk,
            rst          => not locked,
            video_pos_x  => video_pos.X,
            video_pos_y  => video_pos.Y,
            video_frame  => frame,
            active       => active,
            sprite_pos_x => player_pos.X,
            sprite_pos_y => player_pos.Y,
            RGB          => player_RGB,
            transparent  => player_transparent
        );

        ball : entity work.sprite
        generic map(
            C_TIMING => C_TIMING,
            C_SPRITE => S_BALL
        )
        port map(
            clk          => video_clk,
            rst          => not locked,
            video_pos_x  => video_pos.X,
            video_pos_y  => video_pos.Y,
            video_frame  => frame,
            active       => active,
            sprite_pos_x => ball_pos.X,
            sprite_pos_y => ball_pos.Y,
            RGB          => ball_RGB,
            transparent  => ball_transparent
        );

    -- video mix mixes backgroun, sprites and player to single RGB value.
    mix : process(video_clk)
    begin
        if rising_edge(video_clk) then
            VGA_HS                <= bckg_VGA_HS;
            VGA_VS                <= bckg_VGA_VS;
            -- mixint is done with priority given by following order
            -- show background
            (VGA_R, VGA_G, VGA_B) <= color2vec(backgroud_RGB);
            -- sprites are over (in order of idx)
            for i in 0 to C_NUM_SPRITES - 1 loop
                if not (sprite_transparent_s(i)) and sprite_active(i) then
                    (VGA_R, VGA_G, VGA_B) <= color2vec(sprite_RGB_s(i));
                end if;
            end loop;
            -- on top of that is player
            if not player_transparent and player_active then
                (VGA_R, VGA_G, VGA_B) <= color2vec(player_RGB);
            end if;

            if not ball_transparent and ball_active then
                (VGA_R, VGA_G, VGA_B) <= color2vec(ball_RGB);
            end if;

        end if;
    end process;

    /*
        game control state machine
        at every active video end sprite and player movement is computed
        if there is some time remaining collisions between player and sprites are computed
        if there are no sprites before timeout player wins
        if the time runs out sprites win
        timer is parallel to the state machine (see bellow)        
     */
    fsm : process(video_clk) is
        variable sprite_counter                   : unsigned(log2i(C_NUM_SPRITES + 1) - 1 downto 0);
        variable sidx                             : integer range 0 to C_NUM_SPRITES + 1;
        type position_X_t is record
            X : signed(VIDEO_COUNTERS_WIDTH downto 0);
            Y : signed(VIDEO_COUNTERS_WIDTH downto 0);
        end record;
        variable sprite_next_pos, player_next_pos, ball_next_pos : position_X_t;
        variable pl, sl, pr, sr, bl, br                   : position_t;
        variable lose                                     : std_logic;
    begin
        if rising_edge(video_clk) then
            if not locked then
                ball_speed       <= ball_speed_init;
                ball_pos       <= (X => to_unsigned(C_TIMING.H_ACTIVE/2, ball_pos.X'length), Y => to_unsigned(C_TIMING.V_ACTIVE-90, ball_pos.Y'length));
                sprite_speeds    <= sprite_speeds_init;
                sprite_positions <= sprite_positions_init;
                sprite_active    <= (others => '1');
                win_counter      <= (others => '0');
                player_pos       <= (X => to_unsigned(C_TIMING.H_ACTIVE/2, player_pos.X'length), Y => to_unsigned(C_TIMING.V_ACTIVE-45, player_pos.Y'length));
                player_speed     <= (X => (others => '0'), Y => (others => '0'));
                player_active    <= '1';
                ball_active      <= '1';
                bckg_sel         <= "11";
            else
                play_hit       <= '0';
                case state is                    
                    when SIdle =>                        
                        -- wait until active end
                        sprite_counter := (others => '0');
                        if active_end then
                            if timeout_done then
                                -- end of game
                                state <= SGameState;
                            else
                                -- game loop
                                state <= SBallBounce;
                            end if;
                        end if;
                    -- when SSpriteBouncing =>
                    --     -- sprite wall bouncing
                    --     sidx              := to_integer(sprite_counter);
                    --     sprite_next_pos.X := signed(resize(sprite_positions(sidx).X, sprite_next_pos.X'length)) + sprite_speeds(sidx).X;
                    --     sprite_next_pos.Y := signed(resize(sprite_positions(sidx).Y, sprite_next_pos.Y'length)) + sprite_speeds(sidx).Y;
                    --     -- left and right wall hit changes X speed direction
                    --     if (sprite_next_pos.X < 0) or (sprite_next_pos.X + S_BULLET.WIDTH >= C_TIMING.H_ACTIVE) then
                    --         sprite_speeds(sidx).X <= -sprite_speeds(sidx).X;
                    --     end if;
                    --     -- top and bottom wall hit changes Y speed direction
                    --     if (sprite_next_pos.Y < 0) or (sprite_next_pos.Y + S_BULLET.HEIGHT >= C_TIMING.V_ACTIVE) then
                    --         sprite_speeds(sidx).Y <= -sprite_speeds(sidx).Y;
                    --     end if;
                    --     -- next bullet
                    --     sprite_counter    := sprite_counter + 1;
                    --     if sprite_counter >= C_NUM_SPRITES then
                    --         -- compute next bullet position
                    --         state          <= SSpritePositions;
                    --         sprite_counter := (others => '0');
                    --     end if;
                    -- when SSpritePositions =>
                    --     -- sprite movement. Adds speed to current postion
                    --     sidx                     := to_integer(sprite_counter);
                    --     sprite_positions(sidx).X <= unsigned(signed(sprite_positions(sidx).X) + sprite_speeds(sidx).X);
                    --     sprite_positions(sidx).Y <= unsigned(signed(sprite_positions(sidx).Y) + sprite_speeds(sidx).Y);
                    --     -- loop trough all sprites
                    --     sprite_counter           := sprite_counter + 1;
                    --     if sprite_counter >= C_NUM_SPRITES then
                    --         if timeout_done then
                    --             -- do not compute collisions when timeout done
                    --             state <= SGameState;
                    --         else
                    --             state <= SBallBounce;
                    --         end if;
                    --         sprite_counter := (others => '0');
                    --     end if;
                    when SBallBounce =>
                        ball_next_pos.X := signed(resize(ball_pos.X, ball_next_pos.X'length)) + ball_speed.X;
                        ball_next_pos.Y := signed(resize(ball_pos.Y, ball_next_pos.Y'length)) + ball_speed.Y;                        
                        -- left and right wall hit changes X speed direction
                        if (ball_next_pos.X < 0) or (ball_next_pos.X + S_BULLET.WIDTH >= C_TIMING.H_ACTIVE) then
                            ball_speed.X <= -ball_speed.X;
                        end if;
                        -- top and bottom wall hit changes Y speed direction
                        if (ball_next_pos.Y < 0)  then
                            ball_speed.Y <= -ball_speed.Y;
                        elsif (ball_next_pos.Y + S_BULLET.HEIGHT >= C_TIMING.V_ACTIVE) then
                            lose := '1';
                        end if;

                        if lose then
                            -- do not compute collisions when timeout done
                            state <= SGameState;
                        else
                            state<= SBallPosition;
                        end if;
                        
                    when SBallPosition =>
                        -- sprite movement. Adds speed to current postion
                        ball_pos.X <= unsigned(signed(ball_pos.X) + ball_speed.X);
                        ball_pos.Y <= unsigned(signed(ball_pos.Y) + ball_speed.Y);
                        -- loop trough all sprites
                        if timeout_done then
                            -- do not compute collisions when timeout done
                            state <= SGameState;
                        else
                            state <= SControls;
                        end if;
                    when SControls =>
                        -- user controls updates player speed (not position!)
                        if frame(1 downto 0) = 0 then
                            if btnl then
                                if player_speed.X > -3 then
                                    player_speed.X <= player_speed.X - 1;
                                end if;
                            elsif btnr then
                                if player_speed.X < 3 then
                                    player_speed.X <= player_speed.X + 1;
                                end if;
                            else
                                player_speed.X <= (others => '0');
                            end if;
                        end if;
                        state <= SPlayerBounce;
                    when SPlayerBounce =>
                        -- player wall bouncing is the same as sprite bouncing
                        player_next_pos.X := signed(resize(player_pos.X, player_next_pos.X'length)) + player_speed.X;
                        player_next_pos.Y := signed(resize(player_pos.Y, player_next_pos.Y'length)) + player_speed.Y;
                        if (player_next_pos.X < 0) or (player_next_pos.X + S_PLAYER.WIDTH >= C_TIMING.H_ACTIVE) then
                            player_speed.X <= (others => '0');
                        end if;
                        if (player_next_pos.Y < 0) or (player_next_pos.Y + S_PLAYER.HEIGHT >= C_TIMING.V_ACTIVE) then
                            player_speed.Y <= (others => '0');
                        end if;
                        state             <= SPlayerPosition;
                    when SPlayerPosition =>
                        -- player position update
                        player_pos.X   <= unsigned(signed(player_pos.X) + player_speed.X);
                        player_pos.Y   <= unsigned(signed(player_pos.Y) + player_speed.Y);
                        state          <= SPlayerColision;
                        sprite_counter := (others => '0');
                    when SPlayerColision =>
                        -- colision between player and sprites. pl == player left top corner, sr = sprite right bottom corner
                        sidx := to_integer(sprite_counter);
                        bl.X := ball_pos.X;
                        br.X := ball_pos.X + S_BALL.WIDTH - 1;
                        -- pl.X := player_pos.X;
                        -- pr.X := player_pos.X + S_PLAYER.WIDTH - 1;
                        sl.X := sprite_positions(sidx).X;
                        sr.X := sprite_positions(sidx).X + S_BULLET.WIDTH - 1;
                        bl.Y := ball_pos.Y + S_BALL.HEIGHT - 1;
                        br.Y := ball_pos.Y;
                        -- pl.Y := player_pos.Y + S_PLAYER.HEIGHT - 1;
                        -- pr.Y := player_pos.Y;
                        sl.Y := sprite_positions(sidx).Y + S_BULLET.HEIGHT - 1;
                        sr.Y := sprite_positions(sidx).Y;
                        if sprite_active(sidx) then
                            -- only sprites not hit before are counted
                            -- rectangle intersection
                            if (bl.X <= sr.x) and (br.X >= sl.X) and (bl.Y >= sr.Y) and (br.Y <= sl.Y) then
                                if (bl.X <= sr.x) and (br.X >= sl.X) then
                                    ball_speed.X <= -ball_speed.X;
                                end if;
                                if (bl.Y >= sr.Y) and (br.Y <= sl.Y) then
                                    ball_speed.Y <= -ball_speed.Y;
                                end if;
                                -- turn of sprite visibility (and intersection in next cycle)
                                sprite_active(sidx) <= '0';
                                -- update win counter
                                win_counter         <= win_counter + 1;
                                play_hit            <= '1';
                            end if;
                        end if;
                        sprite_counter := sprite_counter + 1;
                        -- loop trough all sprites
                        if sprite_counter >= C_NUM_SPRITES then
                            sprite_counter := (others => '0');
                            state          <= BPlayerColision;
                        end if;
                    when BPlayerColision  => 

                        bl.X := ball_pos.X;
                        br.X := ball_pos.X + S_BALL.WIDTH - 1;
                        pl.X := player_pos.X;
                        pr.X := player_pos.X + S_PLAYER.WIDTH - 1;
                        bl.Y := ball_pos.Y + S_BALL.HEIGHT - 1;
                        br.Y := ball_pos.Y;
                        pl.Y := player_pos.Y + S_PLAYER.HEIGHT - 1;
                        pr.Y := player_pos.Y;
                        if (bl.X <= pr.X) and (br.X >= pl.X) and (bl.Y >= pr.Y) and (br.Y <= pl.Y) then
                            if (bl.X <= pr.X) and (br.X >= pl.X) then
                                ball_speed.X <= -ball_speed.X;
                            end if;
                            if (bl.Y >= pr.Y) and (br.Y <= pl.Y) then
                                ball_speed.Y <= -ball_speed.Y;
                            end if;
                        end if;
                        state          <= SGameState;
                    when SGameState =>
                        if win_counter >= C_NUM_SPRITES then
                            -- if player wins do some terrible blinking
                            bckg_sel <= std_logic_vector(unsigned(bckg_sel) + 1);
                        end if;
                        if lose then
                            -- if sprites win do some terrible blinking
                            --bckg_sel      <= std_logic_vector(unsigned(bckg_sel) + 1);
                            -- hide player 
                            player_active <= '0';
                            ball_active  <=  '0';
                        end if;
                        state <= SIdle;
                end case;
            end if;
        end if;
    end process fsm;

    dd_inst : entity work.display_driver
        port map(
            clk      => video_clk,
            rst      => not locked,
            din      => ss_display_value,
            segments => segments,
            displays => displays
        );

    time_gen : for d_idx in timeout'range generate
        ss_display_value((d_idx + 1) * 4 - 1 downto d_idx * 4) <= std_logic_vector(timeout(d_idx));
    end generate;
    -- # of remaining sprites
    ss_display_value(8 * 4 - 1 downto 6 * 4) <= std_logic_vector(resize(to_unsigned(C_NUM_SPRITES, win_counter'length) - win_counter, 8));

    -- difficulty timeout
    tout : process(video_clk) is
        variable cnt_ms : unsigned(log2i(C_TIMING.REQ_FREQ_HZ / 10) - 1 downto 0);
        variable carry  : std_logic;
    begin
        if rising_edge(video_clk) then
            if not locked then
                timeout      <= timeout_difficulties(to_integer(unsigned(SW(1 downto 0))));
                cnt_ms       := (others => '0');
                timeout_done <= '0';
                play_tick    <= '0';
                play_tock    <= '0';
            else
                play_tick <= '0';
                play_tock <= '0';
                if cnt_ms < (C_TIMING.REQ_FREQ_HZ / 10) then
                    cnt_ms := cnt_ms + 1;
                else
                    cnt_ms := (others => '0');
                    carry  := '1';
                        for c_idx in timeout'reverse_range loop
                            -- count only if all previous counted
                            if carry then

                                if c_idx = 1 then
                                    if timeout(c_idx)(0) then
                                        play_tick <= '1';
                                    else
                                        play_tock <= '1';
                                    end if;
                                end if;
                                
                                if timeout(c_idx) = X"0" then
                                    -- will count 0->9
                                    carry          := '1';
                                    timeout(c_idx) <= time_max(c_idx);
                                else
                                    carry          := '0';
                                    timeout(c_idx) <= timeout(c_idx) - 1;
                                end if;

                            end if;
                        end loop;
                end if;
            end if;
        end if;
    end process tout;

    audio_inst : entity work.audio
        generic map(
            C_SAMPLE_WIDTH => 8,
            C_CLK_FREQ     => C_TIMING.REQ_FREQ_HZ,
            C_SAMPLE_FREQ  => 8000
        )
        port map(
            clk       => video_clk,
            rst       => not locked,
            play_hit  => play_hit,
            play_tick => play_tick,
            play_tock => play_tock,
            PWM       => PWM
        );

    audio_PWM <= 'Z' when PWM else '0';
    audio_SD  <= '1';

end Behavioral;
