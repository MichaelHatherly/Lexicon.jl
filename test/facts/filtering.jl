using Docile.Interface

facts("Filtering.") do

    context("Filter.") do

        d = metadata(Docile);
        
        # Filter entries with categories of :macro and :type
        d1 = filter(d, categories = [:macro]) 
        
        res = [category(v) for (k,v) in EachEntry(d1)]
        @fact all(res .== :macro) --> true
        
        d2 = filter(d) do e
            category(e) == :type
        end
        @fact all([category(v) == :type for (k,v) in EachEntry(d2)]) --> true
        
    end

    context("EachEntry.") do

        d = metadata(Docile);
        
        res = [v.data[:source][1] for (k,v) in EachEntry(filter(d, files = ["types.jl"]), order = [:source])]
        @fact issorted(res) --> true
        
    end

end
