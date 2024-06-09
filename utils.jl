import Base.unsafe_convert


Base.@kwdef mutable struct Metronome
    bpm::Float64 
    last_beat::Float64 = time()
    counts::Float64 = 4.0
end

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


const Note_ON = 0x90
const Note_OFF = 0x80



function quantize(root, steps, note) 
    oct, offset = divrem(note - root, 12) 
    i = findfirst(n -> n >= offset, steps)
    if isnothing(i)
        return root + Int(oct)*12 + 12
    else
        return root + Int(oct)*12 + steps[i]
    end
end


macro play(note, vel, dur, ch = 1)
    return quote 
        @async play_note(stream, metro, $note, $vel, $dur, $ch)
    end
end


function play_note(stream, note::Int, velocity, duration, chn = 1)
    Pm_WriteShort(stream[], 0, Pm_Message(0x90 + chn - 1, note, round(Int, velocity)))
    sleep(duration)
    Pm_WriteShort(stream[], 0, Pm_Message(0x80 + chn - 1, note, round(Int, velocity)))
    return note
end

play_note(stream, metro::Metronome, note, vel, dur, chn = 1) = play_note(stream,note,vel,dur*spb(metro),chn)


macro masync(metro, expr)
    return quote 
        @async begin 
            sleep(until($metro, $metro.counts))
            printstyled("Start temporal recursion.\n", color = :blue)
            @async $expr 
        end
    end
end


bps(metro) = metro.bpm / 60.0
spb(metro) = 60.0 / metro.bpm

beat(metro) = (time() - metro.last_beat[]) * bps(metro)

function until(metro, step, minstep = 1)
    cur = beat(metro) 
    next = ceil( cur / step ) * step
    return max(next * spb(metro) - time(), step * minstep * spb(metro))
end 
