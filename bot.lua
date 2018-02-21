local discordia = require("discordia")
local client = discordia.Client {
	cacheAllMembers = true,
}

local markov = require("markov")

-- secret.lua should contain "return {token = "TOKEN"}"
local secrets = require("secret")


---------- NEEDED STUFF ----------

local version = "v0.10.0"

local helptext = [[I am a Discord bot written in Lua!

My commands are:
```
&help - displays this text
&info - display bot info
&source - show a link to my source
&whoami - displays your user info
&whois - displays another user's info
&randomuser - gives you a random user of the current server
&say - say something in the channel
&sayy - say something a e s t h e t i c a l l y
&roll <x>d<y> - roll x number of y sided dice
&markov [<user>] - generate markov chain over chat history for you or another user
&die - stop the bot*

* can only be run by bot admins
```]]

local botAdmins = {["127036555159273472"] = true, ["116883900688629761"] = true}


---------- FUNCTIONS ----------

local function die()
	-- I don't think there's a way to instantly have it log out with this...
	-- So this'll set it to be Idle while it's dead
	client:setStatus("idle")
	client:stop(true)
end

local function simpleDiscordTime(timeString)
	return string.match(timeString, "(%d+%-%d+%-%d+)") .. " "
	.. string.match(timeString, "%d+%-%d+%-%d+T(%d+:%d+:%d+)")
end


---------- COMMANDS ----------

local function commandHelp(message)
	message.channel:send(helptext)
end

local function isBotAdmin(user)
	return botAdmins[user.id]
end

local function commandInfo(message)
	local i = 0;
	local text = "I am Nico, a Discord bot written by " .. client.owner.name .. [[

I am version: ]] .. version

	if message.guild then
		text = text .. "\nMy admins in this server are: "
		for user in message.guild.members:findAll(isBotAdmin) do
			if i > 0 then
				text = text .. ", "
			end
			text = text .. user.name .. " (" .. user.username .. "#" .. user.discriminator .. ")"
			i = i + 1
		end
	end
	message.channel:send(text)
end

local function commandSource(message)
	message.channel:send("My source is located at: <https://github.com/Sryder13/Nico>")
end

local function commandWhoIs(message)
	local command, arg = string.match(message.content, "(%g+) (.+)")
	if commnd then
		command = string.lower(command)
	end
	local checkUser

	if command == "&whoami" or not arg or not message.guild then
		checkUser = message.author
	end

	if not checkUser then -- we aren't just using the author so go through guild
		for user in message.guild.members:iter() do
			if user.username == arg or user.name == arg then
				checkUser = user
				break
			end
		end
	end
	if checkUser then -- found them, print the info
		local text = "User: `" .. checkUser.username .. "#" .. checkUser.discriminator .. "`\n"
		.. "ID: `"  .. checkUser.id .. "`\n"
		.. "Account Created: `" .. simpleDiscordTime(checkUser.timestamp) .. "`"
		message.channel:send(text)
		return
	end

	message.channel:send("I can't find " .. arg)
end

local function commandRandomUser(message)
	local text = "Your random user is: "
	if not message.channel.guild then
		message.channel:send("This does not work for PM's silly.")
		return
	end
	local userNum = math.random(message.channel.guild.totalMemberCount)-1
	local i = 0
	for user in message.guild.members:iter() do
		if i == userNum then
			text = text .. user.name
			break
		end
		i = i + 1
	end

	message.channel:send(text)
end

local function commandSay(message)
	local command, text = string.match(message.content, "(%g+) (.+)")
	if string.lower(command) == "&sayy" then
		text = string.gsub(text, "(.)", "%1 ")
	end

	if message.guild then
		message:delete()
	end
	message.channel:send(text)
end

local function commandRoll(message)
	local num, sides
	num, sides = string.match(message.content, "%g+ (%d+)d(%d+)")
	-- convert them to numbers
	num = tonumber(num)
	sides = tonumber(sides)
	if not num or not sides or sides <= 0 then
		message.channel:send("You did something wrong")
		return
	end

	-- It just adds up and formats the output text
	local die
	local text = "Rolling " .. num .. " " .. sides .. " sided dice:\n"
	local total = 0
	for i = 0, num-1, 1 do
		die = math.random(sides)
		if num > 1 and num <= 20 then
			if i > 0 then
				text = text .. " + "
			end
			text = text .. die
		end
		total = total + die
	end
	if num > 1 and num <= 20 then
		text = text .. " = " .. total
	else
		text = text .. "Result is: " .. total
	end
	message.channel:send(text)
end

local function commandMarkov(message)
	if not message.channel.guild then
		message.channel:send("This does not work for PM's silly.")
		return
	end

	-- arg is the name that was sent in
	-- target is the server ID + "-" + user ID
	local arg = string.match(message.content, "%g+ (.+)")
	local target
	local file

	if arg == "Nico" then
		message.channel:send("I would not do this here or there.")
		return
	elseif arg == "" then
		target = message.guild.id .. "-" .. message.author.id
	else
		for user in message.guild.members:iter() do
			if user.username == arg or user.name == arg then
				target = message.guild.id .. "-" .. user.id
				break
			end
		end
		if not target then
			message.channel:send("I can't find this user.")
			return
		end
	end

	local rSize = math.random(20, 30)
	local markovText = markov.generateText("./markovs/" .. target, rSize)

	if markovText and markovText ~= "" then
		message.channel:send(markovText)
	else
		message.channel:send("I have not seen this person say anything yet.")
	end
end

local function commandDie(message)
	if not botAdmins[message.author.id] then
		message.channel:send("You do not have permission to do this")
		return
	end
	message.channel:send("Leaving on Command")
	die()
end


---------- EVENTS ----------

local commands = {	["&help"] = commandHelp, 
			["&info"] = commandInfo,
			["&source"] = commandSource,
			["&whoami"] = commandWhoIs, -- It's an alias
			["&whois"] = commandWhoIs,
			["&randomuser"] = commandRandomUser,
			["&say"] = commandSay,
			["&sayy"] = commandSay, -- alias
			["&roll"] = commandRoll,
			["&markov"] = commandMarkov,
			["&die"] = commandDie}

local function messageGrabs(message)
	-- Don't do any of this for yourself
	if message.author == client.user then
		return
	end

	-- Okay, this is a little confusing, basically the above table stores function names
	-- with the user input to run it as a key, we just check that they key exists and run
	-- the function for it directly
	local command = string.match(message.content, "%g+") -- get all characters up to the space

	if command then
		command = string.lower(command)
	end

	if commands[command] then
		message.channel:broadcastTyping()
		commands[command](message)
	else
		-- Log user messages for the markov chains, stored by server and id
		local file = assert(io.open("./markovs/" .. message.guild.id .. "-" .. message.author.id, "a"))
		local addText = string.gsub(message.content, "`+.+`+", " ")
		file:write("\n" .. addText)
		file:close()
	end

	if string.find(string.lower(message.content), "%f[%w]nico%f[^%w]") then
		message:addReaction("\xF0\x9F\x98\x98")
	end
end

local function startup()
	-- Set the bot to be online
	client:setStatus("online")
	-- Go to the dev bot channel and tell us you're alive
	local homeServer = client.guilds:get("116884620032606215")
	local devChannel = homeServer.textChannels:get("202806212599873536")
	devChannel:send("All wound up and ready to go.")
	-- Set "game playing" to version number
	client:setGame(version)
end

client:on("ready", startup) -- event for first joining
client:on("messageCreate", messageGrabs) -- event that is run on message arriving

client:on("warning", print) -- print warnings for me


-- Actually run
client:run(secrets.token)


