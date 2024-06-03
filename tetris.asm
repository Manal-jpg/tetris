################ CSC258H1F Winter 2024 Assembly Final Project ##################
# This file contains our implementation of Tetris.
#
# Student 1: Manaljav Munkhbayar, 1009683825
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

current_x: 
    .word 4

current_y: 
    .word 0

current_rotation: 
    .word 0

current_shape_address: 
    .space 4    # 4-byte shape

current_score: 
    .word 0     # initializing the current score as 0

current_gravity: 
    .word 800   # setting the initial gravity to 800 (sleep 0.8 seconds)

pause_state: 
    .word 0     # initially the game is not paused. 

grid: 
    .space 1200

grid_filled: 
    .space 300
num_elements: 
    .word 0

# Game Colours
silver: 
    .word 0xc0c0c0

dark_grey: 
    .word 0x282928
light_grey: 
    .word 0x353534  

black: 
    .word 0x000000


t_shape: 
    .word 0x800080          # purple
    .half 0x0270            # initial rotation
    .half 0x0232            # first rotation
    .half 0x0072            # second rotation
    .half 0x0262            # third rotation
    # .half 0000011100100000  # tetromino shape in 4x4 table
   # 0000 
   # 0111
   # 0010
   # 0000
   
o_shape:     
    .word 0xffff00          # yellow
    .half 0x0660
    .half 0x0660
    .half 0x0660
    .half 0x0660
    # .half 0000011001100000  # tetromino shape in 4x4 table
    # 0000 => 0
    # 0110 => 6
    # 0110 => 6     
    # 0000 => 0

i_shape: 
    .word 0x00b4d8          # blue
    .half 0x4444    # tetromino shape in 4x4 table
    .half 0x00f0    # after first rotation
    .half 0x2222    # after second rotation
    .half 0x00f0    # after third rotation 
    # 0100 => 4
    # 0100 => 4
    # 0100 => 4
    # 0100 => 4

s_shape: 
    .word 0xff0000          # red
    .half 0x0360    # tetromino shape in 4x4 table
    .half 0x2310    # after first rotation
    .half 0x0360    # after second rotation
    .half 0x2310    # after third iteration
    # 0000 => 0
    # 0011 => 3
    # 0110 => 6
    # 0000 => 0 

z_shape: 
    .word 0x00ff00      # green
    .half 0x0630        # tetromino shape in 4x4 table
    .half 0x1320        # after first iteration
    .half 0x0630        # after second iteration
    .half 0x1320        # after third iteration
    # 0000 => 0 
    # 0110 => 6
    # 0011 => 3
    # 0000 => 0

l_shape: 
    .word 0xffa500      # orange
    .half 0x0446        # tetromino shape in 4x4 table
    .half 0x0074        # after first rotation
    .half 0x0622        # after second rotation
    .half 0x002e        # after third rotation
    # 0000 => 0
    # 0100 => 4
    # 0100 => 4
    # 0110 => 6

j_shape: 
    .word 0xffc0cb          # pink 
    .half 0x0226            # 4x4 table shape
    .half 0x0047            # after first rotation
    .half 0x0644           # after second rotation
    .half 0x0071            # after third rotation
    # .half 0000001000100110  # tetromino shape in 4x4 table
    # 0000 
    # 0010
    # 0010
    # 0110

##############################################################################
# Mutable Data
##############################################################################

##############################################################################
# Code
##############################################################################
	.text
	
.macro sleep(%sleep_duration)
      li $v0, 32
      li $a0, %sleep_duration
      syscall
.end_macro

.macro play_note(%note) 
      li $v0, 31    # midi out -> play note, return immediately
      li $a0, %note # note
      li $a1, 100   # duration
      li $a2, 0     # instrument
      li $a3, 127   # loudness
      syscall
.end_macro

.macro generate_random_int_till_number(%range)
    li $v0, 42
    li $a0, 0
    li $a1, %range  # up to that value, so putting 7 will choose from (0, 6)
    syscall # return the random number in $a0
.end_macro 

.globl main
	# Run the Tetris game.
main:
    # Initializing display address
    lw $t0, ADDR_DSPL # base address for display
    
