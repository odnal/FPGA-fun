----------------------------------------------------------------------------------------
--
-- Module Name: Lab5 - BatterUp
--
--  Description: This program takes the view of a simple baseball game.
--  To begin, simply press the UP button to indicate the pitcher is ready to
--  throw the ball. Then press the LEFT button to throw the ball and the lit led will
--  go all the way down to the last led. When it is on its last led, try to hit it
--  at the exact moment with the RIGHT button. Failure to do so will result in an
--  increment in count on the left seven segment display. Upon succeeding in hitting the
--  led will result in an increment in count on the right seven segment display and
--  the led will move to the left. Hitting to early will also result in as a miss.
--
-- Designer: Landon Brown
--
-----------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity Lab5 is
  port (
    clk: in   std_logic;
    btnL :in std_logic;
    btnR: in std_logic;
    btnD: in std_logic;
    btnU: in std_logic;
    led: out std_logic_vector(15 downto 0);
    sw: in std_logic_vector(3 downto 0);
    seg: out std_logic_vector(6 downto 0);
    an: out std_logic_vector(3 downto 0)
  ) ;
end Lab5 ;

architecture Lab5_ARCH of Lab5 is

    ---------------------------------------------------------CONSTANTS
    -- constant speeds for switches
    constant LED_SPEED : integer := 100_000_000;
    constant LED_SPEED1: integer := 10_000_000;
    constant LED_SPEED2: integer := 30_000_000;
    constant LED_SPEED3: integer := 5_000_000;

    constant ACTIVE : std_logic := '1';
    constant LED_ZERO : std_logic_vector(15 downto 0) := X"0000";

    ---------------------------------------------------------SIGNALS
    signal reset : std_logic; --btnD
    signal pitch : std_logic; -- btnL
    signal loadPitch : std_logic; --btnU
    signal batter : std_logic; -- btnR
    signal enableSpeed : std_logic; --speed of led
    signal shiftRight : std_logic;
    signal shiftLeft : std_logic;
    signal missCountEnable : std_logic;
    signal hitCountEnable : std_logic;
    signal hitCountBcd : std_logic_vector(7 downto 0);
    signal missCountBcd : std_logic_vector(7 downto 0);
    signal hitCount : integer range 0 to 99;
    signal missCount : integer range 0 to 99;
    signal ledControl: std_logic_vector(15 downto 0) := X"0000";
    signal START_LEFT_LED: std_logic_vector(15 downto 0) :=  X"8000";

    ----state-machine-declarations--------------------------------------------SIGNALS
    type States_t is (LOAD_BALL, WAITING, WAIT_FOR_PITCH, PITCHING, HOME, HIT, MISS);
    signal currentState: States_t;
    signal nextState: States_t;

    --count 0 -> 99 procedure
    procedure count_to_99( signal reset: in std_logic;
        signal clock: in std_logic;
        signal countEnable: in std_logic;
        signal count: inout integer) is
    begin
        if (reset=ACTIVE) then
            count <= 0;
        elsif (rising_edge(clock)) then
            if (countEnable=ACTIVE) then
                if (count>=0 and count<99) then
                    count <= count + 1;
                else
                    count <= 99;
                end if;
            end if;
        end if;
    end count_to_99;

    --count to bcd conversion
    function to_bcd_8bit( inputValue: integer) return std_logic_vector is
        variable tensValue: integer;
        variable onesValue: integer;
    begin
        if (inputValue < 99) then
            tensValue := inputValue / 10;
            onesValue := inputValue mod 10;
        else
            tensValue := 9;
            onesValue := 9;
        end if;
        return std_logic_vector(to_unsigned(tensValue, 4)) & std_logic_vector(to_unsigned(onesValue, 4));
    end to_bcd_8bit;

