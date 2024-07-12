


include("init_session.jl")
metro = Metronome(bpm = 110)
piano = Instrument(stream, 1, metro)

function tri(x) 
    x = mod(x+1, 2) - 1
    return 2 * abs(x) - 1
end

root = Ref(60)

function rhs4(instr = piano, i = 1, root = root)
    ts = LinRange(i,i+1,4)

    if i % 8 == 0
        root[] = quantize(62, sc_ionian, rand([60, 60-6, 48, 48 + 4]))
    end

    notes = @. root[] + 24 + 16 * tri(13/4*ts) * tri(9/5*ts) + 8 * tri(0.1*ts)
    notes = quantize(62, sc_ionian, notes)
    @sync begin 
        @async playmelody(instr, notes , 0.25, rand(60:100), 1.6)
    end
    return true, (instr, i+1, root)
end



A = mrepeat(metro, rhs4)
stop!(A)

function riff(instr, root, j) 
    qa(x) = quantize(62, sc_japanese, x)

    @sync begin 
        @async playnote(instr, qa(root[] - 12), 100, 3.9)
        @async begin 
            for i in 1:8 
                playnote(instr, qa(root[]), 100, 0.4)
                i < 8 && sleep(spb(metro)*0.5)
            end
        end
        @async begin 
            sleep(spb(metro)*0.25)
            for i in 1:8
                playnote(instr, qa(quantize(62, sc_ionian, root[] + rand([9 + mod(j/5, 10)]))), 100, 0.4)
                i < 8 && sleep(spb(metro)*0.5)
            end
        end
    end
end

synth = Instrument(stream, 3, metro)
function lhs(instr = synth, i = 1, root = root)
    
    # playmelody(instr, [chord, chord, chord], [1.0, 1.0, 2.0], rand(70:90), [0.9,0.9,1.9])

    sleep(until(metro, 4.))
    riff(instr, root[], i) 


    return true, (instr, i+1, root)
end

B = mrepeat(metro, lhs)
stop!(B)

drums = Instrument(stream, 10, metro)

function dp(instr = drums, i = 1)
    @sync begin
        @async playmelody(instr, [36,38,36,38], 0.5, rand(80:100), 0.5)
        @async playmelody(instr, [0,36,0,rand(37:42),0,36,0,38], 0.25, rand(80:100), 0.5)
    end
    return true, (instr, i+1)
end

C = mrepeat(metro, dp)
stop!(C)

synth2 = Instrument(stream, 2, metro)
function lhs2(instr = synth2, i = 1, root = root)
    chord = quantize(62, sc_ionian, [root[], root[] + 7])
    
    ts = LinRange(i,i+1,4)
    rythm = fill(0.25, 4)
    notes = @. 0 + root[] + (tri(ts*3) + 12) * round(tri(ts/10),digits=1) * (1 + tri(ts/10))
    notes = quantize(62, sc_ionian, notes)

    playmelody(instr, notes, rythm, rand(70:120, 4), 0.24)

    return true, (instr, i+1, root)
end

B2 = mrepeat(metro, lhs2)
stop!(B2)