# drawing the walls for the game grid   
draw_wall: 
    lw $t1, silver           # $t4 = silver  
    addi $t5, $t0, 0      # $t5 = the unit location of the wall being painted
    add $t6, $zero, 25      # how many units to paint
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
    sw $t1, 0($t5)                  # paint the current location silver
    addi $t5, $t5, 4                # locaiton go right by one
    addi $t7, $t7, 1                # add iteration counter
    j draw_bottom_wall              # iterate again
    
right_wall_setup: 
    addi $t5, $t5, -4       # go left by one unit
    li $t6, 25              # how many iterations (num of units to paint)
    add $t7, $zero, $zero   # iteration counter = 0

draw_right_wall: 
    beq $t7, $t6, draw_blank_space # if finished iteration, do next
    sw $t1, 0($t5)          # paint the current location silver 
    addi $t5, $t5, -48      # go up one row
    addi $t7, $t7, 1        # increment iteration counter
    j draw_right_wall       # keep iterating


# drawing the space above the grid where the tetronimo will display before entering the game grid
draw_blank_space: # basically a double for loop
    lw $t1, black       # initialize black to a register
    
    addi $t5, $t0, 4      # current location 
    addi $t6, $zero, 5      # how many iterations per line
    addi $t7, $zero, 4     # how many lines to paint
    addi $t8, $zero, 0      # current line index
    addi $t9, $zero, 0      # current index inside line
    
blank_line_iteration: 
    
    beq $t8, $t7, draw_grid  # when the maximum number of iterations reached, go next
    addi $t8, $t8, 1    # go down one line
    j blank_unit_iteration    # go to the unit iteration

blank_unit_iteration: 
    beq $t9, $t6, blank_line_setup    # go to line_setup after painting all units
    sw $t1, 0($t5)              # paint the first element black
    sw $t1, 4($t5)              # paint the second element black
    addi $t5, $t5, 8            # go right twice
    addi $t9, $t9, 1            # increment the iteration counter
    j blank_unit_iteration

blank_line_setup:
    addi $t5, $t5, 8        # go to the first grid location of the next line
    add $t9, $zero, $zero   # reset the unit iteration counter to 0
    j blank_line_iteration 


draw_grid: # basically a double for loop
    lw $t1, dark_grey       # initialize dark grey to a register
    lw $t2, light_grey      # initialize light grey to a register
    
    addi $t5, $t0, 196      # current location 
    addi $t6, $zero, 5      # how many iterations per line
    addi $t7, $zero, 20     # how many lines to paint
    addi $t8, $zero, 0      # current line index
    addi $t9, $zero, 0      # current index inside line
    
line_iteration: 
    
    beq $t8, $t7, initial_background_save  # when the maximum number of iterations reached, go next
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
    # parameters: 
    # a0 -> shape loaded
    # a1 -> curr_ x
    # a2 -> curr_y
    # a3 -> rotation added
    
    lw $t1, 0($a0)              # loading colour of t_shape
    lw $a3, current_rotation    # fetching current rotation value
    mult $a3, $a3, 2            # Rotation
    add $a3, $a0, $a3           # finding the location   

    lh $t2, 4($a3)              # loading the shape into t2 register
    
    #  setting up the x-coordinate location in terms of the bitmap 
    mult $a1, $a1, 4            # each unit is 4 bits  
    # setting up the y-coordinate location in terms of the bitmap
    mult $a2, $a2, 48           # mult 12 => each line = 4 * 12 bit
    # bitmap address = $t0
    add $t3, $a1, $a2           # location
    add $t3, $t0, $t3           # location on bitmap
    
    add $t4, $zero, $zero       # line iteration counter
    add $t5, $zero, $zero       # unit iteration counter
    addi $t9, $zero, 4          # iterations bound
    li $t8, 0x8000              # for checking bit by bit
    
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
    
 draw_one_t: 
    lw $a0, current_shape_address     # loading addresso f t_shape into a0
    lw $a1, current_x
    lw $a2, current_y
    jal draw_tetromino
    jr $ra
    
initial_background_save: 
    add $a1, $zero, $t0 
    jal save_background
    
    jal generate_random_shape



initial_loop_before_game_loop: 
    lw $t1, ADDR_KBRD
    lw $t8, 0($t1)                  # Load first word from keyboard
    beqz $t8, initial_loop_before_game_loop 
    lw $a0, 4($t1)              # Load the pressed key ASCII code
    beq $a0, 0x6d, respond_to_m     # respond to M 
    beq $a0, 0x6e, respond_to_n     # respond to N, create a game with empty grid
    j initial_loop_before_game_loop

    
