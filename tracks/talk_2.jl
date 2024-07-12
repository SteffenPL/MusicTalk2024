include("../init_session.jl")


metro = Metronome(bpm = 105)
pad = Instrument(stream, 1, metro)
horn = Instrument(stream, 2, metro)
drum = Instrument(stream, 10, metro)

function chords(i=0, instr = pad, root = 60)
    
    chrs = rand([[0,5,9], [-5,0,9], [-9,0,-3]])

    if i % 2 == 0
        root += rand([-5,-12,+3,+7])
        root = clamp(root, 36, 72)
        root = c4major(root)
    end

    playmelody(instr, [c4major.(root .+ chrs)], 16.0, rand(20:100), 15.0)

    return (true, (i+1, instr, root))
end
A = mrepeat(metro, chords)
stop!(A)

function lead(i=0, instr=horn)

    ts = LinRange(i,i+1,4)

    offsets = [0, 2, 2, 5]
    notes = c4major(@. 48 + offsets - [5,9,0][mod1(i,3)])

    rythm = fill(4.0, 4)

    playmelody(instr, notes, rythm, rand(40:100, 4))

    return (true, (i+1,instr))
end
L = mrepeat(metro, lead)
stop!(L)


function drum_pattern(i = 0, instr = drum)
    
    ts = LinRange(i,i+1,4)
    lfo = @. 0.6 + 0.4*tri(ts / 4)

    @sync begin 
        @async playmelody(instr, [76,76,76,76], 1.0, lfo .* [80 + 20 * rand(); 40 .+ 40 .* rand(3)], 0.8, 4.0)
        @async playmelody(instr, [36, 36], 2.0, rand(40:80), 1.0)
    end
    return (true, (i+1, instr,))
end

D = mrepeat(metro, drum_pattern)
stop!(D)