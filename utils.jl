import Base.unsafe_convert


function OpenOutput(name)
    stream = Ref{Ptr{PortMidi.PortMidiStream}}(C_NULL)

    for i in 0:Pm_CountDevices()-1
        info = unsafe_load(Pm_GetDeviceInfo(i))
        if unsafe_string(info.name) == name 
            Pm_OpenOutput(stream, id, C_NULL, 0, C_NULL, C_NULL, 0)
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