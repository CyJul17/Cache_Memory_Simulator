.data 
	# User inputs
	user_address: 	.asciiz "Input the number of address: "
	user_naddress: 	.asciiz "Input the number of memory addresses to access (max 100): "
	input_blocks: 	.asciiz "Input the number of cache blocks (powers of 2, max 64): "
	input_bitsize:	.asciiz "Input the number block size (powers of 2, max 64): "

	# Outputs
	access_addr:	.asciiz "Address Access: "
	address:		.asciiz "Address: "
	tag:			.asciiz "Tag: "
	index:			.asciiz "Index: "
	old_tag:		.asciiz "Old tag: "
	miss: 			.asciiz "Result: Miss \n"
	hit: 			.asciiz "Result: Hit \n"

	# Errors
	error_pow:		.asciiz "Error: The value must be powers of 2: \n"
	error_max		.asciiz "Error: The value must not exceed 100. \n"

	# Summary
	sum_total:		.asciiz "Total Access: "
	sum_hits:		.asciiz "Total Hits: "
	sum_misses:		.asciiz "Total Misses: "
	sum_hr:			.asciiz "Hit Rate: "
	percent:		.asciiz "%\n"
	is_empty:		.asciiz "(slot was empty)"

	# Final cache state:

	fin_block:		.asciiz "Block: "
	fin_tag:		.asciiz "Tag: "
	valid:			.asciiz "Valid\n"
	fin_empty:		.asciiz "Empty\n"

	# Others
	endle:			.asciiz "/n"
	space:			.asciiz " "
	colon: 			.asciiz ":"

	#Arrays

	cache_tag:		.space 256		# 64 words x 4 bytes = 256 bytes to store in blocks
	cache_valid:	.space 256		# 64 words x 4 bytes (0 for invalid, 1 for valid)
	addr_array:		.space 400		# 100 words x 4 bytes

.globl main 
.text

main: 

	li $v0, 4
	la $a0, input_blocks
	syscall 

	li $v0, 5
	syscall 
	move $s0, $v0					# $s0 = number of blocks

	# Error handling for blocks

	li $t0, 64
	bgt $s0, $t0, max_err			# $s0 > $t0 goto max error
	li $t0, 1
	blt $s0, $t0, pow_err			# $s0 < $t0 goto power error
	jal check_pow
	beq $v0, $zero pow_err			# $s0 = 0 goto power error

	li $v0, 4
	la $a0, input_blocks
	syscall

	li $v0, 5
	syscall
	move $s1, $v0					# $s1 = block size

	#Error Handling for block size
	li $t0, 64
	bgt $s1, $t0, max_err
	li $t0, 1
	blt $s1, $t0, pow_err
	move $a0, $s1
	jal check_pow
	beq $v0, $zero, pow_err

	# Getting Address

	li $v0, 4
	la $a0, user_naddress
	syscall

	li $v0, 5
	syscall
	move $s2, $v0 					# $s2 = number of addresses

	# clamp to 1 ... 100

	li $t0, 100
	bgt $s2, $t0, max_err			# $s2 > $t0 GOTO max error
	li $v0, 1
	blt $s2, $t0, pow_err

	# Read the address into Array
	la $s7, addr_array				#s7 = base of address array 
	li $t1, 0

read_loop:

	bge $t1, $s2, read_done
	
	# Prints the address by (i)
	li $v0, 4
	la $a0, user_address
	syscall

	addi $a0, $t1, 1				#based 1 display
	li $v0, 1
	syscall

	li $v0, 4
	la $a0, colon
	syscall

	li $v0, 5
	syscall

	# Store in the array 
	sll $t2, $t1, 2					# byte offset = i x 4
	add $t2, $s7, $t2
	sw $v0, 0($t2)

	addi $t1, $t1, 1
	j read_loop

read_done:

	#initialize cache (all valid ofc)
	la $s3, cache_tag
	la $s4, cache_valid
	li $t1, 0
	
init_loop:

	bge $t1, $s0, init_done
	sll $t2, $t1
	add $t3, $s4, $t2
	sw $zero, 0($t3)				# valid[i] = 0
	add $t3, $s4, $t2
	li $t4, -1
	sw $zero, 0($t3)
	addi, $t1, $t1, 1
	j init_loop 

init_done:

	# Reset the counter 

	li $s5, 0						# Hit counter 
	li $s6, 0 						# Miss counter

	#computing the block_size($t8) and number of blocks($t9)

	move $a0, $s1
	jal log2_val
	move $t8, $v0

	move $a0, $s0
	jal log2_val
	move $t9, $v0

	li $t1, 0						# i = 0

