.data
source:
.word 0,1,2,3,4,5,6,7,8,9,10,-1,-2,-3,-4,-5,-6,-7,-8,-9,-10,0,0,0
destiny:
.space 300
.text
main:
la $7, source
addi $2, $0, 10
la $3, destiny
label: 
sw $31, 0($3)
lw $4, 0($7)
lw $5, 4($7)
add $6, $4, $5
sw $6, 4($3)
sub $6, $4, $5
sw $6, 8($3)
xor $6, $4, 1
sw $6 12($3)
addi $7, $7, 8
addi $3, $3, 16
addi $2, $2, -1
beq $2, $0, out
jal label 
out:
ori $2, $0, 10
syscall
