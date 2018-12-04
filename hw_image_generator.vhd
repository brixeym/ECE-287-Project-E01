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
--		LEDScore    :  out std_logic_vector(6 downto 0));
END hw_image_generator;

ARCHITECTURE behavior OF hw_image_generator IS

signal counter1, counter2, counter3 : std_logic_vector(22 downto 0); -- 23 bits
signal counter_lfsr, lfsr :std_logic_vector(26 downto 0); -- 27 bits
--signal scoreCounter : std_logic_vector(25 downto 0); -- 26 bits
--signal y : std_logic_vector(3 downto 0);
signal clk_lfsr, clk1, clk2, clk3, scoreClk : std_logic;
signal feedback : std_logic;
signal x, obstacle1Exists, obstacle2Exists, obstacle3Exists : std_logic := '0';

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
signal obstacle1Start, obstacle2Start, obstacle3Start : integer := 1770;
signal obstacle1End, obstacle2End, obstacle3End : integer := 1920;

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
			
			if (lfsr(24) = '1') then
				obstacle1Exists <= '1';
			elsif (lfsr(25) = '1') then
				obstacle2Exists <= '1';
			elsif (lfsr(26) = '1') then
				obstacle3Exists <= '1';
			end if;
			
			if (obstacle1Exists = '1') then
			obstaclePosition1  <= '1';
			elsif (obstacle2Exists = '1' and not(obstacle1Exists = '1' or obstacle3Exists = '1')) then
			obstaclePosition2  <= '1';
			elsif (obstacle3Exists = '1') then
			obstaclePosition3  <= '1';
			end if;
		
			if(obstacle1Start <= 0) then
				obstaclePosition1  <= '0';
				obstacle1Exists <= '0';
			elsif(obstacle2Start <= 0) then
				obstaclePosition2 <= '0';
				obstacle2Exists <= '0';
			elsif(obstacle3Start <= 0) then
				obstaclePosition3 <= '0';
				obstacle3Exists <= '0';
			end if;
			
     end if;
   end process sr;

   obstacle1movement : process(clk_50MHz)
	begin
	
		if (clk_50MHz'event and clk_50MHz = '1') then -- rising clock edge
			if counter1 < "10011000100101101000000" then -- binary value is 5 million, 23 bits
				counter1 <= counter1 + 1;         
			else            
				clk1 <= not clk1;            
				counter1 <= (others => '0');
				obstacle1Start <= obstacle1Start - 50;
				obstacle1End <= obstacle1End - 50;
			end if;
			if (obstacle1Start <= 0) then
				obstacle1Start <= 1770;
				obstacle1End <= 1920;
			end if;
		end if;
		
	end process obstacle1movement;

	   obstacle2movement : process(clk_50MHz)
	begin
	
		if (clk_50MHz'event and clk_50MHz = '1') then -- rising clock edge
			if counter2 < "10011000100101101000000" then -- binary value is 5 million, 23 bits
				counter2 <= counter2 + 1;         
			else            
				clk2 <= not clk2;            
				counter2 <= (others => '0');
				obstacle2Start <= obstacle2Start - 50;
				obstacle2End <= obstacle2End - 50;
			end if;
			if (obstacle2Start <= 0) then
				obstacle2Start <= 1770;
				obstacle2End <= 1920;
			end if;
		end if;
		
	end process obstacle2movement;
	
	   obstacle3movement : process(clk_50MHz)
	begin
	
		if (clk_50MHz'event and clk_50MHz = '1') then -- rising clock edge
			if counter3 < "10011000100101101000000" then -- binary value is 5 million, 23 bits
				counter3 <= counter3 + 1;         
			else            
				clk3 <= not clk3;            
				counter3 <= (others => '0');
				obstacle3Start <= obstacle3Start - 50;
				obstacle3End <= obstacle3End - 50;
			end if;
			if (obstacle3Start <= 0) then
				obstacle3Start <= 1770;
				obstacle3End <= 1920;
			end if;
		end if;
		
	end process obstacle3movement;
	
	drawPlayer : process(clk_50MHz, disp_ena, row, column, lane1Start, lane1End, lane2Start, lane2End, lane3Start, lane3End, playerStart, playerEnd, obstacle1Start, obstacle2Start, obstacle3Start, obstacle1End, obstacle2End, obstacle3End, pbLD, pbRU)
	begin
	
	IF(disp_ena = '1') then
	
		if (pbRU = '0' and pbLD = '1') then --right pushbutton pressed, lane 1
					IF((obstaclePosition1 = '1') and ((row < obstacle1End) AND (row > obstacle1Start) AND (column < lane1End) AND (column > lane1Start))) THEN --obstacle lane 1
							red <= (OTHERS => '0');
							green	<= (OTHERS => '0');
							blue <= (OTHERS => '1');
					ELSIF((obstaclePosition2 = '1') and ((row < obstacle2End) AND (row > obstacle2Start) AND (column < lane2End) AND (column > lane2Start))) THEN --obstacle lane 2
							red <= (OTHERS => '0');
							green	<= (OTHERS => '0');
							blue <= (OTHERS => '1');
					ELSIF((obstaclePosition3 = '1') and ((row < obstacle3End) AND (row > obstacle3Start) AND (column < lane3End) AND (column > lane3Start))) THEN --obstacle lane 3
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
					IF((obstaclePosition1 = '1') and ((row < obstacle1End) AND (row > obstacle1Start) AND (column < lane1End) AND (column > lane1Start))) THEN --obstacle lane 1
							red <= (OTHERS => '0');
							green	<= (OTHERS => '0');
							blue <= (OTHERS => '1');
					ELSIF((obstaclePosition2 = '1') and ((row < obstacle2End) AND (row > obstacle2Start) AND (column < lane2End) AND (column > lane2Start))) THEN --obstacle lane 2
							red <= (OTHERS => '0');
							green	<= (OTHERS => '0');
							blue <= (OTHERS => '1');
					ELSIF((obstaclePosition3 = '1') and ((row < obstacle3End) AND (row > obstacle3Start) AND (column < lane3End) AND (column > lane3Start))) THEN --obstacle lane 3
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
					IF((obstaclePosition1 = '1') and ((row < obstacle1End) AND (row > obstacle1Start) AND (column < lane1End) AND (column > lane1Start))) THEN --obstacle lane 1
							red <= (OTHERS => '0');
							green	<= (OTHERS => '0');
							blue <= (OTHERS => '1');
					ELSIF((obstaclePosition2 = '1') and ((row < obstacle2End) AND (row > obstacle2Start) AND (column < lane2End) AND (column > lane2Start))) THEN --obstacle lane 2
							red <= (OTHERS => '0');
							green	<= (OTHERS => '0');
							blue <= (OTHERS => '1');
					ELSIF((obstaclePosition3 = '1') and ((row < obstacle3End) AND (row > obstacle3Start) AND (column < lane3End) AND (column > lane3Start))) THEN --obstacle lane 3
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
					IF((obstaclePosition1 = '1') and ((row < obstacle1End) AND (row > obstacle1Start) AND (column < lane1End) AND (column > lane1Start))) THEN --obstacle lane 1
							red <= (OTHERS => '0');
							green	<= (OTHERS => '0');
							blue <= (OTHERS => '1');
					ELSIF((obstaclePosition2 = '1') and ((row < obstacle2End) AND (row > obstacle2Start) AND (column < lane2End) AND (column > lane2Start))) THEN --obstacle lane 2
							red <= (OTHERS => '0');
							green	<= (OTHERS => '0');
							blue <= (OTHERS => '1');
					ELSIF((obstaclePosition3 = '1') and ((row < obstacle3End) AND (row > obstacle3Start) AND (column < lane3End) AND (column > lane3Start))) THEN --obstacle lane 3
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
	
--	score : process(CLK_50Mhz)
--	begin
--	
--		if (clk_50MHz'event and clk_50MHz = '1') then -- rising clock edge
--			if scoreCounter < "10111110101111000010000000" then -- binary value is 50 million, 26 bits
--				scoreCounter <= scoreCounter + 1;         
--			else            
--				scoreClk <= not scoreClk;  
--				scoreCounter <= (others => '0');
--			end if;
--		end if;
--		
--	end process score;
--	
--	LEDScore : process (CLK_50MHz)
--	begin
--			
--			y <= scoreCounter
--
--			if y = "0000" then 	-- 0
--				LEDScore <= "0000001";
--			elsif y = "0001" then -- 1
--				LEDScore <= "1001111";
--			elsif y = "0010" then -- 2
--				LEDScore <= "0010010";
--			elsif y = "0011" then -- 3
--				LEDScore <= "0000110";
--			elsif y = "0100" then -- 4
--				LEDScore <= "1001100";
--			elsif y = "0101" then -- 5
--				LEDScore <= "0100101"; 
--			elsif y = "0110" then -- 6
--				LEDScore <= "0100000";
--			elsif y = "0111" then -- 7
--				LEDScore <= "0001111";
--			elsif y = "1000" then -- 8
--				LEDScore <= "0000000";
--			elsif y = "1001" then -- 9
--				LEDScore <= "0000100";
--			end if;
--						
--	end process LEDScore;

END behavior;