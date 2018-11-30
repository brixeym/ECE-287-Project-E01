--------------------------------------------------------------------------------
--
--   FileName:         hw_image_generator.vhd
--   Dependencies:     none
--   Design Software:  Quartus II 64-bit Version 12.1 Build 177 SJ Full Version
--
--   HDL CODE IS PROVIDED "AS IS."  DIGI-KEY EXPRESSLY DISCLAIMS ANY
--   WARRANTY OF ANY KIND, WHETHER EXPRESS OR IMPLIED, INCLUDING BUT NOT
--   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
--   PARTICULAR PURPOSE, OR NON-INFRINGEMENT. IN NO EVENT SHALL DIGI-KEY
--   BE LIABLE FOR ANY INCIDENTAL, SPECIAL, INDIRECT OR CONSEQUENTIAL
--   DAMAGES, LOST PROFITS OR LOST DATA, HARM TO YOUR EQUIPMENT, COST OF
--   PROCUREMENT OF SUBSTITUTE GOODS, TECHNOLOGY OR SERVICES, ANY CLAIMS
--   BY THIRD PARTIES (INCLUDING BUT NOT LIMITED TO ANY DEFENSE THEREOF),
--   ANY CLAIMS FOR INDEMNITY OR CONTRIBUTION, OR OTHER SIMILAR COSTS.
--
--   Version History
--   Version 1.0 05/10/2013 Scott Larson
--     Initial Public Release
--    
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

