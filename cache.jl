using Random
using BenchmarkTools

mutable struct kd_node
    d::Int

    lchild::kd_node
    rchild::kd_node

    point::Vector{Float64}
    cost::Float64

    balance::Int

    kd_node(point, cost) = kd_node(1, point, cost)
    function kd_node(d, point, cost)
         n = new()
         n.d = d
         n.point = point
         n.cost = cost
         n.balance = 0
         return n
    end
end

mutable struct cache
    tree::kd_node

    size::Int

    hits::Int
    accesses::Int

    total_add_time::Float64
    total_find_time::Float64

    function cache() 
        c = new()
        c.size = 0
        c.hits = 0
        c.accesses = 0

        c.total_add_time = 0.0
        c.total_find_time = 0.0

        return c
    end
end

hit_rate(cache) = cache.hits/cache.accesses
average_add_time(cache) = cache.total_add_time / cache.size
average_find_time(cache) = cache.total_find_time / cache.accesses

function add_node(c::cache, point::Vector{T}, cost::T) where T <: Number
    if !isdefined(c, :tree)
        c.tree = kd_node(point, cost)
    else
        t1 = time()
        add_node(c.tree, point, cost, 1)
        c.total_add_time += time() - t1
    end

    c.size += 1
end

function find_node(c::cache, point::Vector{T}) where T <: Number
    c.accesses += 1
    cost = find_node(c.tree, point)
    cost != nothing && (c.hits += 1)
    return cost 
end

depth(c::cache) = depth(c.tree)
depth(t::kd_node) = max(isdefined(t, :lchild) ? depth(t.lchild) + 1 : 1, 
                        isdefined(t, :rchild) ? depth(t.rchild) + 1 : 1)

is_balanced(c::cache) = is_balanced(c.tree)
is_balanced(t::kd_node) = abs((isdefined(t, :lchild) ? depth(t.lchild) : 0 ) -
                              (isdefined(t, :rchild) ? depth(t.rchild) : 0)) in [0,1]

get_target(t::kd_node, p::Vector) = p[t.d] <= t.point[t.d] ? :lchild : :rchild

function add_node(tree::kd_node, point::Vector{T}, cost::T, depth::Int) where T <: Number
    target = get_target(tree,point)
    if isdefined(tree, target)
        add_node(getfield(tree, target), point, cost, depth+1)
    else
        setfield!(tree, target, kd_node(tree.d % length(point) + 1, point, cost))
    end
    target == :lchild ? (tree.balance -= 1) : (tree.balance += 1)
    balance(tree)
end

function find_node(tree::kd_node, point::Vector{T}; tolerance=1e-13
                  )::Union{Nothing, T}  where T <: Number
    if in_tolerance(tree, point, tolerance)
        return tree.cost
    else
        target = get_target(tree,point)

        if !isdefined(tree, target)
            return nothing
        end

        return find_node(getfield(tree, target), point; tolerance)
    end
end

function in_tolerance(tree::kd_node, point::Vector, tolerance)::Bool where T
    for (i,v) in enumerate(point)
        if v > tree.point[i] + tolerance || v < tree.point[i] - tolerance
            return false
        end
    end
    return true
end

