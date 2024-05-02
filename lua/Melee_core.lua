local c = {}

local maxint = 2^32
local rngIterationConstants = {
{214013, 2531011},
{2851891209, 505908858},
{3724496977, 159719620},
{4103125409, 2115878600},
{1136269121, 1043415696},
{3532701313, 2186156320},
{2195963137, 2219737664},
{3209722369, 4253435008},
{4173657089, 3752954112},
{2048518145, 3656847872},
{376688641, 1581130752},
{3051855873, 1706838016},
{2412724225, 1886949376},
{2946400257, 1961959424},
{2671575041, 971128832},
{1048182785, 3015999488},
{2096365569, 1737031680},
{4192731137, 3474063360},
{4090494977, 2653159424},
{3886022657, 1011351552},
{3477078017, 2022703104},
{2659188737, 4045406208},
{1023410177, 3795845120},
{2046820353, 3296722944},
{4093640705, 2298478592},
{3892314113, 301989888},
{3489660929, 603979776},
{2684354561, 1207959552},
{1073741825, 2415919104},
{2147483649, 536870912},
{1, 1073741824},
{1, 2147483648}}

local seedIndex = 0
local seed = 0
local function advance_linear(a, b, s)
local stepSize = 1
local fileTag = "default"

    return (a * s + b) & (maxint - 1)
end

c.advance_linear = advance_linear

local function advance_star(s, iterations)
    seed = s
    i = 1
    for j = 1, 32 do
        if (iterations & i) ~= 0 then
            seed = advance_linear(rngIterationConstants[j][1], rngIterationConstants[j][2], seed)
        end
        i = i<<1
    end
    return seed
end
c.advance_star = advance_star

local function findProgress(progressFile, path)
    continueFrom = progressFile:read("*number")
    if continueFrom == nil then
        return -1
    else
       nextIndexes = {}
       i = 0
       seedIndex = progressFile:read("*number")
       while seedIndex ~= nil do
          i = i + 1
          nextIndexes[i] = seedIndex
          seedIndex = progressFile:read("*number")
       end
       progressFile:close()
       progressFile = io.open(path, "w")
       
       for j = 1, i do
           progressFile:write(nextIndexes[j], "\n")
       end
       progressFile:close()
    end
    
    return continueFrom
end

local function rngSequencerInitiate(baseLength, stepLength, tag)
   
   fileTag = tag
   --progPath = "/scriptdata/" .. tag .. "/progress.txt"
   progPath = tag .. "prog.txt"
   progressFile = io.open(progPath, "r")
   --currBasePath = "/scriptdata/" .. tag .. "/base.txt"
   currBasePath = tag .. "base.txt"
   baseFile = io.open(currBasePath, "r")
   stepSize = stepLength

   if baseFile == nil then

       baseFile = io.open(currBasePath, "w")
       baseFile:write(baseLength)
       baseFile:close()

   elseif progressFile == nil then
       seedIndex = baseFile:read("*number")
       baseFile:close()
       seed = advance_star(0, seedIndex)
       baseFile = io.open(currBasePath, "w")      
       baseFile:write(seedIndex + baseLength)
       baseFile:close()

   else
       continueFrom = findProgress(progressFile, progPath)
       if continueFrom == -1 then
           seedIndex = baseFile:read("*number")
           baseFile:close()
           seed = advance_star(0, seedIndex)
           baseFile = io.open(currBasePath, "w")      
           baseFile:write(seedIndex + baseLength)
           baseFile:close()

       else
          seedIndex = continueFrom + stepLength
          seed = advance_star(0, seedIndex)
          baseFile:close()         
       end
   end
end

c.rngSequencerInitiate = rngSequencerInitiate

local function saveProgress()
    --path = "/scriptdata/" .. fileTag .. "/progress.txt" 
    path = fileTag .. "prog.txt"
    progressFile = io.open(path, "a")
    progressFile:write(seedIndex, "\n")
    progressFile:close()

end

c.saveProgress = saveProgress    

local function getNextSeed()

    seedIndex = seedIndex + stepSize
    curr = seed
    seed = advance_star(seed, stepSize)
    
    return curr    
end

c.getNextSeed = getNextSeed

local function getSeedIndex()
    return seedIndex - stepSize
end

c.getSeedIndex = getSeedIndex

-- frame timing functions
-- call timerUpdate() on script update
-- call timerRestart() when you load state or start
-- timerCurrentFrame() returns current in progress or completed frame
-- timerNextInput() tells which frame the inputs made in script update will happen
-- timerFrameComplete() returns true if current frame was just completed, and gamedata will correspond to current frame num

