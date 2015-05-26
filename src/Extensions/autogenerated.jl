["Auto-generated pages"]

# Multi-modules (e.g. package) or single module `section` and single module `page`
function autogenerate(item::Union(Section, Page))
    if isa(item, Page)
        autogenerate(item, item.autogenerate[2], item.config)
    else
        isa(item.autogenerate[2], Module)            ?
            autogenerate(item, item.autogenerate[2]) :   # single module section
            autogenerate(item, item.autogenerate[2])     # mulit-module section
    end
end

# Multi-modules (e.g. package) Section: each module within a separate page
function autogenerate(sect::Section, mA::Vector{Module})
    for mod in mA
        child = autogenerate(page(string(mod)), mod, sect.config)
        length(child.children) > 0 && push!(sect.children, child)
    end
    return sect
end

# Single module section: each category within a separate page
function autogenerate(sect::Section, m::Module)
    objsdict = autogenerate_prepare(sect.autogenerate[2], sect.config)
    for category in objsdict[:order]
        exported, internal = objsdict[category]
        child = page(string(category), title("$(ucfirst(string(category)))s"))
        isempty(exported) || append!(child.children,  [header("Exported"), objs(exported)])
        isempty(internal) || append!(child.children,  [header("Internal"), objs(internal)])
        push!(sect.children,  child)
    end
    return sect
end

# Single module page: all categories within a one page
function autogenerate(page::Page, m::Module, config::Config)
    objsdict = autogenerate_prepare(m, config)
    isempty(objsdict[:order]) && return page

    push!(page.children,  title(page.name))
    for category in objsdict[:order]
        exported, internal = objsdict[category]
        children = Vector{ContentNode}([header("$(ucfirst(string(category)))s")])
        isempty(exported) || append!(children,  [subheader("Exported"), objs(exported)])
        isempty(internal) || append!(children,  [subheader("Internal"), objs(internal)])
        append!(page.children,  children)
    end
    return page
end

# Common method to preprepare objects for autogenerate methods
function autogenerate_prepare(mod::Module, config::Config)
    objects = Cache.objects(mod)
    objsdict = Dict()
    objsdict[:order] = Vector{Symbol}()
    isempty(objects)  && return objsdict

    for category in config.autogenerate_categories
        category_objects = filter((obj) -> Cache.getmeta(mod, obj)[:category]== category, objects)
        if !isempty(category_objects)
            exported, internal = autogenerate_prepare(category_objects, config.autogenerate_internal, mod)
            isempty(exported) && isempty(internal) && return objsdict

            objsdict[category] = (exported, internal)
            push!(objsdict[:order], category)
        end
    end
    return objsdict
end

# Returns separate: exported, internal objects
function autogenerate_prepare(category_objects, autogenerate_internal, mod::Module)
    exported = []
    internal = []
    for obj in category_objects
        # Aside do not work with legacy isexported
        if isa(obj, Collector.Aside) 
            autogenerate_internal && push!(internal, obj)
        elseif Interface.isexported(mod, obj)
            push!(exported, obj)
        elseif autogenerate_internal
            push!(internal, obj)
        end
    end
    return exported, internal
end
