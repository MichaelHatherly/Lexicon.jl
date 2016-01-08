module TestCases

using Docile
@document

"f/0"
f() = ()

"f/1"
f(x) = ()

"f"
f

"g/0"
g() = ()

"g/1"
g(x) = ()

"g"
g

"K"
const K = ()

"@m"
macro m()
end

"S"
abstract S

"T"
type T
end

module A

using Docile
@document

"A.f/0"
f() = ()

"A.f/1"
f(x) = ()

"A.f"
f

"A.g/0"
g() = ()

"A.g/1"
g(x) = ()

"A.g"
g

"A.K"
const K = ()

"A.@m"
macro m()
end

"A.S"
abstract S

"A.T"
type T
end

module B

using Docile
@document

"A.B.f/0"
f() = ()

"A.B.f/1"
f(x) = ()

"A.B.f"
f

"A.B.g/0"
g() = ()

"A.B.g/1"
g(x) = ()

"A.B.g"
g

"A.B.K"
const K = ()

"A.B.@m"
macro m()
end

"A.B.S"
abstract S

"A.B.T"
type T
end

end

end

end