respond_to_m:
    jal paint_a_line_randomly_1
    jal paint_a_line_randomly_2
    jal paint_a_line_randomly_3
    jal paint_a_line_randomly_4
    jal paint_a_line_randomly_5
    j game_loop
    
respond_to_n: 
    j game_loop

game_loop:  
    lw $a0, current_shape_address     # loading addresso f t_shape into a0
    lw $a1, current_x
    lw $a2, current_y
    jal draw_tetromino 
    
    lw $t1, ADDR_KBRD
    lw $t8, 0($t1)                  # Load first word from keyboard
    # 1a. Check if key has been pressed
    # beqz $t8, game_loop     # if no key has been pressed, keep looping
    beqz $t8, respond_to_no_press 
    lw $a0, 4($t1)              # Load the pressed key ASCII code
    # 1b. Check which key has been pressed
    beq $a0, 0x61, respond_to_a     # respond to A 
    beq $a0, 0x77, respond_to_w     # respond to W
    beq $a0, 0x73, respond_to_s     # respond to S
    beq $a0, 0x64, respond_to_d     # respond to D
    beq $a0, 0x70, respond_to_p     # respond to P
    
    # 2a. Check for collisions
    
	# 2b. Update locations (paddle, ball)
	# 3. Draw the screen
    # 4. Sleep 

    #5. Go back to 1
    b game_loop


respond_to_p: 
    play_note(96)       # playing a note on pause.
    la $a1, pause_state 
    lw $a1, 0($a1)  # loading the value of the pause
    
    
    li $s0, 0   # pause state 0  (game not paused)
    li $s1, 1   # pause state 1   (game was paused)
    
    beq $a1, $s0, pause_0   # meaning the game is set to pause on this press
    beq $a1, $s1, pause_1    # the game was paused, with this pause, continue

pause_0:
    la $a1, pause_state     # loading the address of the pause state
    
    sw $s1, 0($a1)    # resetting the pause state to be paused
    
pause_loop:
    lw $t1, ADDR_KBRD
    
    lw $t8, 0($t1) # Load first word from keyboard
    lw $a0, 4($t1)              # Load the pressed key ASCII code
    
    beqz $t8, pause_loop # if no key has been pressed, just keep looping
    beq $a0, 0x70, respond_to_p     # respond to P
    j pause_loop
        
    
pause_1: 
    la $a1, pause_state 
    sw $zero, 0($a1)    # resetting the pause state to be not paused
    j game_loop         # go back to the game loop
    
respond_to_no_press:
    la $a1, current_score   # loading the current score
    lw $a1, 0($a1)  # loading the value of the current score
    
    li $s0, 0
    li $s1, 1
    li $s2, 2
    li $s3, 3
    li $s4, 4
    
    beq $a1, $s0, sleep_800
    beq $a1, $s1, sleep_700
    beq $a1, $s2, sleep_600
    beq $a1, $s3, sleep_500
    beq $a1, $s4, sleep_400
    
    sleep(400)      # when not pressing move down the shape by 1 line
    j respond_to_s
    j game_loop

sleep_800:
    sleep(800)      # when not pressing move down the shape by 1 line
    j respond_to_s
    j game_loop


sleep_700:
    sleep(700)      # when not pressing move down the shape by 1 line
    j respond_to_s
    j game_loop

sleep_600:
    sleep(600)      # when not pressing move down the shape by 1 line
    j respond_to_s
    j game_loop

sleep_500:
    sleep(500)      # when not pressing move down the shape by 1 line
    j respond_to_s
    j game_loop

sleep_400:
    sleep(400)      # when not pressing move down the shape by 1 line
    j respond_to_s
    j game_loop




respond_to_a: 
    # restoring the background before making the move
    add $a1, $zero, $t0
    jal restore_background
    
    # modiyfing the value of the x coordinate
    la $t9, current_x
    lw $t8, 0($t9)
    addi $t8, $t8, -1
    sw $t8, 0($t9)  # saving the value of new x to current_x
    
    
    # check for collision
    jal check_collision # check for collision before drawing the shape
    beq $v0, $zero, respond_to_a_no_collision   # if no collision
    
    # there's been a collision detected for the next move
    la $t9, current_x   # fetch the current_x address
    lw $t8, 0($t9)      # load the value
    addi $t8, $t8, 1    # increment it back 
    sw $t8, 0($t9)
    la $a0, current_shape_address     # loading addresso f t_shape into a0
    lw $a1, current_x
    lw $a2, current_y
    jal draw_tetromino 
    j game_loop
    
    

