include("init_session.jl")
using Random: shuffle, shuffle!

metro = Metronome(bpm = 120.0)

piano = (;stream, chn = 1, metro)
drum  = (;stream, chn = 10, metro)
playnote(piano, 60, 100, 0.1)
playnote(drum, 36, 100, 0.1)

playnotes(piano, [60, 67], 100, 1.8)

melo = [60, 65, 67, 69]
for i in 1:50
    if i % 4 == 0 
        shuffle!(melo)     
        melo[rand(eachindex(melo))] = rand(setdiff([57, 59, 60, 62, 64, 65, 67, 69], melo))  
    end
    @sync begin 
        rythm = 0.5 .* shuffle([0.5,1.0,0.5,0.5])
        @async playmelody(piano, melo, rythm, 40 .+ 60 .* rand(4), 0.5 .+ 0.2 * rand(4))
        @async playmelody(drum, [36, 38, 38, 38], rythm, 40 .+ 60 .* rand(4), 0.3)
    end
end 


using Base.Threads: @spawn

# kick(x) = nothing
function kick(instr)
    dur = 0.5 + 0.0 * sin(1)
    sleep(until(instr.metro, dur))
    @spawn playnote(instr, 60, 100, dur)
    sleep(until(instr.metro, dur))
    @spawn playnote(instr, 62, 100, dur)

    Base.@invokelatest kick(instr)
end

@masync metro kick(piano)

function part(i = 1, offset = 0, instr = drum, instr2 = piano)

    @sync begin
        @async playmelody(piano, [60, 60 + rand([-5,-3,4,7,9])], 0.5, [60, 50], 0.5)
        @async playmelody(instr, [36, 38, 38, 38], 0.25, [100, 60, 80, 60], 0.5)
    end
    return true, i+1, offset + 5
end


function chords(i = 1, instr = piano, o = 48)
    if i % 8 == 0 
        o += rand([-5,3,0,3,5])
        o = clamp(o, 36, 48)
        o = quantize(60, scale_major, o)
        @show notename(o)
    end

    playmelody(instr, [48, o, 48, o], 0.5, rand(40:50), 0.20)
    return true, i+1, instr, o
end

A3 = mrepeat(metro, chords)
stop!(A3)
A2 = mrepeat(metro, part)
stop!(A2)

function jazzi(next = time(), i = 1, melo = [60, 65, 67, 69, 65, 64, 65, 69], root = 0, piano = piano, drum = drum)
    sleep(until(0.0, dur))
    begin 
        rythm = 0.5 .* shuffle([0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5])
        drums = [36, 38, rand([36,38,39,40]), 38]
        # @async playmelody(piano, quantize(60, scale_major, root .+ melo), rythm, 20 .+ 60 .* rand(4), 0.5 .+ 0.2 * rand(4))
        # @async playmelody(drum, vcat(drums, shuffle(drums)), rythm, 40 .+ 60 .* rand(4), 0.3)
        @async begin 
            playmelody(piano, fill(60, 8), 0.25, [120, 60, 60, 60, 60, 60, 60, 60], 0.05)
        end
        # @async begin 
        #     playnotes(piano, quantize(60, scale_major, 48 .+ [0, 4, 9] .+ root), 60 .+ 30 .* rand(3), 1.9)
        # end
    end

    next = time() + until(metro, 2.0)

    return true, next, (i+1, melo, root)
end

A = mrepeat(metro, jazzi)
stop!(A)

function part2(i = 1, instr = drum)
    playmelody(instr, [36, 38, 38], 1.0, rand(50:100), 0.5)
    return true, i+1
end

A2 = mrepeat(metro, part2)
stop!(A2)


A = mrepeat(metro, part)
A2 = mrepeat(metro, part2)
