using Base.Iterators: cycle
using Base: @invokelatest
using Random: shuffle, shuffle!

using PortMidi
import Base.unsafe_convert

function OpenOutput(name)
    stream = Ref{Ptr{PortMidi.PortMidiStream}}(C_NULL)

    for i in 0:Pm_CountDevices()-1
        info = unsafe_load(Pm_GetDeviceInfo(i))
        if info.output > 0 && unsafe_string(info.name) == name 
            print("Open MIDI output stream $(name).")
            Pm_OpenOutput(stream, i, C_NULL, 0, C_NULL, C_NULL, 0)
            return stream
        end
    end
    
    return stream 
end

Pm_Initialize()
stream = OpenOutput("loopMIDI Port")


Base.@kwdef mutable struct Metronome
    bpm::Float64 
    last_beat::Float64 = time()
    counts::Float64 = 4.0
end

mutable struct Instrument
    stream::Base.RefValue{Ptr{PortMidi.PmStream}} 
    chn::Int16
    metro::Metronome
end


bps(metro) = metro.bpm / 60.0
spb(metro) = 60.0 / metro.bpm

beat(metro) = (time() - metro.last_beat[]) * bps(metro)

function msleep(metro, dur)
    sleep(spb(metro)*dur)
end

function until(metro, step, minstep = 1)
    cur = beat(metro) 
    next = ceil( cur / step ) * step
    dur = next * spb(metro) + metro.last_beat[] - time()
    return dur > 0 ? dur : step * minstep * spb(metro)
end 

macro masync(metro, expr)
    return quote 
        @async begin 
            sleep(until($metro, $metro.counts))
            printstyled("Start temporal recursion.\n", color = :blue)
            @async $expr 
        end
    end
end


const scale_major = (0,2,4,5,7,9,11,12)


function notename(note)
    oct, offset = divrem(note, 12, RoundDown)
    return ("C","C♯","D","D♯","E","F","F♯","G","G♯","A","A♯","H")[1+offset] * string(oct-2)
end


const Note_ON = 0x90
const Note_OFF = 0x80

function playnote_(stream, note::Int, velocity, duration, chn = 1)
    Pm_WriteShort(stream[], 0, Pm_Message(0x90 + chn - 1, note, round(Int, velocity)))
    sleep(duration)
    Pm_WriteShort(stream[], 0, Pm_Message(0x80 + chn - 1, note, round(Int, velocity)))
    return note
end

playnote(instr::Instrument, note::Int, vel, dur) = @async playnote_(instr.stream,note,vel,dur*spb(instr.metro),instr.chn)

function playnotes(instr, chord, vels, durs)
    for (note, vel, dur) in zip(chord, cycle(vels), cycle(durs))
        playnote(instr, note, vel, dur)
    end
end

function playmelody(instr, notes, rythm, note_vels, note_durs = 1.0, offset = nothing)
    if isnothing(offset)
        offset = sum(r for (n,r) in zip(notes, cycle(rythm)))
    end
    sleep(until(instr.metro, offset, 0))

    for (k, (chord, beats, vels, durs)) in enumerate(zip(notes, cycle(rythm), cycle(note_vels), cycle(note_durs)))
        playnotes(instr, chord, vels, durs .* beats .* 0.9)
        if k < length(notes)
            sleep(until(instr.metro, beats))
        end
    end
end


function repeat(fnc)
    cont, arg = fnc()
    running = Ref(true)
    Threads.@spawn while cont && running[]
        try
            cont, new_arg = @invokelatest fnc(arg...)
            arg = new_arg
        catch err 
            showerror(stdout, err, catch_backtrace())
            running[] = false
            return running
        end
    end
    return running
end

function mrepeat(metro, fnc)
    dur = until(metro,metro.counts)
    sleep(dur)
    repeat(fnc)
end

stop!(running) = running[] = false

makescale(steps...) = (0, cumsum(steps)...)

# diatonic (7 pitches)
sc_ionian = makescale(2,2,1,2,2,2,1)
sc_dorian = makescale(2,1,2,2,2,1,2)
sc_phrygian = makescale(1,2,2,2,1,2,2)
sc_lydian = makescale(2,2,2,1,2,2,1)
sc_mixolydian = makescale(2,2,1,2,2,1,2)
sc_aeolian = makescale(2,1,2,2,1,2,2)
sc_locrian = makescale(1,2,2,1,2,2,2)

sc_japanese = makescale(2,3,2,2,3)

mutable struct Scale{N} 
    root::Int64 
    scale::NTuple{N,Int64}
end

function scaleposition(s::Scale, note)
    oct, offset = divrem(note - s.root, 12, RoundDown) 
    i = findfirst(n -> n >= offset, s.scale)
    return oct, i
end

function quantize(s::Scale, notes::Vector) 
    return map(note -> quantize(s, note), notes)
end

function quantize(s::Scale, note) 
    oct, i = scaleposition(s, note)
    return s.root + Int(oct)*12 + s.scale[i]
end
    
function (s::Scale)(notes)
    return quantize(s, notes)
end

function step(s::Scale, note, offset)
    oct, i = scaleposition(s, note)
    i += offset 
    oct_steps, i = divrem(i, length(s.scale), RoundDown)
    oct = Int(oct + oct_steps)
    return s.root + 12*oct + s.scale[i]
end

c4major = Scale(60, sc_ionian)


# function which goves between -1 and 1 with period 2
function tri(x) 
    x = mod(x+1, 2) - 1
    return 2 * abs(x) - 1
end