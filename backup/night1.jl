include("init_session.jl")

metro = Metronome(bpm = 105)
lead = Instrument(stream, 1, metro)
pad =  Instrument(stream, 2, metro)
function triplet(start, i)
    ts = LinRange(i,i+1,16)

    notes = @. start + rand([[0, 3, 5], [0, -9, 5], [0, 7, 5]])
    notes = c4major(notes)
    @sync begin 
        sleep(until(metro, 4.0))
        if rand() > 0.8
            @async playmelody(lead, notes, [0.5, 0.25, 3.0], [120, 100, 80], [1.5, 1.5, 2.0], 0)
        else
            @async playmelody(lead, c4major(@. start + 4 * tri(ts/3) * (1 + 2 * tri(ts*2))) , 0.25, [120, 100, 120, 70], 0.5, 0)
        end
        @async playmelody(pad, c4major([notes[1], notes[1] - 12 + 7, notes[1] - 12 + 4]), [0.04, 0.04, 3.0], rand(50:90), 3.8, 0)
    end
end

function rep(instr = lead, i = 0, r = 60)
    triplet(r, i)
    if i % 2 == 0 
        r += rand([-7,-5,-3,-7,9])
        r = clamp(r, 48, 75)
        r = c4major(r)
    end
    return true, (instr, i+1, r)
end

A = mrepeat(metro, rep)
stop!(A)