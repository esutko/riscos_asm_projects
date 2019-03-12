 REM >$.public.code.asm.matrix_parser
 :
 REM by Ellis W.R. Sutko
 REM 03/11/2019
 :
 REM parses a text input into a matrix data structure.
 REM the program assumes elements are positive or negative integers.
 REM the 2 x 2 matrix:
 REM w x
 REM y z
 REM could be written as:
 REM [w, x; y, z]
 REM or:
 REM w,x;y,z;
 :
 DIM code% 768
 DIM elems 64
 DIM io 64
 DIM buffer 16
 DIM matrix 12
 :
 FOR pass = 0 TO 3 STEP 3
   P% = code%
   [
     OPT pass
     .start
     STMEA SP!, {LR}
     ; registers
     ; R12 matrix pointer
     ; R11 rows
     ; R10 colums
     ; R9  io
     ;
     ; set initial values
     ADR R12, matrix
     MOV R11, #0
     MOV R10, #0
     ADR R9, io
     ; setup matrix values
     ADR R0, elems
     STR R0, [R12]
     MOV R0, #0
     STR R0, [R12, #4]
     STR R0, [R12, #8]
     ; prompt user
     SWI "OS_WriteS"
     EQUS "Enter a matrix: "
     EQUB 0
     ALIGN
     ; get input
     MOV R0, R9
     MOV R1, #63
     MOV R2, #0
     MOV R3, #127
     SWI "OS_ReadLine"
     ; parse
     BL parse_matrix
     BL output_matrix
     LDMEA SP!, {LR}
     MOV PC, LR
     ;
     ; === parse_matrix ===
     ; takes an empty matrix in R12
     ; takes a matrix string in R9
     ; on exit the matrix has the values of the matrix string.
     .parse_matrix
     STMEA SP!, {LR}
     ; set up local values
     ; R8 buffer
     ; R7 negative
     ; R6 char
     ADR R8, buffer
     MOV R7, #0
     .parse_loop
     LDRB R6, [R9], #1
     ; begin cases
     CMP R6, #ASC("-")
     MOVEQ R7, #1
     BEQ parse_loop
     CMP R6, #ASC(",")
     BLEQ endnum
     BEQ parse_loop
     CMP R6, #ASC(";")
     BLEQ endrow
     BEQ parse_loop
     CMP R6, #ASC(" ")
     BEQ parse_loop
     CMP R6, #ASC("[")
     BEQ parse_loop
     CMP R6, #ASC("]")
     ; if row does not equal zero then call end row
     BNE next_case
     CMP R10, #0
     BLNE endrow
     BAL parse_loop
     .next_case
     CMP R6, #0
     STREQ R11, [R12, #4]
     BEQ break
     ; default case
     STMEA R8!, {R6}
     BAL parse_loop
     .break
     LDMEA SP!, {LR}
     MOV PC, LR
     ;
     ; === output_matrix ===
     ; takes a matrix in R12
     ; outputs the matrix to the console
     .output_matrix
     STMEA SP!, {LR}
     ; set values
     MOV R11, #0
     MOV R10, #0
     ADR R9, io
     ADR R8, buffer
     .str_loop
     BL clear_buffer
     ADR R8, buffer
     ; get next element
     BL get
     LDR R0, [R0]
     ; deal with negatives
     CMP R0, #0
     BGE positive
     RSB R0, R0, #0
     MOV R7, #ASC("-")
     STRB R7, [R9], #1
     .positive
     ; convert element to str
     ADR R1, buffer
     MOV R2, #16
     SWI "OS_BinaryToDecimal"
     .char_loop
     LDRB R7, [R8], #1
     CMP R7, #0
     MOVEQ R7, #ASC(" ")
     STRB R7, [R9], #1
     BNE char_loop
     ; itterate col
     ADD R10, R10, #1
     ; compare col and col length
     LDR R0, [R12, #8]
     CMP R10, R0
     BNE str_loop
     MOV R7, #10 ; newline
     STRB R7, [R9], #1
     ; adjust values
     ADD R11, R11, #1
     MOV R10, #0
     ; compare row & row length
     LDR R0, [R12, #4]
     CMP R11, R0
     BNE str_loop
     MOV R7, #0 ; terminate str
     STRB R7, [R9], #1
     ; output str
     ADR R0, io
     SWI "OS_Write0"
     LDMEA SP!, {LR}
     MOV PC, LR
     ;
     ; === endnum ===
     ; takes a matrix in R12
     ; takes row in R11 and col in R10
     ; takes buffer in R8
     ; takes negative in R9
     .endnum
     STMEA SP!, {LR}
     ; convert buffer to num
     MOV R0, #10
     ADR R1, buffer
     SWI "OS_ReadUnsigned"
     ; if negative set sign
     CMP R7, #0
     RSBNE R2, R2, #0
     ; store num in memory
     BL get
     STR R2, [R0]
     ; adjust values
     ADD R10, R10, #1
     ADR R8, buffer
     MOV R7, #0
     ; reset buffer
     BL clear_buffer
     LDMEA SP!, {LR}
     MOV PC, LR
     ;
     ; === endrow ===
     ; takes a matrix in R12
     ; takes row in R11 and col in R10
     ; takes buffer in R8
     ; takes negative in R9
     .endrow
     STMEA SP!, {LR}
     BL endnum
     ; save colum value
     STR R10, [R12, #8]
     ; adjust values
     ADD R11, R11, #1
     MOV R10, #0
     LDMEA SP!, {LR}
     MOV PC, LR
     ;
     ; === get ===
     ; takes a pointer to a matrix in R12
     ; takes the row in R11
     ; takes the colums in R10
     ; outputs the location in memory in R0
     .get
     LDR R6, [R12, #8] ; get number of colums
     MLA R0, R6, R11, R10 ; offset = cols * row + col
     MOV R6, #4
     MUL R0, R6, R0 ; multiply offset by size of integer
     LDR R6, [R12] ; get start of matrix
     ADD R0, R0, R6
     MOV PC, LR
     ;
     ; === clear_buffer ===
     ; fills buffer w/ 0s
     .clear_buffer
     ADR R6, buffer
     MOV R5, #16
     MOV R4, #0
     .clear_loop
     STRB R4, [R6], #1
     SUBS R5, R5, #1
     BNE clear_loop
     MOV PC, LR
   ]
 NEXT
