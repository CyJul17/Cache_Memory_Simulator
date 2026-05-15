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
	fin_Tag			.asciiz "Tag: "
	valid:			.asciiz "Valid\n"
	fin_empty:			.asciiz "Empty\n"

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
	
