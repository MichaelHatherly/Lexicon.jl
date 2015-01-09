"f"
:f

"f/0"
f() = ()

"f/1"
f(x) = ()

"g"
:g

"g/0"
g() = ()

"g/1"
g(x) = ()

"K"
const K = ()

"@m"
macro m()
end

"T"
type T
end

module A

using Docile
@document

"A.f"
:f

"A.f/0"
f() = ()

"A.f/1"
f(x) = ()

"A.g"
:g

"A.g/0"
g() = ()

"A.g/1"
g(x) = ()

"A.K"
const K = ()

"A.@m"
macro m()
end

"A.T"
type T
end

module B

using Docile
@document

"A.B.f"
:f

"A.B.f/0"
f() = ()

"A.B.f/1"
f(x) = ()

"A.B.g"
:g

"A.B.g/0"
g() = ()

"A.B.g/1"
g(x) = ()

"A.B.K"
const K = ()

"A.B.@m"
macro m()
end

"A.B.T"
type T
end

end

end
