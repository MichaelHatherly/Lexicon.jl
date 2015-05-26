const STYLE_TAGS     = ["#", "##", "###", "####", "#####", "######"]
const STYLE_EMPHASIS = ["", "*", "**"]

const CATEGORIES = [:module,    :function, :method, :macro, :type,
                    :typealias, :global,   :symbol, :tuple, :aside]

## Config Nodes
abstract ConfigNode

type Config <: ConfigNode
    style_title                 :: ASCIIString
    style_header                :: ASCIIString
    style_subheader             :: ASCIIString
    autogenerate_categories     :: Vector{Symbol}
    autogenerate_internal       :: Bool

    const defaults = Dict{Symbol, Any}(
        :style_title                => "#",
        :style_header               => "##",
        :style_subheader            => "###",
        :autogenerate_categories    => [:module,    :function, :method, :macro, :type,
                                        :typealias, :global,   :symbol, :tuple, :aside],
        :autogenerate_internal      => true
        )

    Config(; args...) = update_config!(new(), merge(defaults, Dict(args)))
end
config(; cargs...) = PreConfig(; cargs...)

type PreConfig <: ConfigNode
    cargs :: Dict{Symbol, Any}

    PreConfig(; cargs...) = new(Dict(cargs))
end

function update_config!(config::Config, args::Dict)
    const fields = fieldnames(Config)
    for (k, v) in args
        k in fields                                                ?
            setfield!(config, k, convert(fieldtype(Config, k), v)) :
            throw(ArgumentError("'Config'. Invalid setting: '$(k) = $(v)'."))
    end

    for k in [:style_title, :style_header, :style_subheader]
        getfield(config, k) in vcat(STYLE_TAGS, STYLE_EMPHASIS) ||
            throw(ArgumentError(string("Invalid 'style' : config-item `$k -> $(getfield(config, k))`.\n",
                      "Valid values: [$(join(vcat(STYLE_TAGS, STYLE_EMPHASIS), ", "))].")))
    end

    for c in config.autogenerate_categories
        c in CATEGORIES ||
            throw(ArgumentError(string("Invalid 'autogenerate_categories' value:  `$c`.\n",
                      "Valid values: [$(join(CATEGORIES, ", "))].")))
    end
    return config
end
update_config!(config::Config, args...) = update_config!(config, Dict(args))

## Main structure nodes
abstract SectionNode
abstract PreformatNode
abstract PagesNode
abstract PageNode
abstract ContentNode

immutable NullSection   <: SectionNode   end
immutable NullPreformat <: PreformatNode end
immutable NullPage      <: PageNode      end

# Document
type Document
    name        :: AbstractString
    config      :: ConfigNode
    meta        :: Dict{Symbol, Any}
    children    :: Vector{SectionNode}
end
document(name::AbstractString, conf::PreConfig, children...) =
                                            prepare_document!(name, conf, Dict(), [children...])
document(name::AbstractString, children...) = document(name, PreConfig(), children...)

function prepare_document!(name::AbstractString, conf::PreConfig, meta::Dict, children::Vector)
    this = isempty(conf.cargs)                           ?
                Document(name, Config(), meta, children) :
                Document(name, update_config!(Config(), deepcopy(conf.cargs)), meta, children)
    isempty(children) || postprocess!(this, children)
    return this
end


# Section
type Section <: SectionNode
    name            :: AbstractString
    config          :: ConfigNode
    meta            :: Dict{Symbol, Any}
    autogenerate    :: Tuple
    parent          :: Union(Document, SectionNode)
    children        :: Vector{Union(SectionNode, PreformatNode, PagesNode, PageNode)}
end
section(name::AbstractString, conf::PreConfig, children...) =
        Section(name, conf, Dict(), (false, nothing), NullSection(), [children...])
section(name::AbstractString, children...) = section(name, PreConfig(), children...)

# High level autogenerate methods
section(m::Module, conf::PreConfig) =
        Section(string(m), conf, Dict(), (true, m), NullSection(), [])
section(m::Module) = section(m, PreConfig())

function section(name::AbstractString, conf::PreConfig, mA::Vector{Module})
    Section(name, conf, Dict(), (true, mA), NullSection(), [])
end
section(name::AbstractString, mA::Vector{Module}) = section(name, PreConfig(), mA)


# Page
type Page <: PageNode
    name            :: AbstractString
    config          :: ConfigNode
    meta            :: Dict{Symbol, Any}
    autogenerate    :: Tuple
    parent          :: Union(SectionNode, PagesNode)
    children        :: Vector{ContentNode}
end
page(name::AbstractString, conf::PreConfig, children...) =
        Page(name, conf, Dict(), (false, nothing), NullSection(), [children...])
page(name::AbstractString, children...) = page(name, PreConfig(), children...)

# High level autogenerate methods
page(m::Module, conf::PreConfig) =
        Page(string(m), conf, Dict(), (true, m), NullSection(), [])
page(m::Module) = page(m, PreConfig())


## Group container nodes

# PreformatPage
type PreformatPage
    name        :: AbstractString
    config      :: ConfigNode
    meta        :: Dict{Symbol, Any}
    parent      :: PreformatNode
    data        :: AbstractString
end


# Preformat
type Preformat <: PreformatNode
    name        :: AbstractString
    config      :: ConfigNode
    meta        :: Dict{Symbol, Any}
    parent      :: SectionNode
    children    :: Vector{PreformatPage}
end

function preformat(name::AbstractString, conf::PreConfig, children...)
    # findexternal: if content is acutally a file path read that instead if it.
    prepages = [PreformatPage(child[1], PreConfig(),  Dict(), NullPreformat(),
                              findexternal(child[2])) for child in [children...]]
    Preformat(name, conf, Dict(), NullSection(), prepages)
end
preformat(name::AbstractString, children...) = preformat(name, PreConfig(), children...)


# Pages
type Pages <: PagesNode
    name        :: AbstractString
    config      :: ConfigNode
    meta        :: Dict{Symbol, Any}
    parent      :: SectionNode
    children    :: Vector{Page}
end
pages(name::AbstractString, conf::PreConfig, children...) =
    Pages(name, conf, Dict(), NullSection(), [children...])
pages(name::AbstractString, children...) = pages(name, PreConfig(), children...)


## Related functions
# sets: parents, final configuration
function postprocess!(parent, children::Vector)
    for child in children
        child.parent = parent
        child.config = isempty(child.config.cargs)  ?
                            deepcopy(parent.config) :
                            update_config!(deepcopy(parent.config), deepcopy(child.config.cargs))
        if isa(child, Union(Section, Page))
            # auto generate pages for the module
            child.autogenerate[1] && autogenerate(child)
            isempty(child.children) || postprocess!(child, child.children)
        elseif isa(child, Pages)
            isempty(child.children) || postprocess!(child, child.children)
        # these have no field children: but valid just skip them
        elseif !isa(child, Union(Preformat, PreformatPage, ContentNode))
            throw(ArgumentError("`$(typeof(child))` is not a valid node structure type."))
        end
    end
end

# get the method name for a node structure object
function getnodename(nodeobj)
    isa(nodeobj, Document)  && return "document"
    isa(nodeobj, Section)   && return "section"
    isa(nodeobj, Page)      && return "page"
    isa(nodeobj, Preformat) && return "preformat"
    isa(nodeobj, Pages)     && return "pages"
    throw(ArgumentError("`$(typeof(nodeobj))` is not a valid node structure type."))
end

# These methods are found in `Extensions` module.
autogenerate(::Union()) = error("Undefined autogenerate method.")