respond_to_a_no_collision: 
    lw $a0, current_shape_address     # loading address of t_shape into a0
    lw $a1, current_x 
    lw $a2, current_y
    jal draw_tetromino 
    j game_loop
    

respond_to_w:
    add $a1, $zero, $t0
    jal restore_background
    la $t9, current_rotation
    lw $t8, 0($t9)
    addi $t8, $t8, 1
    sw $t8, 0($t9)      # saving the updated rotation
    beq $t8, 4, respond_to_w_minues_one   # if the rotation is equal to 4, make it 0
    
    jal check_collision # check for collision
    beq $v0, $zero, respond_to_w_no_collision   # there's been no collision detected, so just display
    
    # If the code gets here, there's been collision detected
    
    la $t9, current_rotation
    lw $t8, 0($t9)
    addi $t8, $t8, -1   # subtract it back
    sw $t8, 0($t9)      # saving the updated rotation
    lw $a0, current_shape_address     # loading addresso f t_shape into a0
    lw $a1, current_x
    lw $a2, current_y
    jal draw_tetromino 
    j game_loop
    
respond_to_w_no_collision: 
    play_note(32)
    lw $a0, current_shape_address     # loading address of t_shape into a0
    lw $a1, current_x 
    lw $a2, current_y
    jal draw_tetromino 
    j game_loop # done

respond_to_w_minues_one: 
    la $t9, current_rotation    # load the rotation
    lw $t8, 0($t9)
    addi $t8, $t8, -4   # resetting the rotation to 0 as it was 4
    sw $t8, 0($t9)
    
    jal check_collision
    beq $v0, $zero, respond_to_w_no_collision   # no collision, just display the shape
    
    
    # collision detected: 
    
    la $t9, current_rotation    # load the rotation
    lw $t8, 0($t9)
    addi $t8, $t8, 3   # resetting the rotation to 3 as it was 0
    sw $t8, 0($t9)
    
    lw $a0, current_shape_address     # loading addresso f t_shape into a0
    lw $a1, current_x
    lw $a2, current_y
    jal draw_tetromino 
    j game_loop



respond_to_s: 
    # restoring the background before making a move
    add $a1, $zero, $t0
    jal restore_background
    
    # loading the current y value and incrementing it by 1 for the move
    la $t9, current_y
    lw $t8, 0($t9)
    addi $t8, $t8, 1
    sw $t8, 0($t9)
    
    # check for collision
    jal check_collision
    beq $v0, $zero, respond_to_s_no_collision
    
    # collision detected
    la $t9, current_y
    lw $t8, 0($t9)
    addi $t8, $t8, -1
    sw $t8, 0($t9)
    lw $a0, current_shape_address     # loading address of t_shape into a0
    lw $a1, current_x
    lw $a2, current_y
    jal draw_tetromino 
    
    add $a1, $t0, $zero     # saving the current grid here
    jal save_background
    jal check_for_line_removal
    jal save_background
    
    jal generate_random_shape
    
    li $t6, 4               # 
    la $t5, current_x
    sw $t6, 0($t5)
    
    li $t6, 0
    la $t5, current_y
    sw $t6, 0($t5)
    
    lw $a0, current_shape_address     # loading addresso f t_shape into a0
    lw $a1, current_x
    lw $a2, current_y
    jal draw_tetromino
    
    
    j game_loop


respond_to_s_no_collision: 
    lw $a0, current_shape_address     # loading address of t_shape into a0
    lw $a1, current_x 
    lw $a2, current_y
    jal draw_tetromino 
    j game_loop
    

s_check_collision: 
    addi $t8, $t8, -1
    sw $t8, 0($t9)
    lw $a0, current_shape_address     # loading addresso f t_shape into a0
    lw $a1, current_x
    lw $a2, current_y
    jal draw_tetromino 
    add $a1, $t0, $zero     # saving the current grid here
    jal save_background
    jal check_for_line_removal
    jal save_background
    
    jal generate_random_shape
    
    li $t6, 4               # 
    la $t5, current_x
    sw $t6, 0($t5)
    
    li $t6, 0
    la $t5, current_y
    sw $t6, 0($t5)
    
    lw $a0, current_shape_address     # loading addresso f t_shape into a0
    lw $a1, current_x
    lw $a2, current_y
    jal draw_tetromino  
    
    la $t5, num_elements 
    lw $t6, 0($t5)
    addi $t6, $t6, 1
    sw $t6, 0($t5)
    lw $t6, num_elements
    add $t6, $t6, $zero
    
    
    j game_loop


