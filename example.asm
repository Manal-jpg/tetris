################ CSC258H1F Winter 2024 Assembly Final Project ##################
# This file contains our implementation of Tetris.
#
# Student 1: Manaljav Munkhbayar, 1009683825
# Student 2: Name, Student Number (if applicable)
######################## Bitmap Display Configuration ########################
# - Unit width in pixels:       8
# - Unit height in pixels:      8
# - Display width in pixels:    96
# - Display height in pixels:   200
# - Base Address for Display:   0x10008000 ($gp)
##############################################################################

    .data
##############################################################################
# Immutable Data
##############################################################################
# The address of the bitmap display. Don't forget to connect it!
ADDR_DSPL:
    .word 0x10008000
# The address of the keyboard. Don't forget to connect it!
ADDR_KBRD:
    .word 0xffff0000

# Game Colours
white: 
    .word 0xffffff

dark_grey: 
    .word 0x282928
light_grey: 
    .word 0x353534  


o_shape:     
    .word 0xffff00          # yellow
    .half 0000011001100000  # tetromino shape in 4x4 table
    # 0000 => 0
    # 0110 => 6
    # 0110 => 6     
    # 0000 => 0

i_shape: 
    .word 0x00b4d8          # blue
    .half 0100010001000100  # tetromino shape in 4x4 table
    # 0100 => 4
    # 0100 => 4
    # 0100 => 4
    # 0100 => 4

s_shape: 
    .word 0xff0000          # red
    .half 0000001101100000  # tetromino shape in 4x4 table
    # 0000 => 0
    # 0011 => 3
    # 0110 => 6
    # 0000 => 0 

z_shape: 
    .word 0x00ff00          # green
    .half 0000011000110000  # tetromino shape in 4x4 table
    # 0000 => 0 
    # 0110 => 6
    # 0011 => 3
    # 0000 => 0

l_shape: 
    .word 0xffa500          # orange
    .half 00000010001000110 # tetromino shape in 4x4 table
    # 0000
    # 0100
    # 0100
    # 0110

j_shape: 
    .word 0xffc0cb          # pink 
    .half 0000001000100110  # tetromino shape in 4x4 table
    # 0000 
    # 0010
    # 0010
    # 0110

t_shape: 
    .word 0x800080          # purple
    .half 0x0720
    # .half 0000011100100000  # tetromino shape in 4x4 table
   # 0000 
   # 0111
   # 0010
   # 0000

current_piece_x:    .word   120               # x coordinate for current piece
current_piece_y:    .word   0               # y coordinste for current piece


grid: 
    .word 

##############################################################################
# Mutable Data
##############################################################################

##############################################################################
# Code
##############################################################################
	.text
	.globl main

	# Run the Tetris game.
main:
    # Initializing display address
    lw $t0, ADDR_DSPL # base address for display
    
# drawing the walls for the game grid   
draw_wall: 
    lw $t1, white           # $t4 = white  
    addi $t5, $t0, 192      # $t5 = the unit location of the wall being painted
    add $t6, $zero, 21      # how many units to paint
    add $t7, $zero, $zero   # counting the num of iterations

draw_left_wall: 
    beq $t7, $t6, bottom_wall_setup 
    sw $t1, 0($t5)          # paint the unit on the location of register t5
    addi $t5, $t5, 48       # $t5 += 1
    addi $t7, $t7, 1        # $t7 += 1
    j draw_left_wall        # keep looping

bottom_wall_setup: 
    addi $t5, $t5, -48      # t5 -= 48 (go up one row)
    li $t6, 12              # how many iterations
    add $t7, $zero, $zero   # iteration counter

draw_bottom_wall: 
    beq $t7, $t6, right_wall_setup  # if iteration ended, do next step
    sw $t1, 0($t5)                  # paint the current location white
    addi $t5, $t5, 4                # locaiton go right by one
    addi $t7, $t7, 1                # add iteration counter
    j draw_bottom_wall              # iterate again
    