sim_loop:

	bge $t1, $s2, fin_sim

	# Loading the address 
	sll $t2, $t1, 2
	add $t2, $s7, $t2
	lw $t0, 0($t2)					# We put the address in $t0

	# Block address($t3) = address >> block size
	srlv $t3, $t0, $t8

	# index = block number % number of blocks = block number & number of blocks
	addi $t4, $s0, -1
	and $t4, $t3, $t4 				# $t4 = index

	# tag = blck number >> number of blocks 
	srlv $t5, $t3, $t9				# $t5 = tag

	# Print access info

	li $v0, 4
	la $a0, access_addr
	syscall 

	addi $a0, $t1, 1
	li $v0, 1
	syscall

	li $v0, 4
	la $a0, address
	syscall

	move $a0, $t0
	li $v0, 1
	syscall

	li $v0, 4
	la $a0, index
	syscall

	move $a0, $t4
	li $v0, 1
	syscall

	li $v0, 4
	la $a0, tag
	syscall

	move $a0, $t5
	li $v0, 1
	syscall

	li $v0, 4
	la $a0, endle
	syscall

	# Check the cache 
	sll $t6, $t4, 2					# Byte offset
	add $t6, $s4, $t6
	lw $t7, 0($t6)					# loading a valid(index)

	beq $t7, $zero, cache_miss

	# check if tag is valid

	sll $t6, $t4, 2
	add $t6, $s3, $t6
	lw $t7, 0($t6)					# loading the tag(index)


	beq $t7, $t5, cache_hit			# if it maches the tag then it is hit
	j cache_miss					# else it is miss

cache_hit:

	addi $s5, $s5, 1 				# increment the hit
	li $v0, 4
	la $a0, hit
	syscall
	j sim_next
cache_miss:

	addi $s6, $s6, 1					# increment the miss

# Update the cache valid[index] = 1, tag[index] = tag

	sll $t6, $t4, 2
	add $t6, $s4, $t6
	li $t7, 1
	sw $t7, 0($t6)

	sll $t6, $t4, 2
	add $t6, $s3, $t6
	sw $t5, 0($t6)

	li $v0, 4
	la $a0, miss
	syscall

sim_next:

	addi, $t1, $t1, 1
	j sim_loop
sim_done:

	# Print the Summary 
	li $v0, 4
	la $a0, sum_total

	li $v0, 4
	la $a0, endle
	syscall 

	li $v0, 4
	la $a0, sum_hits
	syscall 

	move $a0, $s5
	li $v0, 1
	syscall 

	li $v0, 4
	la $a0, endle
	syscall

	li $v0, 4
	la $a0, sum_misses
	syscall

	move $a0, $s6
	li $v0, 1
	syscall

	li $v0, 4
	la $a0, endle
	syscall

	li $v0, 4
	la $a0, sum_hr				
	syscall

	mul $t0, $s5, 100				#Hit rate = (hits x 100) / total
	div $t0, $s2
	mflo #a0
	li $v0, 1
	syscall

	li $v0, 4
	la $a0, percent
	syscall

	# Print the final cache 
	li $t1, 0

print_cache:

	bge $t1, $s0, print_cache_done

	li $v0, 4
	la $a0, fin_block
	syscall 

	move $a0, $t1
	li $v0, 1
	syscall 

	li $v0, 4
	la $a0, fin_tag
	syscall

	sll $t2, $t1, 2
	add $t3, $s3, $t2
	lw $a0, 0($t3)						# Tag value
	li $v0, 1
	syscall 

	sll $t2, $t1, 2
	add $t3, $s4, $t2
	lw $t4, 0($t3)						#Valid 

	beq $t4, $zero, print_empty 

	li $v0, 4
	la $a0, valid
	syscall

	j print_next_block

print_empty:

	li $v0, 4
	la $a0, fin_empty
	syscall

print_next_block:

	addi $t1, $t1, 1
	j print_cache

print_cache_done:

	li $v0, 4
	la $a0, endle
	syscall 

	li $v0, 10							#Exit the program
	syscall


# Error strings
pow_err:

	li $v0, 4
	la $a0, error_pow
	syscall 
	j main
max_err:

	li $v0, 4
	la $a0, error_max
	syscall 
	j main

# Check if the powers of 2

check_pow:

	blez $a0, cp2_fail					# <= 0 is not valid
	addi $t0, $a0, -1
	and $t0, $a0, $t0
	bne $t0, $zero, cp2_fail
	li $v0, 1
	jr $ra
cp2_fail:

	li $v0, 0
	jr $ra

# check for log2_val

log2_val:

	li $v0, 0
	move $t0, $a0
log2_loop:

	ble $t0, 1, log2_done 
	srl $t0, $t0, 1
	addi $v0, $v0, 1
	j log2_loop

log2_done:
	jr $ra
	








	