respond_to_d: 
    # restoring the background before making the move
    add $a1, $zero, $t0
    jal restore_background
    
    # modiyfing the value of the x coordinate
    la $t9, current_x
    lw $t8, 0($t9)
    addi $t8, $t8, 1
    sw $t8, 0($t9)  # saving the value of new x to current_x
    
    
    # check for collision
    jal check_collision # check for collision before drawing the shape
    beq $v0, $zero, respond_to_d_no_collision   # if no collision
    
    # there's been a collision detected for the next move
    la $t9, current_x   # fetch the current_x address
    lw $t8, 0($t9)      # load the value
    addi $t8, $t8, -1    # decrement it back 
    sw $t8, 0($t9)
    lw $a0, current_shape_address     # loading addresso f t_shape into a0
    lw $a1, current_x
    lw $a2, current_y
    jal draw_tetromino 
    j game_loop
    
    

respond_to_d_no_collision: 
    lw $a0, current_shape_address     # loading address of t_shape into a0
    lw $a1, current_x 
    lw $a2, current_y
    jal draw_tetromino 
    j game_loop
    


save_background: 
    la $a0, grid    # last saved grid address
    la $a3, grid_filled # status of the grid being filled
    # a1 = t0 -> current grid
    li $t1, 0   # iteration counter
    li $t2, 1200    # total bytes, also loop boundary

save_background_loop: 
    beq $t1, $t2, save_background_loop_end # loop end condition
    
    lw $t4, 0($a1)      # Load current element from the current saved grid
    sw $t4, 0($a0)      # Store that value into the grid being saved
    
    lb $t9, 0($a3)      # load bit value of the 
    
    addi $a1, $a1, 4    # move to the next grid location
    addi $a0, $a0, 4   # move to the next grid location
    addi $a3, $a3, 1    # increment the address of the bit status representation of the grid
    addi $t1, $t1, 4    # increment the counter
    j save_background_loop


save_background_loop_end: 
    play_note(64)   # playing note whenever we save the background, because it means a piece dropped, or the game started
    addi $sp, $sp, -4   # save the current stack pointer in a stack as the inner function might be recursively called
    sw $ra, 0($sp)
    
    jal check_for_line_removal
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4    # popping off the stack
    
    jr $ra
    
    


check_for_line_removal: 
    la $a1, grid    # loading the address of the grid
    li $t1, 1       # where the x-coordinate of the game grid starts
    li $t2, 4       # where the y-coordinate of the game grid starts
    li $t3, 11      # where the x-coordinate of the game ends
    li $t4, 24      # where the y-coordinate of the game ends
    


check_for_line_removal_outer_loop: 
    beq $t2, $t4, check_for_line_removal_done
    
check_for_line_removal_inner_loop:
    beq $t1, $t3, line_removal_line_painted # all units have been checked and found no empty line, so eliminate the line
    
    mult $t6, $t1, 4    # finding the x coordinate
    mult $t7, $t2, 48   # finding the y coordinate
    
    add $t5, $t6, $t7
    add $t5, $t5, $a1  # finding the grid location of the current cell unit
    lw $t5, 0($t5)      # finding the color value of the current cell unit
    
    addi $t1, $t1, 1    # incrementing the x coordiante
    
    lw $s1, dark_grey   # loading dark grey
    lw $s2, light_grey  # loading light grey
    beq $t5, $s1, line_removal_loop_setup  # if dark grey, line is not filled, so go to next line
    beq $t5, $s2, line_removal_loop_setup     # if light grey, line is not filled, so go to next line
    j check_for_line_removal_inner_loop 
    
line_removal_loop_setup: 
    li $t1, 1           # resetting the x-coordinate for the new line
    addi $t2, $t2, 1    # going to the next y coordinate
    j check_for_line_removal_outer_loop
    
line_removal_line_painted: 
    la $t8, current_score   # load the address of the current score
    lw $t8, 0($t8)          # load the value of the score
    addi $t8, $t8, 1        # increment the value by 1
    sw $t8, current_score   # save the current score
    
     j paint_a_line
    