begin

    MY_SEGMENTS: entity work.SevenSegmentDriver port map (
        reset => reset,
        clock => clk,
        digit3 => missCountBcd(7 downto 4),
        digit2 => missCountBcd(3 downto 0),
        digit1 => hitCountBcd(7 downto 4),
        digit0 => hitCountBcd(3 downto 0),
        blank3 => not ACTIVE,--s_Blank3,
        blank2 => not ACTIVE,--s_Blank2,
        blank1 => not ACTIVE, --s_Blank1,
        blank0 => not ACTIVE ,--s_Blank0,
        sevenSegs => seg,
        anodes => an
    );

    -- btnR(batter) for hitting the led
    SYNC_BATTER_BUTTON: process(reset, clk)
    begin
        if(reset = ACTIVE) then
            batter <= not ACTIVE;
        elsif(rising_edge(clk)) then
            batter <= btnR;
        end if;
    end process;

    -- btnL(pitch) for pitching the led
    SYNC_PITCH_BUTTON: process(reset, clk)
    begin
        if(reset = ACTIVE) then
            pitch <= not ACTIVE;
        elsif(rising_edge(clk)) then
            pitch <= btnL;
        end if;
    end process;

    -- btnU(loadPitch) for loading the pitch
    SYNC_LOAD_BUTTON: process(reset, clk)
    begin
        if(reset = ACTIVE) then
            loadPitch <= not ACTIVE;
        elsif(rising_edge(clk)) then
            loadPitch <= btnU;
        end if;
    end process;

    -- speed control for how fast the leds go left to right and vice versa
    SPEED_PROCESS: process(reset, clk)
        variable countspeed: integer range 0 to LED_SPEED;
        variable countspeed1: integer range 0 to LED_SPEED1;
        variable countspeed2: integer range 0 to LED_SPEED2;
        variable countspeed3: integer range 0 to LED_SPEED3;
        variable count: integer range 0 to 3;
        begin
    --manage-count-value--------------------------------------------
            if (reset = ACTIVE) then
                countspeed := 0;
                countspeed1 := 0;
                countspeed2 := 0;
                countspeed3 := 0;
                count := 0;
            elsif (rising_edge(clk)) then
                if (countspeed = LED_SPEED) then
                    countspeed := 0;
                    countspeed1 := 0;
                    countspeed2 := 0;
                    countspeed3 := 0;
                    count := 0;
                else
                    countspeed := countspeed + 1;
                    countspeed1 := countspeed1 + 1;
                    countspeed2 := countspeed2 + 1;
                    countspeed3 := countspeed3 + 1;
                    count := count + 1;
                end if;
            end if;

            --update-enable-signal-------------------------------------------
            enableSpeed <= not ACTIVE;  --default value unless count reaches terminal

                if(sw(0) = ACTIVE and countspeed = LED_SPEED) then
                    enableSpeed <= ACTIVE;
                elsif(sw(1) = ACTIVE and countspeed1 = LED_SPEED1) then
                    enableSpeed <= ACTIVE;
                elsif(sw(2) = ACTIVE and countspeed2 = LED_SPEED2) then
                    enableSpeed <= ACTIVE;
                elsif(sw(3) = ACTIVE and countspeed3 = LED_SPEED3) then
                    enableSpeed <= ACTIVE;
                else
                    enableSpeed <= not ACTIVE;
                end if;
        end process;

    -- state machine for control of the game
    STATE_REG: process(reset, clk)
        begin
            if(reset = ACTIVE) then
                currentState <= LOAD_BALL;
            elsif(rising_edge(clk)) then
                currentState <= nextState;
            end if;
    end process;

    STATE_TRANS: process(currentState, pitch, batter, ledControl(0), ledControl(15), ledControl(14 downto 1))
    begin
        shiftRight <= not ACTIVE;
        shiftLeft <= not ACTIVE;
        hitCountEnable <= not ACTIVE;
        missCountEnable <= not ACTIVE;
        nextState <= currentState;
            case currentState is
                ---------------------------------------------LOAD_BALL
                when LOAD_BALL =>
                    if(loadPitch = ACTIVE) then
                        nextState <= WAITING;
                    end if;
                ---------------------------------------------WAITING
                when WAITING =>
                    if(ledControl(15) = ACTIVE) then
                        nextState <= WAIT_FOR_PITCH;
                    end if;
                ---------------------------------------------WAIT_FOR_PITCH
                when WAIT_FOR_PITCH =>
                    if(pitch = ACTIVE) then
                        nextState <= PITCHING;
                    end if;
                ---------------------------------------------PITCHING
                when PITCHING =>
                    shiftRight <= ACTIVE;
                    if(batter = ACTIVE) then
                        missCountEnable <= ACTIVE;
                        nextState <= MISS; --LOAD_BALL
                    elsif(ledControl(0) = ACTIVE) then
                        nextState <= HOME;
                    end if;
                --------------------------------------------HOME
                when HOME =>
                shiftRight <= ACTIVE;
                if(batter = ACTIVE) then
                    nextState <= HIT;
                    hitCountEnable <= ACTIVE;
                elsif(ledControl = LED_ZERO) then
                    missCountEnable <= ACTIVE;
                    nextState <= LOAD_BAlL;
                end if;
                --------------------------------------------HIT
                when HIT =>
                    shiftLeft <= ACTIVE;
                    if(ledControl(15) = ACTIVE) then
                        nextState <= LOAD_BALL;
                    else
                        shiftLeft <= ACTIVE;
                    end if;
                --------------------------------------------MISS
                when MISS =>
                    shiftRight <= ACTIVE;
                    if(ledControl = LED_ZERO) then
                        nextState <= LOAD_BALL;
                    end if;
            end case;
    end process;

    -- led shift left or shift right ##maybe make count to shift across##
    BALL_DRIVER: process(reset, clk)
    begin
        if(reset = ACTIVE) then
            ledControl <= LED_ZERO;
        elsif(rising_edge(clk)) then
            if(loadPitch = ACTIVE) then
                ledControl <= START_LEFT_LED;
            elsif(enableSpeed = ACTIVE) then
                if(shiftRight = ACTIVE) then
                    ledControl(15 downto 0) <= '0' & ledControl(15 downto 1);
                elsif(shiftLeft = ACTIVE) then
                    ledControl(15 downto 0) <= ledControl(14 downto 0) & '0';
                end if;
            end if;
        end if;

          led <= ledControl;
    end process;

    HIT_COUNT: count_to_99(
        reset => reset,
        clock => clk,
        countEnable => hitCountEnable,
        count => hitCount
    );

    MISS_COUNT: count_to_99(
        reset => reset,
        clock => clk,
        countEnable => missCountEnable,
        count => missCount
    );

    hitCountBcd <= to_bcd_8bit(hitCount);
    missCountBcd <= to_bcd_8bit(missCount);
    --led <= ledControl;
    reset <= btnD;
end Lab5_ARCH;
