using PortMidi
import Base.unsafe_convert
using Base.Iterators: cycle
using Base: @invokelatest
using Random: shuffle, shuffle!

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
    
    # give information about the error
    println("Could not open output $(name). Available streams: ")
    for i in 0:Pm_CountDevices()-1
        info = unsafe_load(Pm_GetDeviceInfo(i))
        println(i, ": ", info.output > 0 ? "[Output] " : "[Input]  ", unsafe_string(info.name), " (", unsafe_string(info.interf), ")")
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

bps(metro) = metro.bpm / 60.0
spb(metro) = 60.0 / metro.bpm

beat(metro) = (time() - metro.last_beat[]) * bps(metro)

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

const Note_ON = 0x90
const Note_OFF = 0x80



function quantize(root, steps, note) 
    oct, offset = divrem(note - root, 12, RoundDown) 
    i = findfirst(n -> n >= offset, steps)
    return root + Int(oct)*12 + steps[i]
end

function notename(note)
    oct, offset = divrem(note, 12, RoundDown)
    return ("C","C♯","D","D♯","E","F","F♯","G","G♯","A","A♯","H")[1+offset] * string(oct-2)
end

function playnote_(stream, note::Int, velocity, duration, chn = 1)
    Pm_WriteShort(stream[], 0, Pm_Message(0x90 + chn - 1, note, round(Int, velocity)))
    sleep(duration)
    Pm_WriteShort(stream[], 0, Pm_Message(0x80 + chn - 1, note, round(Int, velocity)))
    return note
end

playnote(instr::NamedTuple, note::Int, vel, dur) = @async playnote_(instr.stream,note,vel,dur*spb(instr.metro),instr.chn)

function playnotes(instr, chord, vels, durs)
    for (note, vel, dur) in zip(chord, cycle(vels), cycle(durs))
        playnote(instr, note, vel, dur)
    end
end

function playmelody(instr, notes, rythm, note_vels, note_durs)
    for (chord, beats, vels, durs) in zip(notes, cycle(rythm), cycle(note_vels), cycle(note_durs)) 
        playnotes(instr, chord, vels, durs)
        sleep(until(instr.metro, beats))
    end
end