paint_a_line: 
    # t2 is the index of the y coordinate
    # can use t6, t7, $t9
    # s1 -> dark grey, s2 -> light grey
    # find the grid address
    # a1 -> address of the grid
    li $t6, 4   # x coordinate address
    li $t7, 44  # load 44 -> 
    

paint_a_line_loop: 
    beq $t6, $t7, paint_a_line_done
    mult $t9, $t2, 48   # y coordiante address 
    add $t9, $t9, $t6   # x + y
    add $t9, $a1, $t9   # address = x + y + initial address
    
    sw $s1, 0($t9)  # paint the first unit dark grey
    sw $s2, 4($t9)  # paint the second unit light grey
    
    addi $t6, $t6, 8 # painting two cell at a time
    j paint_a_line_loop

paint_a_line_done: 
    # finished painting the line, go check the next line
    j line_removal_loop_setup
    
check_for_line_removal_done:
    jr $ra    
    
restore_background: 
    la $a0, grid
    # add $a1, $zero, $t0  a1 -> current grind, shuold be t0 at most times imo
    li $t1, 0  
    li $t2, 1200 

restore_background_loop: 
    beq $t1, $t2, restore_background_loop_end
    
    lw $t4, 0($a0) 
    sw $t4, 0($a1)
    
    addi $a0, $a0, 4
    addi $a1, $a1, 4
    addi $t1, $t1, 4
    j restore_background_loop

restore_background_loop_end: 
    jr $ra


check_collision:
    # fetch the current address of the shape
    lw $a0, current_shape_address
    # la $a0, current_shape_address
    
    # fetch the value of the current address of the shape
    # x coordiante storedi a1
    # y coordiante stored in a2
    la $a1, current_x
    la $a2, current_y
    # fetch the address of the current rotation of the game piece
    la $a3, current_rotation
    # fetch the value of the coordinates
    lw $a1, 0($a1)  # x-coordiante
    lw $a2, 0($a2)  # y-coordinate
    # fetch the rotation of the shape
    lw $a3, 0($a3)  # rotation value
    
    # loading the current shape according to the rotation
    mult $a3, $a3, 2    # each address is a half word = 2 bytes
    add $a3, $a3, $a0   # adding the value of the rotation to the shape address
    addi $a3, $a3, 4    # adding 4 (size of the color) to get the current address of the shape
    lh $a3, 0($a3)
    # $a3 = current address of the shape (16-bit)
    
    # loading the address of the most recent saved game grid
    la $s3, grid
    
    # loop initialization
    li $t2, 0       # outer loop incrementer
    li $t3, 0       # inner loop incrementer
    li $t4, 4       # loop boundary
    # shape color check
    li $s4, 0x8000  # checking bit by bit
    

collision_detection_outer_loop: 
    beq $t2, $t4, no_collision_detected    # loop done


collision_detection_inner_loop: 
    beq $t3, $t4, collision_detection_outer_loop_setup    # go to the outer loop
    addi $t3, $t3, 1                                # loop increment inner loop
    
    # now gotta find the color of the shape 
    # if 0, check the color of the unit in the grid
    and $t7, $a3, $s4           # checking if the current bit is equal to 1
    srl $s4, $s4, 1             # shift right logical 1 by 1 to check the next bit
    
    beq $t7, $zero, collision_detection_inner_loop
    j collision_detection_inner_loop_shape_one  # if not 0, that means the bit is equal to 1
    