ENTITY hw_image_generator IS
	GENERIC(
		pixels_y :	INTEGER := 478;    --row that first color will persist until
		pixels_x	:	INTEGER := 600);   --column that first color will persist until
	PORT(
		clk_50MHz	: in std_logic;      --connected to vga clock
		pbRU, pbLD  : in std_logic;		--pushbutton right=up(lane1) and pushbutton left=down(lane3)
		reset			: in std_logic;      --game reset pushbutton
		disp_ena		:	IN		STD_LOGIC;	--display enable ('1' = display time, '0' = blanking time)
		row			:	IN		INTEGER;		--row pixel coordinate
		column		:	IN		INTEGER;		--column pixel coordinate
		red			:	OUT	STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');  --red magnitude output to DAC
		green			:	OUT	STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');  --green magnitude output to DAC
		blue			:	OUT	STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0')); --blue magnitude output to DAC
END hw_image_generator;

ARCHITECTURE behavior OF hw_image_generator IS

signal counter : std_logic_vector(22 downto 0); -- 23 bits
signal counter_lfsr, lfsr :std_logic_vector(26 downto 0); -- 27 bits
signal clk_lfsr, clk : std_logic;
signal feedback : std_logic;
signal x,obstacle1Exists, obstacle2Exists, obstacle3Exists : std_logic := '0';

-- column pixel signals
signal lane1Start : integer := 105;
signal lane1End : integer := 255;
signal lane2Start : integer := 465;
signal lane2End : integer := 615;
signal lane3Start : integer := 825;
signal lane3End : integer := 975;

-- row pixel signals
signal playerStart : integer := 0;
signal playerEnd : integer := 150;
signal obstacleStart : integer := 1770;
signal obstacleEnd : integer := 1920;

signal obstaclePosition1,obstaclePosition2,obstaclePosition3 : std_logic := '0';

BEGIN

	feedback <= not(lfsr(3) xor lfsr(2));

	sr : process (clk_50MHz) -- linear feedback shift register is pseudo-random number generator for obstacles
   begin
     if (clk_50MHz'event and clk_50MHz = '1') then -- rising clock edge
			if counter_lfsr < "101111101011110000100000000" then -- binary value is 100 million, 27 bits, slow frequency so that obstacles can generate slowly
				counter_lfsr <= counter_lfsr + 1;         
			elsif ((pbRU = '0' or pbLD = '0') and x = '0') then-- obstacles start when player moves either up or down for the first time
				x <= '1';
				lfsr <= counter_lfsr;
			elsif (reset = '0') then -- obstacles reset when button is pressed
				x <= '0';
				lfsr <= (others => '0');
			else            
				clk_lfsr <= not clk_lfsr;            
				counter_lfsr <= (others => '0');
				lfsr <= lfsr(25 downto 0) & feedback; --shifting to the left, feedback on the right (1 bit)
			end if; 
			if (lfsr(21) = '1') then
				obstacle1Exists <= '1';
			elsif (lfsr(22) = '1') then
				obstacle2Exists <= '1';
			elsif (lfsr(23) = '1') then
				obstacle3Exists <= '1';
			end if;
			
			if obstacle1Exists = '1' then
			obstaclePosition1  <= '1';
			elsif (obstacle2Exists = '1' and not(obstacle1Exists = '1' and obstacle3Exists = '1')) then
			obstaclePosition2  <= '1';
			elsif obstacle3Exists = '1' then
			obstaclePosition3  <= '1';
			end if;
		
			if(obstacleStart <= 0) then
				obstaclePosition1  <= '0';
				obstaclePosition2 <= '0';
				obstaclePosition3 <= '0';
				obstacle1Exists <= '0';
				obstacle2Exists <= '0';
				obstacle3Exists <= '0';
			end if;
     end if;
	  
   end process sr;

   obstacle_movement : process(clk_50MHz)
	begin
		if (clk_50MHz'event and clk_50MHz = '1') then -- rising clock edge
			if counter < "10011000100101101000000" then -- binary value is 5 million, 23 bits
				counter <= counter + 1;         
			else            
				clk <= not clk;            
				counter <= (others => '0');
				obstacleStart <= obstacleStart - 50;
				obstacleEnd <= obstacleEnd - 50;
			end if;
			if (obstacleStart <= 0) then
				obstacleStart <= 1770;
				obstacleEnd <= 1920;
			end if;
		end if;
		
	end process obstacle_movement;

	drawPlayer : process(clk_50MHz, disp_ena, row, column, lane1Start, lane1End, lane2Start, lane2End, lane3Start, lane3End, playerStart, playerEnd, obstacleStart, obstacleEnd, pbLD, pbRU)
	begin
	IF(disp_ena = '1') then
	
		if (pbRU = '0' and pbLD = '1') then --right pushbutton pressed, lane 1
					IF((obstaclePosition1 = '1') and ((row < obstacleEnd) AND (row > obstacleStart) AND (column < lane1End) AND (column > lane1Start))) THEN --obstacle lane 1
							red <= (OTHERS => '0');
							green	<= (OTHERS => '0');
							blue <= (OTHERS => '1');
					ELSIF((obstaclePosition2 = '1') and ((row < obstacleEnd) AND (row > obstacleStart) AND (column < lane2End) AND (column > lane2Start))) THEN --obstacle lane 2
							red <= (OTHERS => '0');
							green	<= (OTHERS => '0');
							blue <= (OTHERS => '1');
					ELSIF((obstaclePosition3 = '1') and ((row < obstacleEnd) AND (row > obstacleStart) AND (column < lane3End) AND (column > lane3Start))) THEN --obstacle lane 3
							red <= (OTHERS => '0');
							green	<= (OTHERS => '0');
							blue <= (OTHERS => '1');
					ELSIF((row < 150) AND (row > 0) AND (column < 255) AND (column > 105)) THEN --player
						red <= (OTHERS => '1');
						green	<= (OTHERS => '1');
						blue <= (OTHERS => '1');
					ELSE --"blanking time"
						red <= (OTHERS => '0');
						green	<= (OTHERS => '0');
						blue <= (OTHERS => '0');
					END IF;
		elsif (pbRU = '0' and pbLD = '0') then -- both pressed, lane 2
					IF((obstaclePosition1 = '1') and ((row < obstacleEnd) AND (row > obstacleStart) AND (column < lane1End) AND (column > lane1Start))) THEN --obstacle lane 1
							red <= (OTHERS => '0');
							green	<= (OTHERS => '0');
							blue <= (OTHERS => '1');
					ELSIF((obstaclePosition2 = '1') and ((row < obstacleEnd) AND (row > obstacleStart) AND (column < lane2End) AND (column > lane2Start))) THEN --obstacle lane 2
							red <= (OTHERS => '0');
							green	<= (OTHERS => '0');
							blue <= (OTHERS => '1');
					ELSIF((obstaclePosition3 = '1') and ((row < obstacleEnd) AND (row > obstacleStart) AND (column < lane3End) AND (column > lane3Start))) THEN --obstacle lane 3
							red <= (OTHERS => '0');
							green	<= (OTHERS => '0');
							blue <= (OTHERS => '1');
					ELSIF((row < 150) AND (row > 0) AND (column < 615) AND (column > 465)) THEN --player
						red <= (OTHERS => '1');
						green	<= (OTHERS => '1');
						blue <= (OTHERS => '1');
					ELSE --"blanking time"
						red <= (OTHERS => '0');
						green	<= (OTHERS => '0');
						blue <= (OTHERS => '0');
					END IF;
		elsif (pbRU = '1' and pbLD = '1') then -- both aren't pressed, default lane 2
					IF((obstaclePosition1 = '1') and ((row < obstacleEnd) AND (row > obstacleStart) AND (column < lane1End) AND (column > lane1Start))) THEN --obstacle lane 1
							red <= (OTHERS => '0');
							green	<= (OTHERS => '0');
							blue <= (OTHERS => '1');
					ELSIF((obstaclePosition2 = '1') and ((row < obstacleEnd) AND (row > obstacleStart) AND (column < lane2End) AND (column > lane2Start))) THEN --obstacle lane 2
							red <= (OTHERS => '0');
							green	<= (OTHERS => '0');
							blue <= (OTHERS => '1');
					ELSIF((obstaclePosition3 = '1') and ((row < obstacleEnd) AND (row > obstacleStart) AND (column < lane3End) AND (column > lane3Start))) THEN --obstacle lane 3
							red <= (OTHERS => '0');
							green	<= (OTHERS => '0');
							blue <= (OTHERS => '1');
					ELSIF((row < 150) AND (row > 0) AND (column < 615) AND (column > 465)) THEN --player
						red <= (OTHERS => '1');
						green	<= (OTHERS => '1');
						blue <= (OTHERS => '1');
					ELSE --"blanking time"
						red <= (OTHERS => '0');
						green	<= (OTHERS => '0');
						blue <= (OTHERS => '0');
					END IF;
		elsif (pbLD = '0' and pbRU = '1') then --left pushbutton pressed, lane 3
					IF((obstaclePosition1 = '1') and ((row < obstacleEnd) AND (row > obstacleStart) AND (column < lane1End) AND (column > lane1Start))) THEN --obstacle lane 1
							red <= (OTHERS => '0');
							green	<= (OTHERS => '0');
							blue <= (OTHERS => '1');
					ELSIF((obstaclePosition2 = '1') and ((row < obstacleEnd) AND (row > obstacleStart) AND (column < lane2End) AND (column > lane2Start))) THEN --obstacle lane 2
							red <= (OTHERS => '0');
							green	<= (OTHERS => '0');
							blue <= (OTHERS => '1');
					ELSIF((obstaclePosition3 = '1') and ((row < obstacleEnd) AND (row > obstacleStart) AND (column < lane3End) AND (column > lane3Start))) THEN --obstacle lane 3
							red <= (OTHERS => '0');
							green	<= (OTHERS => '0');
							blue <= (OTHERS => '1');
					ELSIF((row < 150) AND (row > 0) AND (column < 975) AND (column > 825)) THEN --player
						red <= (OTHERS => '1');
						green	<= (OTHERS => '1');
						blue <= (OTHERS => '1');
					ELSE --"blanking time"
						red <= (OTHERS => '0');
						green	<= (OTHERS => '0');
						blue <= (OTHERS => '0');
					END IF;
		end if;	
		
	ELSE --"blanking time"
			red <= (OTHERS => '0');
			green	<= (OTHERS => '0');
			blue <= (OTHERS => '0');
	end if;
	
	end process drawPlayer;

END behavior;