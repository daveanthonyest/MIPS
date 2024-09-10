.data
# $a2 width for drawing
# $a3 height for drawing
buffer: .space 65536		# reserves the space of the 256x256 display
displayHeight: .word 64 	# width in pixels of display
displayWidth: .word 64  	# height in pixels of display
blue: .word 0x0087CEEB
grey: .word 0x00808080
white: .word 0x00FFFFFF
brown: .word 0x00964B00	
yellow: .word 0x00FFFF00
black: .word 0x00000000
red: .word 0x00FF0000
baseAddress: .word 0x10010000
Win: .asciiz "You Win!"
found: .asciiz "Brown detected"		# this was used for troubleshooting 
newline: .asciiz "\n"
startTime: .word 0
endTime: .word 0
elapsedTime: .word 0
timeString: .asciiz "Elapsed Time: "
.text
main:
	# DRAWS BLUE BACKDROP
	la $s0, buffer	# address register
	lw $s1, blue	# color register
	li $a0, 0	# x register (col)
	li $a1, 0	# y register (row)
	li $a2, 64	# width (col) for rectangle
	li $a3, 64	# height (row) for rectangle
	jal addressCalc
	jal drawRectangle
	
	###################################################################################################
	#DRAWS GREY BUILDING
	lw $s1, grey
	li $a0, 22
	li $a1, 16
	li $a2, 20
	li $a3, 48
	jal addressCalc
	jal drawRectangle
	
	##################################################################################################
	#DRAWS THE GROUND
	lw $s1, black
	li $a0, 0
	li $a1, 63
	li $a2, 64
	li $a3, 1
	jal drawRectangle
	
	###################################################################################################
	#DRAWS THE WINDOWS
	lw $s1, brown
	li $a0, 24
	li $a1, 18
	li $a2, 4
	li $a3, 4
	jal windows
	
	##################################################################################################
	#DRAWS THE SUN
	lw $s1, yellow
	li $a0, 60
	li $a1, 0
	li $a2, 4
	li $s3, 4
	jal drawRectangle
	
	###################################################################################################
	#character initialize
	lw $s1, red
	li $a0, 0
	li $a1, 62
	jal addressCalc
	addiu $sp, $sp, -4	#stores the initial position on stack
	sw $s0, 0($sp)
	
	sw $s1, 0($s0)
	lw $s2, blue
	
	
	##########################################################################################################################################
	gameLoop:
	
	li $v0, 12
    	syscall
    	move $t8, $v0  # The input character is now in $t8
    	
    	li $t9, 'W'   
    	beq $t8, $t9, moveUp
    	li $t9, 'A'    
    	beq $t8, $t9, moveLeft
   	li $t9, 'S'     
    	beq $t8, $t9, moveDown
    	li $t9, 'D'     
    	beq $t8, $t9, moveRight
    	li $t9, 'Q'	# quit
    	beq $t8, $t9, quit
   	
    	j gameLoop
    	
quit:   

li $v0, 10
syscall
#####################################################################################################################################################
addressCalc:
	
	lw  $s0, baseAddress
	mul $t3, $a1, 64	# row*width
	addu $t3, $t3, $a0	#(row*width)+col
	sll $t3, $t3, 2 	# all that * 4
	addu $s0, $s0, $t3	# baseaddress+(row*width)+col
	
	jr $ra
#####################################################################################################################################################
drawRectangle:
    
    	addiu $sp, $sp, -4    # make a spot on the stack
    	sw $ra, 0($sp)        # Store $ra on the stack
	
	li $t0, 0	#COUNTER FOR ROW
	li $t1, 0	#COUNTER FOR COL

	jal addressCalc
	
	drawRow:	
	bge  $t0, $a3,  endDraw  		#loop for row
		bge $t1, $a2,  nextRow		#loop for col
			
			sw $s1, 0($s0)		#this draws each row 
			addiu $s0, $s0 ,4
			addiu $t1, $t1 ,1
			j drawRow
	
			nextRow:
			addiu $t0, $t0, 1
			beq  $t0, $a3, skip 	# here we need to check if it is the last row as we do not want to calculate address out of boundary
			li $t1, 0		# reset for col counter
			addiu $a1, $a1, 1	# increment the y coordinate as we want to move down one to the next row
			jal addressCalc
			skip:
			
			j drawRow
		
		endDraw:
		    
    		lw $ra, 0($sp)        # Load the original $ra value
    		addiu $sp, $sp, 4     # Move back the stack pointer
		jr $ra
		

##############################################################################################################################################
windows: 	
	addiu $sp, $sp, -4	# make a spot on the stack
    	sw $ra, 0($sp)		# Store $ra on the stack
	li $t4, 3 		# counter for window col
	li $t5, 5 		# counter for window row
	
	drawWindow:
	beqz $t5, endWindows
		beqz $t4, nextWindowrow
			move $t6, $a0		#had to store the previous iterations x and y coorninates
			move $t7, $a1 
			jal drawRectangle
			move $a0, $t6		#gets back the x and y coordinates before incrememnting them to the next slot for window
			move $a1, $t7
			
			addiu $a0,$a0, 6 	#the increment for x position
			subiu $t4, $t4, 1 	#counter decrement(inner)
			j drawWindow
			
			nextWindowrow:
			subiu $t5, $t5, 1 	#counter decrement (outer)
			li $t4, 3		#this resets the number for how many windows per row since we modified it earlier 
			li $a0, 24		#resets the x coordinate to starting point
			addiu $a1, $a1, 8	#moves y coord down

			j drawWindow
			
	endWindows:
	
	lw $ra, 0($sp)        # load the original $ra value
    	addiu $sp, $sp, 4     # move back the stack pointer
	jr $ra	
