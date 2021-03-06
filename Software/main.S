/*
 * main.S - #Project 1 Simple Bot Code
 * running on Nexys4 DDR FPGA target board
 *
 * Copyright Srivatsa Yogendra, 2017
 * 
 * Created By:		Srivatsa Yogendra
 * Modified By:     Michael Bourquin, Jean Shirimpaka
 * Last Modified:	12-Oct-2018
 *
 * Description:
 * Reads the switches on the FPGA board and writes 
 * the values to the LEDs
 * Reads the Buttons on the FPGA board and outputs a compass (3 Digit Display) based on relative turning position of Robot
 * Displays a robot motion in the 4th display based on button input
 *
 * Assumes the existance of an AHB-Lite peripheral for the 8 digit
 * 7-segment display on the Nexys4 DDR.  The peripheral has 4 memory
 * mapped I/O registers:
 *	PORT_SEVENSEG_EN - (8 bits) Individual enables for each digit. Set bit to 0 to enable digit
 *									Digit7 = bit[7], Digit6 = bit[6], Digit5 = bit[5], Digit4 = bit[4],
 *									Digit3 = bit[3], Digit2 = bit[2], Digit1 = bit[1], Digit0 = bit[0]
 *	PORT_SEVENSEG_HGH = (32 bits) Value of digit.  Each digit has the range of 31:0, top 3 bits ignored
 *									Digit7 = bits[31:24], Digit6 = bits[23:16],
 *									Digit5 = bits[15:8] , Digit4 = bits[7:0]
 *	PORT_SEVENSEG_LOW = (32 bits) Value of digit.  Each digit has the range of 31:0, top 3 bits ignored
 *									Digit3 = bits[31:24], Digit2 = bits[23:16],
 *									Digit1 = bits[15:8] , Digit0 = bits[7:0]
 *	PORT_SEVENSEG_DP - (8 bits) Individual decimal points for each digit. Set bit to 0 to turn on the decimal point
 *									DP7 = bit[7], DP6 = bit[6], DP5 = bit[5], DP4 = bit[4],
 *									DP3 = bit[3], DP2 = bit[2], DP1 = bit[1], DP0 = bit[0]
 */

PORT_SEVENSEG_EN 	= 0xbf700000		# (o) 7 Segment enable
PORT_SEVENSEG_HGH	= 0xbf700004		# (o) 7 Segment Higher Display
PORT_SEVENSEG_LOW	= 0xbf700008		# (o) 7 Segment Lower Display
PORT_SEVENSEG_DP	= 0xbf70000C		# (o) 7 segment Decimal Point Display
BUTTONS_ADDR 		= 0xbf800008        	# (o) Input Buttons Address


#Added by Jean
H_SW_ADDR           = 0xbf800004        #Address
H_PB_ADDR           = 0xbf800008
H_BotInfo_ADDR      = 0xbf80000C
H_BotUpdt_Sync_ADDR = 0xbf800010
H_BotCtrl_ADDR      = 0xbf800014
H_INT_ACK_ADDR      = 0xbf800018
#End

 
 
.globl main
main:
	li   $20, 0                    #loop counter
   	li	 $23, 0                         	# $23 = hundreds place counter register
   	li	 $24, 0					# $24 = tens place counter register
   	li	 $25, 0                         	# $25 = ones place counter register
   	li   $12, LEDS_ADDR #0xbf80    	    	# $12 = address of LEDs (0xbf800000)
   	addiu $13, $12, 4    				# $13 = address of switches
   	li    $14, PORT_SEVENSEG_EN			# $14 = address of the 7 segment enable
   	li 	 $15, PORT_SEVENSEG_HGH			# $15 = address of the higher 7 segment digits
   	li 	 $16, PORT_SEVENSEG_LOW			# $16 = address of the lower 7 segment digits
   	li 	 $17, PORT_SEVENSEG_DP			# $17 = address of the dp points in 7 segment digits
   	li	 $18, BUTTONS_ADDR			# $18 = address of the button inputs (last 4 bits are UPLR)
   	li	 $26, 0                         	# $26 = motion state register, default to 0(idle)
   	li 	  $11, 0xf0					# set display enable to only enable lowest 4 displays (b'11110000)
	sw	  $11, 0($14)				# set display enables
	li 	  $11, 0xFF					# Turn off all of the decimal points
	sw	  $11, 0($17)

	li $4, 0xf4240 					#slow period (1hz approximated to 1000000 readIO loops)
	li $5, 0x30d40 					#norm period
	li $6, 0x186a0 					#fast period
	
	#Added by Jean
	li $21,H_BotInfo_ADDR address   #Register for H_BotInfo_ADDR address
	li $3,H_BotUpdt_Sync_ADDR       #Register for H_BotUpdt_Sync_ADDR
	li $8,H_INT_ACK_ADDR            #Register for H_INT_ACK_ADDR
	li $7,H_BotInfo_ADD             #Register for  H_BotInfo_ADD 
	
	li $1,0                         #Register for direction value(forward, reverse, right, stop)
	li $21, H_BotInfo_ADDR          # Direction state register

	sw $1,0($21)                    #write the direction value to $21 for rojobot movement forward, reverse or right turn
    #End


