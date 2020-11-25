----------------------------------------------------------------------------------
--
-- Module Name: Lab5_TB - Lab5_ARCH_TB
--
-- Despription: This test bench serves the purpose of seeing signal updates of
-- the design for our mini baseball game. The btnU signal load the pitch, btnL
-- send the pitch for led shifting from led(15) to led(0), and btnL hits the ball
-- at led(0) sending the led shifting back left. Hits and misses are accounted for
-- as well.
--
-- Designer: Landon Brown
--
----------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;

entity Lab5_TB is
end Lab5_TB;

architecture Lab5_ARCH_TB of Lab5_TB is

constant ACTIVE: std_logic := '1';

component Lab5
    port(
        clk: in   std_logic;
        btnL :in std_logic;
        btnR: in std_logic;
        btnD: in std_logic; --maybe reset game
        btnU: in std_logic; -- load pitch or led
        led: out std_logic_vector(15 downto 0);
        sw: in std_logic_vector(3 downto 0); --only 4 pitching speeds
        seg: out std_logic_vector(6 downto 0);
        an: out std_logic_vector(3 downto 0)
    );
end component;

signal clk : std_logic; --:= '1';
signal btnL : std_logic; --:= '0';
signal btnR : std_logic; --:= '0';
signal btnD : std_logic; --:= '0';
signal btnU : std_logic; --:= '0';
signal led : std_logic_vector(15 downto 0);
signal sw : std_logic_vector(3 downto 0);
signal seg : std_logic_vector(6 downto 0);
signal an : std_logic_vector(3 downto 0);

begin

    --unit under test
    UUT: Lab5 port map (
        clk => clk,
        btnL => btnL,
        btnR => btnR,
        btnD => btnD,
        btnU => btnU,
        led => led,
        sw => sw,
        seg => seg,
        an => an
    );

    --clock
    CLOCK: process
    begin
        clk <= '0';
        wait for 5 ns;
        clk <= '1';
        wait for 5 ns;
    end process;

    --reset
    RESET: process
    begin
        btnD <= '1';
        wait for 40 ns;
        btnD <= '0';
        wait;
    end process;

    --generate waveform
    WAVEFORM: process
    begin
        btnL <= not ACTIVE;
        btnR <= not ACTIVE;
        btnU <= not ACTIVE;
        sw <= "0000";
        wait for 65 ns;

        sw <= "1000";
        wait for 45 ns;

        for i in 0 to 16 loop
            btnR <= not ACTIVE;
            btnL <= not ACTIVE;
            btnU <= ACTIVE;
            wait for 15 ns;
        end loop;

        for i in 0 to 16 loop
            btnU <= not ACTIVE;
            btnR <= not ACTIVE;
            btnL <= ACTIVE;
            wait for 30 ns;
        end loop;

        btnL <= not ACTIVE;
        wait for 7000 ns; -- when led makes it to led(0)

        for i in 0 to 16 loop
            btnU <= not ACTIVE;
            btnR <= ACTIVE;
            btnL <= not ACTIVE;
            wait for 30 ns;

            btnR <= not ACTIVE;
        end loop;
        wait;
    end process;

end Lab5_ARCH_TB;