collision_detection_inner_loop_shape_one: 


    # check if that value is equal to grey or dark grey or black
    lw $s0, light_grey  # loading light grey
    lw $s1, dark_grey    # loading dark grey
    lw $s2, black       # loading black
    
     # now, $t6 is the current address of top-left unit of the 4x4 shape
    mult $t6, $a2, 48       # y * 48 = start of the current row
    mult $t7, $a1, 4        # each unit is 4 byte long
    add $t6, $t6, $t7       # y*48 + x = address of the current grid unit
    add $t6, $t6, $t0       # address on the grid 
    # use $t2 (outer loop incremeneter, aka y-coordinate counter)
    # use $t3 (inner loop incrementer, aka x-coordiante counter)
    # t6 = t6 + 48*t2 (implying y) + t3 (implying x) 
    
    
    # finding the grid value related
    mult $t9, $t2, 48   # finding the y-coordinate unit size
    mult $t8, $t3, 4    # y-coordinate unit size
    add $t9, $t9, $t8   # adding x-coordinate
    add $t6, $t6, $t9   # finding address of the corresponding unit     
    lw $t6, 0($t6)      # finding the colour value of the corresponding unit
    
    
    beq $t6, $s0, collision_detection_inner_loop    # dark grey. if the corresponding value is not painted, no problem, go ahead with the loop
    beq $t6, $s1, collision_detection_inner_loop    # light grey. if the corresponding value is not painted, no problem, go ahead with the loop
    beq $t6, $s2, collision_detection_inner_loop    # black. if the corresponding value is not painted, no problem, go ahead with the loop
    
    # now, if the unit is painted, what do I do?
    j collision_detection_unit_already_painted
    
    
collision_detection_unit_already_painted: 
    li $v0, 1   # indicating a collision being detected
    j collision_detection_done  # immediately return as there's been a collision, no further check needed
    
    

collision_detection_outer_loop_setup: 
    addi $t2, $t2, 1                # incrementing the outer loop by 1
    li $t3, 0                       # resetting the inner loop incrementer for new iteration
    j collision_detection_outer_loop
    

no_collision_detected:
    li $v0, 0
    j collision_detection_done
    
    
collision_detection_done: 
    jr $ra  # return


generate_random_shape: 
    generate_random_int_till_number(7)
    li $s0, 0
    li $s1, 1
    li $s2, 2
    li $s3, 3
    li $s4, 4
    li $s5, 5
    li $s6, 6
    beq $a0, $s0, random_shape_0
    beq $a0, $s1, random_shape_1
    beq $a0, $s2, random_shape_2
    beq $a0, $s3, random_shape_3
    beq $a0, $s4, random_shape_4
    beq $a0, $s5, random_shape_5
    beq $a0, $s6, random_shape_6
    

random_shape_0: 
    la $v0,  current_shape_address
    la $v1, t_shape
    sw $v1, 0($v0)  
    jr $ra
    
random_shape_1: 
    la $v0,  current_shape_address
    la $v1, o_shape
    sw $v1, 0($v0)
    jr $ra
    
random_shape_2: 
    la $v0,  current_shape_address
    la $v1, i_shape
    sw $v1, 0($v0)
    jr $ra
random_shape_3: 
    la $v0,  current_shape_address
    la $v1, s_shape
    sw $v1, 0($v0)
    jr $ra
random_shape_4:
    la $v0,  current_shape_address
    la $v1, z_shape
    sw $v1, 0($v0)
    jr $ra
random_shape_5: 
    la $v0,  current_shape_address
    la $v1, j_shape
    sw $v1, 0($v0)
    jr $ra
random_shape_6: 
    la $v0,  current_shape_address
    la $v1, l_shape
    sw $v1, 0($v0)
    jr $ra
    
paint_a_line_randomly_1:
    # 39FF14 -> Neon green
    # t2 is the index of the y coordinate
    # can use t6, t7, $t9
    # s1 -> dark grey, s2 -> light grey
    # find the grid address
    # a1 -> address of the grid
    
    li $t3 , 4   # x coordinate address
    li $t7, 44  # end of the line 
    li $s1, 0x39ff14    # loading neon green to s1

paint_a_line_randomly_loop_1: 
    la $a1, grid        # loading the address of the grid
    li $t2, 19  # index of the y coordinate
    beq $t3, $t7, paint_a_line_randomly_done_1
    mult $t9, $t2, 48   # y coordiante address 
    add $t9, $t9, $t3   # x + y
    add $t9, $a1, $t9   # address = x + y + initial address
    addi $t3, $t3, 4 # painting one cell at a time
    
    generate_random_int_till_number(2)
    beq $a0, $zero, paint_a_line_randomly_loop_1
    sw $s1, 0($t9)  # paint the first unit dark grey
    j paint_a_line_randomly_loop_1

paint_a_line_randomly_done_1: 
    jr $ra  # return

#########################################################################################################################


paint_a_line_randomly_2:
    # 39FF14 -> Neon green
    # t2 is the index of the y coordinate
    # can use t6, t7, $t9
    # s1 -> dark grey, s2 -> light grey
    # find the grid address
    # a1 -> address of the grid
    
    li $t3 , 4   # x coordinate address
    li $t7, 44  # end of the line 
    li $s1, 0x39ff14    # loading neon green to s1

