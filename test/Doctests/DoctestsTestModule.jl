module DoctestsTestModule

"""
!!set(preamble:
x = 1
)

```
a = b
```

```julia
x = 2
sin(x)
```

```julia
sin(x)
```

```julia
t
```
"""
abstract A

"""
```julia
K
```

```julia
f(x) = x^2

const t = 2
f(t)
```
"""
const K = 1

export K

"""

"""
bitstype 8 BT

"""
```julia
rand(2, 2)
```
"""
f(x, y = 1) = x + y

end
