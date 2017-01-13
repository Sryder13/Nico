local M = {}

local function fileToWords(file)
	file:seek("set")
	local data = file:read("*all")

	local words = {}
	for word in string.gmatch(data, "([^%s]+)") do
		table.insert(words, word)
	end
	return words
end

local function prefix(w1, w2, w3)
	return w1 .. " " .. w2 .. " " .. w3
end

local function stateTabInsert(statetab, index, value)
	if not statetab[index] then
		statetab[index] = {n=0}
	end
	table.insert(statetab[index], value)
end

function M.generateText(fileName, size)
	-- fileName should be the file name, size should be the message size
	local file = io.open(fileName, "r")

	if not file then
		return nil
	else
		local text = ""
		local words = fileToWords(file)
		file:close()

		local statetab = {}
		local NOWORD = "\n"
		local w1, w2, w3 = NOWORD, NOWORD, NOWORD
		local word
		for i=1,#words,1 do
			word = words[i]
			stateTabInsert(statetab, prefix(w1, w2, w3), word)
			w1 = w2
			w2 = w3
			w3 = word
		end
		stateTabInsert(statetab, prefix(w1, w2, w3), NOWORD)
		
		w1 = NOWORD
		w2 = NOWORD
		w3 = NOWORD

		local statetabSize = 0
		for _,_ in pairs(statetab) do
			statetabSize = statetabSize + 1
		end

		local startR = math.random(statetabSize)
		local i = 1
		for k,_ in pairs(statetab) do
			if i == startR then
				w1, w2, w3 = string.match(k, "(%g+) (%g+) (%g+)")
				break
			end
			i = i + 1
		end

		for i=1,size,1 do
			local list = statetab[prefix(w1, w2, w3)]
			local r = math.random(table.getn(list))
			local nextword = list[r]
			if nextword == NOWORD then
				break
			end
			text = text .. nextword .. " "
			w1 = w2
			w2 = w3
			w3 = nextword
		end
		
		return text
	end
end

return M
