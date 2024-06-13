using PortMidi
include("utils.jl")
Pm_Initialize()
stream = OpenOutput("loopMIDI Port")

const A3 = 57
const C4 = 60

# time keeping
metro = Metronome(bpm = 120.0)

# basic math function
Base.cos(metro, t, period = 1.0) = cos(2pi * t / bps(metro) / period)

root = Ref(C4)
root[] = 52

# lefthand(stream, metro, root, i) = nothing 
function lefthand(stream, metro, root, i)
    if i % 8 == 0 
        root[] = rand(setdiff([48,50,52],root[]))
    end

    notes = 52 .+ (3,3,5,7)
    dur = 1/2
    
    @async play_note(stream, metro, notes[mod(i,eachindex(notes))], rand(60:90), dur)
    sleep(until(metro, dur))
    
    @async play_note(stream, metro, root[], rand(50:80), dur)
    sleep(until(metro, dur))
    Base.@invokelatest lefthand(stream, metro, root, i + 1)
end

@masync metro lefthand(stream, metro, root, 1)

aeolian = (0,2,3,5,7,8,9,12)
major   = (0,2,4,5,7,9,11,12)

# righthand(stream, metro, root) = nothing
function righthand(stream, metro, root) 
    dur = 1/4 #  rand([1/2, 1/4, 1/2, 1/2, 1/2])

    t = time() 

    note = 52 + 12 + (12 + 3 * cos(metro, t, 3/7)) * cos(metro, t, 2)
    note = quantize(60, major, note)

    vel = 80 + 20 * cos(metro, t, 3/7)

    @async play_note(stream, metro, note, vel, dur, 2) 
    sleep(until(metro, dur))

    # @show vel
    
    Base.@invokelatest righthand(stream, metro, root)
end
# righthand(stream, metro, root) = nothing

@masync metro righthand(stream, metro, root)

# kick(stream, metro) = nothing
function kick(stream, metro)
    dur = rand([1/4,1/8])   
    @async play_note(stream, metro, 40-2, 100, dur, 3)
    sleep(until(metro, 2*dur))
    Base.@invokelatest kick(stream, metro)
end

@masync metro kick(stream, metro)

# hat(stream, metro) = nothing
function hat(stream, metro)
    dur = 1/2
    sleep(until(metro, dur))
    @async play_note(stream, metro, 40-2, 100, dur, 3)
    sleep(until(metro, dur))
    Base.@invokelatest hat(stream, metro)
end

@masync metro hat(stream, metro)

# chords(stream, metro, root) = nothing
function chords(stream, metro, root)
    dur = 4.0 
    @async play_note(stream, metro, root[] + rand([0,-12]), 120, dur, 4)
    @async play_note(stream, metro, root[] + 7, 120, dur, 4)
    
    sleep(until(metro, dur))
    Base.@invokelatest chords(stream, metro, root)
end

@masync metro chords(stream, metro, root)

# @async play_note(stream, C4 + rand([-5,-2,0,2,5]), rand(80:120), 1.0 + 0.05*rand(), 1)


# function rep(stream, root)
#     dur = 0.19 + 0.005*randn()
#     @async play_note(stream, root[] + rand([-7,-5,0,3,5,12]), rand(60:70), dur + 0.05*rand())
#     sleep(dur)
#     @async play_note(stream, root[] + rand([-12,12]), rand(50:90), dur + 0.05*rand())
#     sleep(dur)
#     Base.invokelatest(rep, stream, root)
# end

# root = Ref(C4)

# rep(stream, C4) = nothing
# @async rep(stream, root)



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
