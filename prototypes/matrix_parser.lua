-- By Ellis W.R. Sutko
-- 03/05/2019
-- version 2

--[[
 this script is a proof of concept for parsing
 a text representation of a matrix.
 the 2x2 matrix:
 a b
 c d
 can would be represented as:
 a,b;c,d;
 or:
 [a, b; c, d]
--]]

-- creates a table with feilds
-- row and col
function new_matrix ()
   return {row = 0, col = 0}
end

-- gets the value at mtx[i, j]
-- assuming i in [1, row]
-- and j in [1, col]
function at(mtx, i, j)
  return mtx[mtx.col * (i - 1) + (j - 1)]
end

-- procedure to be run after finishing parsing a sequenc of digits
function endnum ()
  local num = (negative and -1 or 1) * tonumber(text)
  matrix[matrix.col * row + col] = num

  col += 1
  text = ""
  negative = false
end

-- procedure to run after parsing a row of numbers
function endrow ()
  endnum()

  if matrix.col == 0 then
    matrix.col = col
  elseif matrix.col ~= col then
     error("invalid matrix")
  end

  col = 0
  row += 1
end

-- start of the program body

matrix = new_matrix()
row = 0
col = 0
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
    if row ~= 0 then
      endrow()
    end
  elseif asc >= 48 and asc <= 57 then
    text = text .. char
  elseif asc == 0   then
    matrix.row = row
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
for r=1, matrix.row  do
  local line = "  {"
  for c=1, matrix.col do
    line = line .. at(matrix, r, c)  .. ", "
  end
  line = string.sub(line, 1, -3) .. "},"
  print(line)
end
print("}")
