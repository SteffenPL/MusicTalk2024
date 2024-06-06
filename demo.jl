using PortMidi
include("utils.jl")

Pm_Initialize()

for i in 0:Pm_CountDevices()-1
    info = unsafe_load(Pm_GetDeviceInfo(i))
    println(i, ": ", info.output > 0 ? "[Output ] " : "[Input] ", unsafe_string(info.name), " (", unsafe_string(info.interf), ")")
end

id = 3

# 2. Open device 
const stream = OpenOutput("") Ref{Ptr{PortMidi.PortMidiStream}}(C_NULL)
Pm_OpenOutput(stream, id, C_NULL, 0, C_NULL, C_NULL, 0)
# don't forget to call later: Pm_Close(stream[])

# 3. Send MIDI messages 
Note_ON = 0x90
Note_OFF = 0x80
C4 = 60

function play_note(stream, note, velocity, duration,chn = 1)
    @assert 0 < chn <= 16
    Pm_WriteShort(stream[], 0, Pm_Message(0x90 + chn - 1, note, velocity))
    sleep(duration)
    Pm_WriteShort(stream[], 0, Pm_Message(0x80 + chn - 1, note, velocity))
end

# @async play_note(stream, C4 + rand([-5,-2,0,2,5]), rand(80:120), 1.0 + 0.05*rand(), 1)

# # make a random tune...
# for i in 1:12
#     @async play_note(stream, C4 + rand([-5,-2,0,2,5]), rand(80:120), 0.15 + 0.05*rand())
#     sleep(0.15)
#     @async play_note(stream, C4, rand(80:120), 0.15 + 0.05*rand())
#     sleep(0.3 + 0.05*rand())
# end

function rep(stream, root)
    dur = 0.19 + 0.005*randn()
    @async play_note(stream, root[] + rand([-7,-5,0,3,5,12]), rand(60:70), dur + 0.05*rand())
    sleep(dur)
    @async play_note(stream, root[] + rand([-12,12]), rand(50:90), dur + 0.05*rand())
    sleep(dur)
    Base.invokelatest(rep, stream, root)
end

root = Ref(C4)

rep(stream, C4) = nothing
@async rep(stream, root)


play_note(stream, 48, 70, 1.0, 1)


@async play_note(stream, C4 - 12 * 2, rand(80:120), 1.0 + 0.05*rand())

macro pa(note, vel, dur)
    return :(@async play_note(stream, $note, $vel, $dur) )
end

time()


beat = 120.0

function rep(t = now())
    sleep(max(0.0, t - time())) # wait until the function should start

    @pa C4 120 1.0

    Base.invokelatest(rep, t + 1.0)
end

rep(1.0)



# 4. Close device
Pm_Close(stream[])

















### instruments

# drum 
BD = 1   # bass drum 
SD = 2   # snare drum 
CLP = 3  # clap 
HH1 = 4  # hi hat 1 
HH2 = 5  # hi hat 2 
HHO = 6  # hi hat open 
CY1 = 7  # cymbal 1 
CY2 = 8  # cymbal 2 
PT1 = 9  # tam/percussions

Kick  = 1
Snare = 2 
Tom1  = 3
Tom2  = 4 
Rim   = 5
Clap  = 6
CHat  = 7
OHat  = 8
Crash = 9
Ride  = 10

macro drum(vel, note)
    return :(play_drum(stream,$note, $vel))
end

play_drum(stream, note, vel, chn = 10) = play_note(stream, C4 - 1 + note, vel, 0.0, chn)

@play beat -> @drum BD [1 0 0 0]


for i in 1:80
    k = (i % 2 == 0) ? Kick : rand((Snare, Clap, CHat))
    play_drum(stream, k, 120)
    sleep(0.5)
end