paint_a_line_randomly_loop_2: 
    la $a1, grid        # loading the address of the grid
    li $t2, 20  # index of the y coordinate
    beq $t3, $t7, paint_a_line_randomly_done_2
    mult $t9, $t2, 48   # y coordiante address 
    add $t9, $t9, $t3   # x + y
    add $t9, $a1, $t9   # address = x + y + initial address
    addi $t3, $t3, 4 # painting one cell at a time
    
    generate_random_int_till_number(2)
    beq $a0, $zero, paint_a_line_randomly_loop_2
    sw $s1, 0($t9)  # paint the first unit dark grey
    j paint_a_line_randomly_loop_2

paint_a_line_randomly_done_2: 
    jr $ra  # return

#########################################################################################################################

    
paint_a_line_randomly_3:
    # 39FF14 -> Neon green
    # t2 is the index of the y coordinate
    # can use t6, t7, $t9
    # s1 -> dark grey, s2 -> light grey
    # find the grid address
    # a1 -> address of the grid
    
    li $t3 , 4   # x coordinate address
    li $t7, 44  # end of the line 
    li $s1, 0x39ff14    # loading neon green to s1

paint_a_line_randomly_loop_3: 
    la $a1, grid        # loading the address of the grid
    li $t2, 21  # index of the y coordinate
    beq $t3, $t7, paint_a_line_randomly_done_3
    mult $t9, $t2, 48   # y coordiante address 
    add $t9, $t9, $t3   # x + y
    add $t9, $a1, $t9   # address = x + y + initial address
    addi $t3, $t3, 4 # painting one cell at a time
    
    generate_random_int_till_number(2)
    beq $a0, $zero, paint_a_line_randomly_loop_3
    sw $s1, 0($t9)  # paint the first unit dark grey
    j paint_a_line_randomly_loop_3

paint_a_line_randomly_done_3: 
    jr $ra  # return

#########################################################################################################################

paint_a_line_randomly_4:
    # 39FF14 -> Neon green
    # t2 is the index of the y coordinate
    # can use t6, t7, $t9
    # s1 -> dark grey, s2 -> light grey
    # find the grid address
    # a1 -> address of the grid
    
    li $t3 , 4   # x coordinate address
    li $t7, 44  # end of the line 
    li $s1, 0x39ff14    # loading neon green to s1

paint_a_line_randomly_loop_4: 
    la $a1, grid        # loading the address of the grid
    li $t2, 22  # index of the y coordinate
    beq $t3, $t7, paint_a_line_randomly_done_4
    mult $t9, $t2, 48   # y coordiante address 
    add $t9, $t9, $t3   # x + y
    add $t9, $a1, $t9   # address = x + y + initial address
    addi $t3, $t3, 4 # painting one cell at a time
    
    generate_random_int_till_number(2)
    beq $a0, $zero, paint_a_line_randomly_loop_4
    sw $s1, 0($t9)  # paint the first unit dark grey
    j paint_a_line_randomly_loop_4

paint_a_line_randomly_done_4: 
    jr $ra  # return

#########################################################################################################################

paint_a_line_randomly_5:
    # 39FF14 -> Neon green
    # t2 is the index of the y coordinate
    # can use t6, t7, $t9
    # s1 -> dark grey, s2 -> light grey
    # find the grid address
    # a1 -> address of the grid
    
    li $t3 , 4   # x coordinate address
    li $t7, 44  # end of the line 
    li $s1, 0x39ff14    # loading neon green to s1

paint_a_line_randomly_loop_5: 
    la $a1, grid        # loading the address of the grid
    li $t2, 23  # index of the y coordinate
    beq $t3, $t7, paint_a_line_randomly_done_5
    mult $t9, $t2, 48   # y coordiante address 
    add $t9, $t9, $t3   # x + y
    add $t9, $a1, $t9   # address = x + y + initial address
    addi $t3, $t3, 4 # painting one cell at a time
    
    generate_random_int_till_number(2)
    beq $a0, $zero, paint_a_line_randomly_loop_5
    sw $s1, 0($t9)  # paint the first unit dark grey
    j paint_a_line_randomly_loop_5

paint_a_line_randomly_done_5: 
    jr $ra  # return

#########################################################################################################################