############################################################################################################################################		
moveUp:
	addiu $sp, $sp, -4	# make a spot on the stack
    	sw $ra, 0($sp)		# Store $ra on the stack

	lw  $t4, brown		# I load brown color onto t3 to compare later	
	sw $t1, 0($s0)		# colors  the last position color so I can restore the proper color when I leave the spot

	addi $a0,$a0, 0		# this block of code increments the position based on whatever the movement is. Increments/decrements x or y coordinate
	subiu $a1, $a1, 1
	jal addressCalc

	lw $t1, 0($s0)		# this moves the color onto t1 so that whenever we move we have the color it was last
	beq $t1, $t4, clean	# branch checking if the pixel is brown, if brown we want the position when left to be white
	lw $s1, red
	sw $s1, 0($s0)
	j cleanskip		# we skip the loading white into t1 if we are not on a brown spot

	clean: 
	lw $t1, white		# white substitutes the color brown as we want to clean the dirt
	lw $s1, red
	sw $s1, 0($s0)

	cleanskip:
	move $t5,$a0		# this block ensures that we preserve the value of $a0 which is holding the address of where our "cursor" is
	la $a0, newline		# and prints a newline so that we do not have a long string of letters in the run io box
    	li $v0, 4 
    	syscall
    	move $a0,$t5
    	
	jal clearCheck	       # checks if we are done
	lw $ra, 0($sp)        # load the original $ra value
    	addiu $sp, $sp, 4     # move back the stack pointer
	jr $ra	
	
moveDown:

	addiu $sp, $sp, -4	# make a spot on the stack
    	sw $ra, 0($sp)		# Store $ra on the stack  
    		
	lw $t4, brown
	sw $t1, 0($s0)
	
	addiu $a0,$a0, 0
	addiu $a1, $a1, 1
	jal addressCalc

	lw $t1, 0($s0)
	beq $t1, $t4, clean1
	lw $s1, red
	sw $s1, 0($s0)
	j clean1skip
	
	clean1: 
	lw $t1, white
	lw $s1, red
	sw $s1, 0($s0)

	clean1skip:
	move $t5,$a0
	la $a0, newline
    	li $v0, 4 
    	syscall
    	move $a0,$t5
    	
	jal clearCheck
	lw $ra, 0($sp)        # load the original $ra value
    	addiu $sp, $sp, 4     # move back the stack pointer
	jr $ra	

moveRight:

	addiu $sp, $sp, -4	# make a spot on the stack
    	sw $ra, 0($sp)		# Store $ra on the stack
    	
	lw $t4, brown
	sw $t1, 0($s0)
   	
	addiu $a0,$a0, 1
	addiu $a1, $a1, 0
	jal addressCalc
	
	lw $t1, 0($s0)
	beq $t1, $t4, clean2
	lw $s1, red
	sw $s1, 0($s0)
	j clean2skip

	clean2: 
	lw $t1, white
	lw $s1, red
	sw $s1, 0($s0)

	clean2skip:
	move $t5,$a0
	la $a0, newline
    	li $v0, 4 
    	syscall
    	move $a0,$t5
    	
	jal clearCheck
	lw $ra, 0($sp)        # load the original $ra value
    	addiu $sp, $sp, 4     # move back the stack pointer
	jr $ra	
	
moveLeft:

	addiu $sp, $sp, -4	# make a spot on the stack
    	sw $ra, 0($sp)		# Store $ra on the stack
    	
	lw $t4, brown			
	sw $t1, 0($s0)			

	subiu  $a0,$a0, 1	
	addiu $a1, $a1, 0
	jal addressCalc

	lw $t1, 0($s0)			
	beq $t1, $t4, clean3
	lw $s1, red
	sw $s1, 0($s0)
	j clean3skip

	clean3: 
	lw $t1, white
	lw $s1, red
	sw $s1, 0($s0)

	clean3skip:
	move $t5,$a0
	la $a0, newline
    	li $v0, 4 
    	syscall
    	move $a0,$t5
    	
	jal clearCheck
	lw $ra, 0($sp)        # load the original $ra value
    	addiu $sp, $sp, 4     # move back the stack pointer
	jr $ra	
###################################################################################################################################################
clearCheck:
    	
	addiu $sp, $sp, -4	# make a spot on the stack
    	sw $ra, 0($sp)		# store $ra on the stack

    	la $t5, buffer           # load the address of the buffer
    	li $t6, 4096             # set the loop count to 4096 (64*64 pixels)
    	lw $t7, brown            # load the brown color code

loopCheck:
	lw $t0, 0($t5)           # load a word from the buffer
	beq $t0, $t7, endCheck   # if the pixel is brown, exit loop
    	addiu $t5, $t5, 4        # move to the next spot
    	addiu $t6, $t6, -1       # decrement the loop counter
    	bgtz $t6, loopCheck      # continue looping if the counter is not zero

    				  # If we get here, there are no brown pixels left
    	la $a0, newline
    	li $v0, 4 
    	syscall
    	
    	la $a0, Win            
    	li $v0, 4                
    	syscall
   	j quit                   # jump to quit 

endCheck:	
	lw $ra, 0($sp)        # load the original $ra value
   	addiu $sp, $sp, 4     # move back the stack pointer
    	jr $ra    
