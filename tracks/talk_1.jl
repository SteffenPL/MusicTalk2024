include("../init_session.jl")

metro = Metronome(bpm = 120)
piano = Instrument(stream, 1, metro)
lead =  Instrument(stream, 3, metro)
bass = Instrument(stream, 5, metro)
drum = Instrument(stream, 10, metro)

# Cover of Andrew Sorenson's: The Concert Programmer performance!

root = Ref(60)

function lefthand(i = 1, instr = piano, root = root, bass = bass)

    if i % 4 == 0 
        root[] = rand( [r for r in [52,50,48] if r != root[]] )
    end

    dur = 0.5
    @sync begin
        @async playmelody(instr, [fill(root[] * 0, 4)'; [55,55,57,59]'][:] , dur, rand(40:60, 4))
        @async playmelody(bass, [fill(root[] - 12, 3);0], dur * 2, rand(60:100,4))
    end
    return (true, (i+1, instr, root))
end
A = mrepeat(metro, lefthand)
stop!(A)

sc = Scale(64, sc_aeolian)
function righthand(i = 1, instr = lead, root = root)
    dur = 0.25
    N = 4
    ts = LinRange(i,i+1,N)

    notes = quantize(sc, @. root[] + 24 + 5 + 3 * cospi(ts * 1/2) * cospi(ts * 7/3))
    vels = max(0,(100 - 5*i)/100) * @. 80 + 20 * cospi(ts)
    playmelody(instr, notes, dur, vels) 

    return (true, (i+1,instr,root))
end
B = mrepeat(metro, righthand)
stop!(B)

function drums(i=1,instr = drum)
    playmelody(instr, [37,38,37,38], 1.0, rand(50:100, 4))
    return (true, (i+1,instr))
end
D = mrepeat(metro, drums)
stop!(D)

