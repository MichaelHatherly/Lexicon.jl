### Handle differences between versions. --------------------------------------------------------

if VERSION < v"0.4.0-dev+2418"
    # returns the index of the previous element for which the function returns true, or zero if it never does
    function findprev(testf::Function, A, start)
        for i = start:-1:1
            testf(A[i]) && return i
        end
        0
    end
    findlast(testf::Function, A) = findprev(testf, A, length(A))
end

if VERSION < v"0.4.0-dev+4393"
    # Return a relative filepath to path either from the current directory or from an optional start directory.
    # This is a path computation: the filesystem is not accessed to confirm the existence or nature of path or startpath.
    function relpath(path::ByteString, startpath::ByteString = ".")
        isempty(path) && throw(ArgumentError("`path` must be specified"))
        isempty(startpath) && throw(ArgumentError("`startpath` must be specified"))
        curdir = "."
        pardir = ".."
        path == startpath && return curdir

        path_arr  = split(abspath(path),      Base.path_separator_re)
        start_arr = split(abspath(startpath), Base.path_separator_re)

        i = 0
        while i < min(length(path_arr), length(start_arr))
            i += 1
            if path_arr[i] != start_arr[i]
                i -= 1
                break
            end
        end

        pathpart = join(path_arr[i+1:findlast(x -> !isempty(x), path_arr)], Base.path_separator)
        prefix_num = findlast(x -> !isempty(x), start_arr) - i - 1
        if prefix_num >= 0
            prefix = pardir * Base.path_separator
            relpath_ = isempty(pathpart)     ?
                (prefix^prefix_num) * pardir :
                (prefix^prefix_num) * pardir * Base.path_separator * pathpart
        else
            relpath_ = pathpart
        end
        return isempty(relpath_) ? curdir :  relpath_
    end
end

if VERSION < v"0.4.0-dev+4499"
    function cptree(src::AbstractString, dst::AbstractString; remove_destination::Bool=false,
                                                                 follow_symlinks::Bool=false)
        isdir(src) || throw(ArgumentError("'$src' is not a directory. Use `cp(src, dst)`"))
        if ispath(dst)
            if remove_destination
                rm(dst; recursive=true)
            else
                throw(ArgumentError(string("'$dst' exists. `remove_destination=true` ",
                                           "is required to remove '$dst' before copying.")))
            end
        end
        mkdir(dst)
        for name in readdir(src)
            srcname = joinpath(src, name)
            if !follow_symlinks && islink(srcname)
                symlink(readlink(srcname), joinpath(dst, name))
            elseif isdir(srcname)
                cptree(srcname, joinpath(dst, name); remove_destination=remove_destination,
                                                     follow_symlinks=follow_symlinks)
            else
                Base.FS.sendfile(srcname, joinpath(dst, name))
            end
        end
    end

    function cp(src::AbstractString, dst::AbstractString; remove_destination::Bool=false,
                                                             follow_symlinks::Bool=false)
        if ispath(dst)
            if remove_destination
                rm(dst; recursive=true)
            else
                throw(ArgumentError(string("'$dst' exists. `remove_destination=true` ",
                                           "is required to remove '$dst' before copying.")))
            end
        end
        if !follow_symlinks && islink(src)
            symlink(readlink(src), dst)
        elseif isdir(src)
            cptree(src, dst; remove_destination=remove_destination, follow_symlinks=follow_symlinks)
        else
            Base.FS.sendfile(src, dst)
        end
    end
end

if endswith(functionloc(isgeneric)[1], "deprecated.jl")
    _isgeneric(x) = true
else
    _isgeneric(x) = isgeneric(x)
end

lsdfield(x :: Function, f)    = _isgeneric(x) ? lsdfield(methods(x), f) : lsdfield(x.code, f)
lsdfield(x :: Method, f)      = lsdfield(x.func, f)
lsdfield(x :: MethodTable, f) = lsdfield(x.defs, f)

lsdfield(x :: LambdaStaticData, f) = getfield(x, f)