right_wall_setup: 
    addi $t5, $t5, -4       # go left by one unit
    li $t6, 21              # how many iterations (num of units to paint)
    add $t7, $zero, $zero   # iteration counter = 0

draw_right_wall: 
    beq $t7, $t6, draw_grid # if finished iteration, do next
    sw $t1, 0($t5)          # paint the current location white 
    addi $t5, $t5, -48      # go up one row
    addi $t7, $t7, 1        # increment iteration counter
    j draw_right_wall       # keep iterating

draw_grid: # basically a double for loop
    lw $t1, dark_grey       # initialize dark grey to a register
    lw $t2, light_grey      # initialize light grey to a register
    
    addi $t5, $t0, 196      # current location 
    addi $t6, $zero, 5      # how many iterations per line
    addi $t7, $zero, 20     # how many lines to paint
    addi $t8, $zero, 0      # current line index
    addi $t9, $zero, 0      # current index inside line
    
line_iteration: 
    
    beq $t8, $t7, next  # when the maximum number of iterations reached, go next
    addi $t8, $t8, 1    # go down one line
    j unit_iteration    # go to the unit iteration


unit_iteration: 
    beq $t9, $t6, line_setup    # go to line_setup after painting all units
    sw $t1, 0($t5)              # paint the first element dark grey
    sw $t2, 4($t5)              # paint the second element light grey
    addi $t5, $t5, 8            # go right twice
    addi $t9, $t9, 1            # increment the iteration counter
    j unit_iteration

line_setup:
    add $t3, $zero, $t1 
    add $t1, $zero, $t2
    add $t2, $zero, $t3     # swapping the two colour values with these 3 lines
    addi $t5, $t5, 8        # go to the first grid location of the next line
    add $t9, $zero, $zero   # reset the unit iteration counter to 0
    j line_iteration

draw_tetromino: 
    # a0 -> shape loaded
    lw $t1, 0($a0)      # loading colour of t_shape
    lh $t2, 4($a0)      # loading the shape into t2 register
    
    #  setting up the x-coordinate location in terms of the bitmap 
    mult $a1, $a1, 4        # each unit is 4 bits  
    # setting up the y-coordinate location in terms of the bitmap
    mult $a2, $a2, 48   # mult 12 => each line = 4 * 12 bit
    # bitmap address = $t0
    add $t3, $a1, $a2   # location
    add $t3, $t0, $t3   # location on bitmap
    
    add $t4, $zero, $zero   # line iteration counter
    add $t5, $zero, $zero   # unit iteration counter
    addi $t9, $zero, 4      # iterations bound
    li $t8, 0x8000          # for checking bit by bit
    
    # sw $t1, 0($t3)
    

shape_line_iteration: 
     beq $t4, $t9, draw_shape_done # loop exit
     j shape_row_iteration
    
shape_row_iteration: 
    beq $t5, $t9, new_line_setup
    and $t7, $t2, $t8       # checking if the curr indexed cell should be painted
    addi $t5, $t5, 1        # loop increment
    srl $t8, $t8, 1
    addi $t3, $t3, 4
    beq $t7, $zero, shape_row_iteration    # if the shape's i-th element is 0, just keep on looping
    sw $t1, 0($t3)
    j shape_row_iteration
    
new_line_setup: 
    addi $t4, $t4, 1    # increment the line iteration
    addi $t3, $t3, 32   # setting up the bitmap for the next line
    li $t5, 0           # resetting the row iteration counter
    j shape_line_iteration  # jump the next line iteration

draw_shape_done:
    jr $ra
    
 next: 
    la $a0, t_shape     # loading addresso f t_shape into a0
    addi $a1, $zero, 4  # loading the x coordinate of the shape 
    addi $a2, $zero, 0     # loading the y coordiante of the shape
    jal draw_tetromino   
    
game_loop:
	# 1a. Check if key has been pressed
	
	
	
    # 1b. Check which key has been pressed
    # 2a. Check for collisions
	# 2b. Update locations (paddle, ball)
	# 3. Draw the screen
    # 4. Sleep 

    #5. Go back to 1
    b game_loop