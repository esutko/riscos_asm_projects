 REM >$.public.code.asm.gcd
 REM finds the GCD of two numbers
 :
 DIM code% 256
 DIM input 16
 FOR pass = 0 TO 3 STEP 3
   P% = code%
   [
     OPT pass
     .start
     ; R12, first number
     ; R11, second number
     ; R10,  remainder
     STMEA SP!, {LR}
     BL getnum
     MOV R12, R0
     BL getnum
     MOV R11, R0
     ;ensure the larger number is in R12
     CMP R12, R11
     MOVLS R9, R11
     MOVLS R11, R12
     MOVLS R12, R9
     BL gcd
     ; convert gcd to str
     ADR R1, input
     MOV R2, #16
     SWI "OS_BinaryToDecimal"
     ; output the gcd
     MOV R0, R1
     MOV R1, #16
     SWI "OS_WriteN"
     LDMEA SP!, {LR}
     MOV PC, LR
     ;
     ; takes two positive integers in R11 & R12
     ; returns their GCD in R0
     .gcd
     STMEA SP!, {LR}
     .gcd_loop
     BL rem
     MOV R12, R11
     MOVS R11, R10
     BNE gcd_loop
     MOV R0, R12
     LDMEA SP!, {LR}
     MOV PC, LR
     ;
     ; accepts positive integers in R12 & R11
     ; returns their GCD in R10
     .rem
     MOV R10, R12
     .remloop
     SUB R10, R10, R11
     CMP R10, R11
     BGE remloop
     MOV PC, LR
     ;
     ; takes no inputs
     ; returns a user generated number in R0
     ; uses R9 to itterate over str buffer
     ; uses R8 to store 0
     .getnum
     ; prompt user for a number
     SWI "OS_WriteS"
     EQUS "Enter a number: "
     EQUB 0
     ALIGN
     ; get user response
     ADR R0, input
     MOV R1, #16
     MOV R2, #48
     MOV R3, #57
     SWI "OS_ReadLine"
     ; save start of str
     MOV R9, R0
     ; convert str to int
     MOV R1, R0
     MOV R0, #10
     SWI "OS_ReadUnsigned"
     MOV R0, R2
     ; fill str buffer w/ 0s
     MOV R8, #0
     .write_loop
     STR R8, [R9], #4
     CMP R9, R1
     BLT write_loop
     MOV PC, LR
   ]
 NEXT
 CALL start
