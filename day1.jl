include("init_session.jl")

metro = Metronome(bpm = 120.0)

piano = (;stream, chn = 1, metro)
drum  = (;stream, chn = 10, metro)
playnote(piano, 60, 100, 0.1)
playnote(drum, 36, 100, 0.1)

playnotes(piano, [60, 61], 100, 0.2)

using Random: shuffle, shuffle!
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

function repeat(fnc)
    cont, arg = fnc()
    running = Ref(true)
    @async while cont && running[]
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
    @show dur = until(metro,metro.counts)
    sleep(dur)
    repeat(fnc)
end

stop!(running) = running[] = false




function part(i = 1, offset = 0, instr = piano)
    if i % 8 == 0 
        offset += rand([-9,-5,0,5,7])
        offset = clamp(offset, -24,24)
        @show offset
    end

    notes = quantize(60, scale_major, shuffle([60, 64, 67]) .- 12 .+ offset)

    playmelody(instr, notes, 0.25 / 2, rand(20:40), 0.5)
    return true, i+1, offset
end

function jazzi(i = 1, melo = [60, 65, 67, 69, 65, 64, 65, 69], root = 0, piano = piano, drum = drum)
    if i % 1 == 0 
        melo[rand(eachindex(melo))] = rand(setdiff([55, 55, 57, 59, 60, 62, 64, 64, 65, 67, 69, 72], melo))  
        @show melo, root
    end

    if i % 2 == 0
        a = rand(eachindex(melo))
        b = rand(eachindex(melo))
        a, b = minmax(a,b)
        melo[a:b] .= sort(melo[a:b]; rev = rand(Bool))
    end

    if i % 2 == 0 
        root = rand([-5,-3,-12,-15,-24,0,4,9])
    end

    if i % 8 == 0 
        shuffle!(melo)
    end
    
    @sync begin 
        rythm = 0.5 .* shuffle([0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5])
        drums = [36, 38, rand([36,38,39,40]), 38]
        @async playmelody(piano, quantize(60, scale_major, root .+ melo), rythm, 20 .+ 60 .* rand(4), 0.5 .+ 0.2 * rand(4))
        @async playmelody(drum, vcat(drums, shuffle(drums)), rythm, 40 .+ 60 .* rand(4), 0.3)
        @async begin 
            sleep(0.125 * spb(metro))
            playmelody(piano, fill(60 + root, 7), 0.25, 60 .+ 20 .* rand(7), 0.12)
        end
        @async begin 
            playnotes(piano, quantize(60, scale_major, 48 .+ [0, 4, 9] .+ root), 60 .+ 30 .* rand(3), 1.9)
        end
    end

    return true, (i+1, melo, root)
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
