type Entries
    entries::Vector{(Module, Any, Entry)}
end
Entries() = Entries((Module, Any, Entry)[])

function push!(ents::Entries, modulename::Module, obj, ent::Entry)
    push!(ents.entries, (modulename, obj, ent))
end

length(ents::Entries) = length(ents.entries)

@doc "The manual pages associated with a documented module." ->
manual(modulename::Module) = manual(documentation(modulename))
