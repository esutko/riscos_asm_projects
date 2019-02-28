-- By Ellis W.R. Sutko
-- 02/28/2018

--[[
 this script is a proof of concept for parsing
 a text representation of a matrix.
 the 2x2 matrix:
 a b
 c d
 can would be represented as:
 a,b;c,d;
 [a, b; c, d]
--]]

-- creates a table with the feild 'head'.
-- 'head' is the index of the next empty
-- in the stack.
function new_stack ()
   return {head = 1}
end

-- pushes 'val' onto 'stack' and increments 'head'
function push (stack, val)
  stack[stack.head] = val
  stack.head += 1
end

-- procedure to be run after finishing parsing a sequenc of digits
function endnum ()
  local num = (negative and -1 or 1) * tonumber(text)
  push(row, num)

  text = ""
  negative = false
end

-- procedure to run after parsing a row of numbers
function endrow ()
  endnum()
  push(matrix, row)
  row = new_stack()
end

-- start of the program body

matrix = new_stack()
row = new_stack()
text = ""
negative = false

--get user input
print("enter a matrix")
str = io.read() .. string.char(0)

--main loop
while true do
   local char = string.sub(str, 1, 1)
   local asc = string.byte(char)

   if char == "-" then
     negative = true
   elseif char == "," then
     endnum()
   elseif char == ";" then
     endrow()
   elseif char == " " or char == "[" then
     --skip
   elseif char == "]" then
     if row.head ~= 1 then
       endrow()
     end
   elseif asc >= 48 and asc <= 57 then
     text = text .. char
   elseif asc == 0   then
     break
   else
     error("invalid matrix")
   end

  str = string.sub(str, 2)
end

-- print the matrix back formatted as a table
-- to show correctness.

print("------")

print("{")
for r=1, matrix.head-1  do
  local row = matrix[r]
  local line = "  {"
  for c=1, row.head-1 do
    line = line .. row[c] .. ", "
  end
  line = string.sub(line, 1, -3) .. "},"
  print(line)
end
print("}")