#Added by Jean for State machine 
updateLoop:
    j stateMachine                          # To check the state
	updateLoopAfterStateMachine    			# Load the bot update port address
	lw 	  $21, 0($3) 				        #	write the bot update val to $21
	beq	  $21, $0, updateLoop
	li 	  $8, H_INT_ACK_ADDR			    #   Load the Acknowledgement port address
	li 	  $21, 1				            #   Set the Acknowledgement bit
	sw 	  $21, 0($3)				        # 	Write the Acknowledgement bit
	li $21,0
	li $8,0
updateLoopAfterStateMachine:
    li    $3, H_BotUpdt_Sync_ADDR			# Load the bot update port address
    

stateMachine:
    BlkLL                              #Detect sensor val is black line

	beq $19, 7, forwardState            #If the mask value is 111 or 7(robot is on black line) then go forward label  
             	                       #Clear out all registers
	li $19,0
	li $17,0
    j updateLoopAfterStateMachine
    

forwardState:
	li $1, 33                          #Load 33(value to write for forward)
    BlkLL                              #To detect a black line	

	bne $19, 7, reverseState            #If the mask value is not 111 or 7(robot is not on black line) then go reverse 
	forwardState                        #otherwise continue in forward state and clear out all registers
    li $19, 0                           
	li $17,0
	
	
	
	j updateLoop
	
reverseState:
    li $1,22                          #Load 22(value to write for reverse)
	BlkLL                             # To detect a black line
	bne $19, 7, rightState            #If the mask value is not 111 or 7(robot is not on black line) then go right 
    reverseState	                  #otherwise continue in reverse state and clear out all registers 
    li $19, 0                           
	li $17,0
    j updateLoop



rightState:
	li $1, 2                           #Load 2(value to write for reverse)
	
	#Current orientation determination starts here
	
    li $t3, H_BotInfo_ADD              # Load and store Bot Info into $3 and $11
    lw $11, 0($t3)

    andi $12, $11,0x00000007         #Mask the bot info with 0x00000007 to get current orientation
    #Current orientation ends here
	
	sub $12, $3, $12                 #Compute and store in $12 the difference between current and previous orientation
	beq $12, 180,forward180State     #go to forward180State if current-prev=180 otherwise go to updateLoop 
	
	j updateLoop
	
forward180State:
    BlkLL                            #To detect the black line
	beq $19,7 forwardState           #If a blackline is detected then go forward otherwise reverse
	reverseState
	li $19, 0                        #Clear all used registers.                      
	li $18,0
	li $17,0
	li $2,0
	
    j updateLoop
	
#Masking Bot info to obtain BlkLL value
BlkLL:
	li $7, H_BotInfo_ADD               #Load Bot Info to $2

    lw $17, 0($7)                      #Store Bot Info in $17                                  
    andi $19, $17, 0x00000700          #Mask the bot info to get BlkLL value and store into $18
    slr $19 8                          #right shift for the actual val
#Masking ends here
	
#End of Jean's state machine
	
