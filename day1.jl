include("init_session.jl")

metro = Metronome(bpm = 120.0)

piano = (;stream, chn = 1, metro)
drum  = (;stream, chn = 10, metro)
playnote(piano, 60, 100, 0.1)
playnote(drum, 36, 100, 0.1)

playnotes(piano, [60, 61], 100, 0.2)

using Random: shuffle, shuffle!
melo = [60, 65, 67, 69]
for i in 1:20
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
            cont, new_arg = @invokelatest fnc(arg)
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




function part(i = 1, instr = piano)
    playmelody(instr, shuffle([60, 64, 67]) .- 24 .+ 5, 0.25 / 2, rand(20:40), 0.5)
    return true, i+1
end

A = mrepeat(metro, part)
stop!(A)

function part2(i = 1, instr = drum)
    playmelody(instr, [36, 38, 38], 1.0, rand(50:100), 0.5)
    return true, i+1
end

A2 = mrepeat(metro, part2)
stop!(A2)


A = mrepeat(metro, part)
A2 = mrepeat(metro, part2)
