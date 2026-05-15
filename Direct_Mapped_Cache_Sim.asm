.data 
	# User inputs
	user_input: .asciiz "Input the number of address: "
	input_Tag: .asciiz "Input the number o b in f 2^b: "
	input_Offset: .asciiz "Input the number of n in 2^n: "
	# Outputs
	miss: .asciiz "Result: Miss \n"
	hit: .asciiz "Result: Hit \n"
	# Arrays
	
.globl main 
.text