readIO:
	li    $3,  0						# lower digit data, reset to 0 every write
	lw    $11, 0($13)    				# read switches: $10 = switch values
	lw	  $19, 0($18)       			# read buttons: $19 = button values
	andi  $19, $19, 0xf     			# load only the lowest 4 bits ($19 stores values of UDLR Buttons)	(don't care what the others are)
	sw    $11, 0($12)    				# write switch values to leds

	#write out the current compass digits
	add $11, $0, $23  #write hundreds value
	sll $11, $11, 16 #shift the data 16 bits left for digit 2 data (hundreds)
	add $3, $11, $3 #add this to lower digit data for later write out

	add $11, $0, $24  #write tens value
	sll $11, $11, 8 #shift the data 8 bits left for digit 1 data (tens)
	add $3, $11, $3 #add this to lower digit data for later write out

	add $11, $0, $25  #write ones value
	add $3, $11, $3 #add this to lower digit data for later write out
	
	#motion state machine code (outputs only)
	
	beq $26, 0, labelidle //start code for motion state machine, if branch state == goto label
	beq $26, 1, labela
	beq $26, 2, labelb
	beq $26, 3, labelc
	beq $26, 4, labeld
	beq $26, 5, labele
	beq $26, 6, labelf
	beq $26, 7, labelg
	j labelclock
	
	#16 = a, 17= b, 18 = c, 19 = d, 20 = e, 21 = f, 22 = g, 28 = blank
	labelidle:
	  	#write correct digit code to digit data
	  	li $11, 28  #write blank value
	  	j labelclock
	labela:
	  	#write correct digit code to digit data
	  	li $11, 16  #write a value
	  	j labelclock
	
	labelb:
	  	#write correct digit code to digit data
	  	li $11, 17  #write b value
	  	j labelclock
	  
	labelc:
	  	#write correct digit code to digit data
	  	li $11, 18  #write c value
	  	j labelclock
	  
	labeld:
	  	#write correct digit code to digit data
	  	li $11, 19  #write d value
	  	j labelclock
	  
	labele:
	  	#write correct digit code to digit data
	  	li $11, 20  #write e value
	  	j labelclock
	  
	labelf:
	  	#write correct digit code to digit data
	  	li $11, 21  #write f value
	  	j labelclock
	  
	labelg:
	  	#write correct digit code to digit data
	  	li $11, 22  #write g value
	  	j labelclock
	
	labelclock:
	
	sll $11, $11, 24 #shift the data 24 bits left for digit 3 data
	add $3, $11, $3 #add this to lower digit data for later write out

	#write the digit data to the digit address
	sw	  $3, 0($16) 
	
	#branch statement is checking if equal, if true then goes to label (equivalent to if statement)
	#figure out the state change speed, if the state should go to next state based on clock counter

	#input from button data comes in bits like so -> UDLR
	#Buttons (UPLR)
	#forward -> 0011 (3)
	#reverse -> 1100 (12)
	#idle -> 0000 (0) or 1111 (15), 10, 5
	#clockwise -> 4, 2, 7, 13
	#counterclockwise -> 1, 11, 14, 8
	#clockwise fast -> 0101 (d5) (reverse right and left)
	#counter clockwise fast -> 1010 (d10) (reverse left and right motors)

	beq $19, 6, labelfast #clockwise fast
	beq $19, 9, labelfast #counterclockwise fast
	
	beq $19, 3, labelslow #forward
	beq $19, 12, labelslow #reverse
	beq $19, 0, labelslow #idle
	beq $19, 15, labelslow #idle
	beq $19, 10, labelslow #idle
	beq $19, 5, labelslow #idle

	beq $19, 2, labelnorm #clockwise
	beq $19, 7, labelnorm #clockwise
	beq $19, 4, labelnorm #clockwise
	beq $19, 14, labelnorm #clockwise
	beq $19, 1, labelnorm #counter clockwise
	beq $19, 11, labelnorm #counter clockwise
	beq $19, 8, labelnorm #counter clockwise
	beq $19, 13, labelnorm #counter clockwise
	
	j labelskipnextstate

	labelfast:
		#check timer for 10hz speed (P = .1 seconds) goto labelfastcheck if P reached
		slt $11, $20, $6 #(set $11 to 1 if time difference is less than 100000)
		bne $11, 1, labelfastcheck #goto if not equal to 1, (greater than or equal)
		#ifnot
		j labelskipnextstate #skip all the next state stuff, not time yet
		
	labelfastcheck: #compass change check for 10hz speed, goto statemachinenext when done
		beq $19, 9, labelcompassdecrement #decrement in any case that robot is turning cc, increment otherwise
		beq $19, 6, labelcompassincrement
		j statemachinenext
		
	labelslow:
		#check timer for 1hz speed (P = 1 seconds), goto statemachinenext if P reached
		slt $11, $20, $4 #(set $11 to 1 if time difference is less than 1000000)
		bne $11, 1, statemachinenext #goto if not equal to 1, (greater than or equal)
		#an else
		j labelskipnextstate
		
	labelnorm:
		#check timer for 5hz speed (P = .2 seconds),goto labelnormcheck if P reached
		slt $11, $20, $5 #(set $11 to 1 if time difference is less than 200000)
		bne $11, 1, labelnormcheck #goto if not equal to 1, (greater than or equal)
		#an else
		j labelskipnextstate
		
	labelnormcheck: #compass change check for 5hz speed, goto statemachinenext when done
		beq $19, 1, labelcompassdecrement #decrement in any case that robot is turning cc, increment otherwise
		beq $19, 2, labelcompassincrement
		beq $19, 11, labelcompassdecrement
		beq $19, 7, labelcompassincrement
		beq $19, 4, labelcompassincrement #clockwise
		beq $19, 14, labelcompassincrement #clockwise
		beq $19, 8, labelcompassdecrement #counter clockwise
		beq $19, 13, labelcompassdecrement #counter clockwise
		j statemachinenext
		
	labelcompassdecrement:
		#decrement the compass counter
		addi $25, $25, -1
		beq $25, -1, decrementtens
		j statemachinenext

	decrementtens:
		li $25, 9
		addi $24, $24, -1
		beq $24, -1, decrementhundreds
		j statemachinenext

	decrementhundreds:
		li $24, 9
		addi $23, $23, -1
		beq $23, -1, resetcompasscountersdecrement
		j statemachinenext

	resetcompasscountersdecrement:
		li $23, 3
		li $24, 5
		li $25, 9
		#set counters to 359
		j statemachinenext

	resetcompasscounters:
		li $23, 0
		li $24, 0 
		li $25, 0
		j statemachinenext

	labelcompassincrement:
		#increment the compass counter
		addi $25, $25, 1
		beq $25, 10, incrementtens
		j statemachinenext

	incrementtens:
		li $25, 0
		addi $24, $24, 1
		beq $23, 3, incrementtenslast #if hundreds is 3
		beq $24, 10, incrementhundreds #else if tens is 10
		j statemachinenext

	incrementtenslast:
		beq $24, 6, resetcompasscounters #if hundreds is 3 and tens is 6 that means counter needs to be reset
		j statemachinenext

	incrementhundreds:
		li $24, 0
		addi $23, $23, 1
		j statemachinenext
	
	statemachinenext: #motion state machine (next state only)

	#reset the loop counter (timer), next state reached
	li $20, 0

	#Buttons (UPLR)
	#forward -> 0011 (3)
	#reverse -> 1100 (12)
	#idle -> 0000 (0) or 1111 (15), 10, 5
	#clockwise -> 4, 2, 7, 13
	#counterclockwise -> 1, 11, 14, 8
	#clockwise fast -> 0101 (d5) (reverse right and left)
	#counter clockwise fast -> 1010 (d10) (reverse left and right motors)
	
	beq $26, 0, labelidlenext
	beq $26, 1, labelanext
	beq $26, 2, labelbnext
	beq $26, 3, labelcnext
	beq $26, 4, labeldnext
	beq $26, 5, labelenext
	beq $26, 6, labelfnext
	beq $26, 7, labelgnext
	j labelskipnextstate


	labelidlenext:
	  beq $19, 3, anext   		#forward
	  beq $19, 12, dnext   		#reverse
	  beq $19, 1, anext 			#cc
	  beq $19, 11, anext 			#cc
	  beq $19, 4, anext 			#cw
	  beq $19, 14, anext 			#cc
	  beq $19, 9, anext 			#ccf
	  beq $19, 2, anext			#cw
	  beq $19, 7, anext			#cw
	  beq $19, 8, anext			#cc
	  beq $19, 13, anext			#cw
	  beq $19, 6, anext			#cwf
	  beq $19, 0, gnext			#idle
	  beq $19, 15, gnext			#idle
	  beq $19, 10, gnext #idle
	  beq $19, 5, gnext #idle
	  j idlenext
	  
	labelanext:
	  beq $19, 3, idlenext		#forward		
	  beq $19, 12, idlenext	 	#reverse		
	  beq $19, 1, fnext			#cc
	  beq $19, 11, fnext			#cc	
	  beq $19, 4, bnext 			#cw
	  beq $19, 14, fnext 			#cc
	  beq $19, 9, fnext			#ccf	
	  beq $19, 2, bnext			#cw	
	  beq $19, 7, bnext			#cw	
	  beq $19, 8, fnext			#cc
	  beq $19, 13, bnext			#cw
	  beq $19, 6, bnext			#cwf	
	  beq $19, 0, idlenext		#idle		
	  beq $19, 15, idlenext		#idle		
	  j idlenext
	
	labelbnext:
	  beq $19, 3, idlenext		#forward					
	  beq $19, 12, idlenext		#reverse					
	  beq $19, 1, anext			#cc
	  beq $19, 11, anext			#cc
	  beq $19, 4, cnext 			#cw
	  beq $19, 14, anext 			#cc
	  beq $19, 9, anext			#ccf			
	  beq $19, 2, cnext			#cw			
	  beq $19, 7, cnext			#cw
	  beq $19, 8, anext			#cc
	  beq $19, 13, cnext			#cw
	  beq $19, 6, cnext			#cwf			
	  beq $19, 0, idlenext		#idle					
	  beq $19, 15, idlenext		#idle					
	  j idlenext
	  
	labelcnext:
	  beq $19, 3, idlenext		#forward				
	  beq $19, 12, idlenext		#reverse				
	  beq $19, 1, bnext			#cw
	  beq $19, 11, bnext			#cc		
	  beq $19, 4, dnext 			#cw
	  beq $19, 14, bnext 			#cc
	  beq $19, 9, bnext			#ccf		
	  beq $19, 2, dnext			#cw		
	  beq $19, 7, dnext			#cw		
	  beq $19, 8, bnext			#cc
	  beq $19, 13, dnext			#cw
	  beq $19, 6, dnext			#cwf		
	  beq $19, 0, idlenext		#idle				
	  beq $19, 15, idlenext		#idle				
	  j idlenext
	  
	labeldnext:
	  beq $19, 3, idlenext		#forward				
	  beq $19, 12, idlenext		#reverse				
	  beq $19, 1, cnext			#cc
	  beq $19, 11, cnext			#cc
	  beq $19, 4, enext 			#cw
	  beq $19, 14, cnext 			#cc
	  beq $19, 9, cnext			#ccf		
	  beq $19, 2, enext			#cw		
	  beq $19, 7, enext			#cw		
	  beq $19, 8, cnext			#cc
	  beq $19, 13, enext			#cw
	  beq $19, 6, enext			#cwf		
	  beq $19, 0, idlenext		#idle				
	  beq $19, 15, idlenext		#idle				
	  j idlenext
	  
	labelenext:
	  beq $19, 3, idlenext		#forward			
	  beq $19, 12, idlenext		#reverse			
	  beq $19, 1, dnext			#cc
	  beq $19, 11, dnext			#cc	
	  beq $19, 4, fnext 			#cw
	  beq $19, 14, dnext 			#cc
	  beq $19, 9, dnext			#ccf	
	  beq $19, 2, fnext			#cw	
	  beq $19, 7, fnext			#cw	
	  beq $19, 8, dnext			#cc
	  beq $19, 13, fnext			#cw
	  beq $19, 6, fnext			#cwf	
	  beq $19, 0, idlenext		#idle			
	  beq $19, 15, idlenext		#idle			
	  j idlenext
	  
	labelfnext:
	  beq $19, 3, idlenext		#forward			
	  beq $19, 12, idlenext		#reverse			
	  beq $19, 1, enext			#cc
	  beq $19, 11, enext			#cc	
	  beq $19, 4, anext 			#cw
	  beq $19, 14, enext 			#cc
	  beq $19, 9, enext			#ccf	
	  beq $19, 2, anext			#cw	
	  beq $19, 7, anext			#cw	
	  beq $19, 8, enext			#cc
	  beq $19, 13, anext			#cw
	  beq $19, 6, anext			#cwf	
	  beq $19, 0, idlenext		#idle			
	  beq $19, 15, idlenext		#idle			
	  j idlenext
	  
	labelgnext:
	  j idlenext #next state from g is always idle
	
	#set next state register
	idlenext:
	  li $26, 0
	  j labelskipnextstate
	anext:
	  li $26, 1
	  j labelskipnextstate
	bnext:
	  li $26, 2
	  j labelskipnextstate
	cnext:
	  li $26, 3
	  j labelskipnextstate
	dnext:
      li $26, 4
	  j labelskipnextstate
	enext:
	  li $26, 5
	  j labelskipnextstate
	fnext:
	  li $26, 6
	  j labelskipnextstate
	gnext:
	  li $26, 7
	  j labelskipnextstate
	  
	labelskipnextstate:
	#increment the loop counter (timer)
	add $20, 1

	beq   $0, $0, readIO 	# repeat
	nop                  	# branch delay slot