local bufferAddress = 0x804C1F7B
local bufferSlotAddress = 0x804C1F7A
local engineStartAddr = 0x804D76FC
local engineStartTime = 0
local cpuTime = 0x80407218
local currentFrame = 0
local frameComplete = false
local restarted = true
local nextInputFrame = 0
local inputsBuffered = 0
local currBufferSlot = 0
local completeCounter = 0

local function timerRestart()
    
     currentFrame = ReadValue32(0x80479D60)
     engineStartTime = ReadValue32(engineStartAddr)
     inputsBuffered = ReadValue8(bufferAddress)
     currBufferSlot = currBufferSlot
     frameComplete = false
     nextInputFrame = currentFrame + 1 + inputsBuffered
     restarted = true
     completeCounter = 0
end

c.timerRestart = timerRestart

local function timerUpdate()
    frame = ReadValue32(0x80479D60)
    
    if frame ~= currentFrame then
        completeCounter = 0
    end    
    
    currentFrame = frame
    inputsBuffered = ReadValue8(bufferAddress)
    slot = ReadValue8(bufferSlotAddress)
    originalslot = currBufferSlot
    updatedEngineTime = ReadValue32(engineStartAddr)
    frameCalcTime = ReadValue32(cpuTime)

    if currentFrame == 2 and not restarted then
        timerRestart()
    else

        if (updatedEngineTime ~= engineStartTime) and (frameCalcTime == 0) then
            frameComplete = false
            completeCounter = 0
        else
            frameComplete = true
            completeCounter = completeCounter + 1
        end

        engineStartTime = updatedEngineTime

        if restarted then
           if frameComplete then
               currBufferSlot = slot
               restarted = false
           end
           nextInputFrame = currentFrame + 1 + inputsBuffered
        else
           slotDifference = 0
           while slot ~= currBufferSlot do         
               currBufferSlot = (currBufferSlot + 1) % 5
               slotDifference = slotDifference + 1
           end

           nextInputFrame = nextInputFrame + slotDifference           
        end
    end
end	

c.timerUpdate = timerUpdate

local function timerNextInput()
    return nextInputFrame - 84
end

c.timerNextInput = timerNextInput

local function timerFrameComplete()
    return frameComplete
end
c.timerFrameComplete = timerFrameComplete

local function timerCompleteCounter()
    return completeCounter
end

c.timerCompleteCounter = timerCompleteCounter


local function timerCurrentFrame()
    return currentFrame - 84
end

c.timerCurrentFrame = timerCurrentFrame

--frame timing functions end

local function left()
    SetMainStickX(0)
    SetMainStickY(128)
end
c.left = left

local function verifyAddress(address)

    lbound = 1<<31
    ubound = 124<<24

    return ((address&lbound) ~= 0) and ((address&ubound) == 0)
end

c.verifyAddress = verifyAddress

local function player2data()

    address = ReadValue32(0x80453FC0) + 44
    ret = -1
    if verifyAddress(address) then
        ret = ReadValue32(address)
    end
    return ret 
 end

c.player2data = player2data

local function loadSeedFile(seedPath)
    seeds = {}
    seedFile = io.open(seedPath, "r")
    io.input(seedPath)
    s = io.read("*number")
    i = 1
    while s ~= nil do
        seeds[i] = s
        s = io.read("*number")
        i = i+1
    end
    io.input():close()
    return seeds
end

c.loadSeedFile = loadSeedFile
    
local function right()
    SetMainStickX(255)
    SetMainStickY(128)
end
c.right = right

local function up()
    SetMainStickX(128)
    SetMainStickY(255)
end
c.up = up

local function down()
    SetMainStickX(128)
    SetMainStickY(0)
end
c.down = down

local function downLeft()
    SetMainStickX(0)
    SetMainStickY(0)
end
c.downLeft = downLeft

local function stick(X, Y)
    SetMainStickX(X)
    SetMainStickY(Y)
end
c.stick = stick

local function press(Button)
    PressButton(Button, 0)
end
c.press = press

local function seedAdvanceIntermediate(seed)
    return (1077635517 * seed + 1562443379)&(maxint-1)
end

c.seedAdvanceIntermediate = seedAdvanceIntermediate

local function seedAdvanceLarge(seed)
    return (338071361 * seed + 3054200976)&(maxint-1)
end

c.seedAdvanceLarge = seedAdvanceLarge

local function initiateSeedIndex(progresspath)
    local seedfile = io.open(progresspath, "r")
		
    if seedfile == nil then
        seedindex = 0
    
    else         
    io.input(seedfile)
    seedindex = io.read("*number")
    end
    io.input():close()
    local seedw = io.open(progresspath, "w")
    io.output(seedw)
    io.write(seedindex+1)
    io.output():close()

    return seedindex
end

c.initiateSeedIndex = initiateSeedIndex
return c