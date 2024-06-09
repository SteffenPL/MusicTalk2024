using PortMidi


include("utils.jl")
Pm_Initialize()
stream = OpenOutput("loopMIDI Port")

@sync begin
    @async play_note(stream, 60, 127, 1.0, 1)
    @async play_note(stream, 60 + 4, 127, 1.0, 1)
    @async play_note(stream, 60 + 7, 127, 1.0, 1)
end 


@sync begin
    @async play_note(stream, 60, 127, 1.0, 1)
    @async play_note(stream, 60 + 3, 127, 1.0, 1)
    @async play_note(stream, 60 + 7, 127, 1.0, 1)
end 

# melody: 52 .+ (3,3,5,7)
# aeolian = (0,2,3,5,7,8,10)
const A3 = 57
const C4 = 60
const KICK = 36
const HAT = 38

# time keeping
metro = Metronome(bpm = 120.0)

# basic math function
Base.cos(metro, t, period) = cos(2pi * t / bps(metro) / period)


function lefthand(stream, metro, root, i = 1) 
    dur = 1/2

    if i % 8 == 0 
        root[] = rand([48,50,52])
    end

    notes = 52 .+ (3,3,5,7)

    @async play_note(stream, metro, notes[ mod(i, 1:4) ], rand(80:120), dur, 1)
    sleep(until(metro, dur))
    
    @async play_note(stream, metro, root[] - 12, 100, dur, 1)
    sleep(until(metro, dur))

    Base.@invokelatest lefthand(stream, metro, root, i+1)
end

root = Ref(C4)
@masync metro lefthand(stream, metro, root, 1)

function kick(stream, metro) 
    dur = 1/2 
    @async play_note(stream, metro, KICK, rand(80:120), dur, 3)
    sleep(until(metro, dur))
    Base.@invokelatest kick(stream, metro)
end

@masync metro kick(stream, metro)