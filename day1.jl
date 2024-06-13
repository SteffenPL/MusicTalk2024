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

function something(i)
    rythm = 0.5 .* shuffle([0.5,1.0,0.5,0.5])
    playmelody(drum, [36, 38, 38, 38], rythm, 40 .+ 60 .* rand(4), 0.3)
end
macro makefn(prefix, name)
    fn = Symbol(prefix * "_" * name)
    quote
        function $(esc(fn))()
            println("hello")
        end
    end
end
@makefn "fn" "hello"
macro repeat(expr, force = false)
    running_sym = Symbol(expr, :_running)
    return quote
        function TempRec(running, args...)
            if running[]
                try 
                    cont, new_args = Base.invokelatest($expr,args...)
                    if cont
                        return TempRec(running, new_args...)
                    else 
                        running[] = false
                    end
                catch err 
                    running[] = false 
                    showerror(stdout, err, catch_backtrace())
                    return nothing
                end
            end
        end

        was_running = if !$(force) && isdefined(Main, Symbol($expr, :_running))
            $(esc(running_sym))[]
        else
            false 
        end
        
        if !was_running
            $(esc(running_sym)) = Ref(true)
            @async TempRec($(esc(running_sym)))
        end
    end
end

macro repeat_(expr)
    running_sym = Symbol(expr, :_running)
    return quote 
        $(esc(running_sym))[] = false
    end
end

function repeat(fnc)
    if !isnothing(metro)
    sleep(until(metro,metro.counts,0))
    cont, arg = fnc()
    running = Ref(true)
    @async while cont && running[]
        cont, new_arg = @invokelatest fnc(arg)
        arg = new_arg
    end
    return running
end

function mrepeat(metro, fnc)
    sleep(until(metro,metro.counts))
    repeat(fnc)
end


Base.throwto(tsk, InterruptException())

stop!(running) = running[] = false

A = mrepeat(part, metro)
stop!(A)

function part(i = 1)
    playmelody(piano, [60, 64, 67], 0.2, rand(50:100), 0.5)
    return true, i+1
end

A = @repeat part8;

close(A)
function part(i = 1)
    sleep(0.1)
    print(i, ", ")
    return false, i+1
end


@macroexpand @repeat something function(i = 1) 
    sleep(0.1)
    println(i)
    return i+1
end
a = @repeat something function(i = 1) 
    sleep(0.1)
    println(i)
    return i+1
end
@repeat something function(i = 1) 
    sleep(1.0)
    println(i*100)
    return i+1
end
eval(Meta.parse("#228#something(i) = nothing")) 

@pattern function drums1(i) 
    [60, 62], [100, 120], [0.1, 0.2], [0.2, 0.2], i+1
end

function drums1(instr)

@play drums 


evn(n::Int, i) = n 
evn(n::Vector, i) = evn.(n, i) 
evn(n, i) = n(i)

function pattern(instr, notes, vels, durs)
    all_notes = evn(notes, eachindex(notes))
    for cur_notes in all_notes
        @sync begin 
            for note in cur_notes
                @async play_note(instr, note, vels, durs)
            end
        end
    end
end

macro repeat(expr)
    return quote 
        task = Task( () -> begin 
            for i in 1:2 
                ($pattern)()
            end 
        end)
        task
    end
end

instr = piano
pattern(instr, [60, [60,64], [60, 64, 67]], 100, 0.2)

t = @repeat( ()->pattern(instr, [60, [60,64], [60, 64, 67]], 100, 0.2) )
schedule(t)

@repeat 