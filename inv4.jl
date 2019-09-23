known_inversions = Dict()

#invert: (X -> Y) -> (Y * (param_type) -> X)
invert(f) = known_inversions[f]

plus(x::Array) = [x[1] + x[2]]
plus_inv(y::Array, th) = [y[1] - th, th]
square(x::Array) = [x[1]^2]
square_inv(y::Array, th) = [th in [-1, 1] ? th * y[1]^0.5 : error("square inverse parameter must be 1 or -1")]

dupl(n::Int64) = function(x::Array) 
	[x[1] for i in 1:n]
end
dupl_inv(n::Int64) = function(arr::Array, th)
	for i in 1:length(arr)
		if arr[i] != arr[1]
			error("dupl inverse failed")
		end
	end
	return arr[1]
end

dupl1 = dupl(1)
dupl2 = dupl(2)

prod(x::Array) = x[1] * x[2]
function prod_inv(y::Array, th)
	if th[1] == 0
		error("")
	elseif (th[2] != 0) && (th[2] != 1)
		error("")
	else
		return th[2] == 0 ? (y[1]/th[1], th[1]) : (th[1], y[1]/th[1])
	end
end

known_inversions[plus] = plus_inv
known_inversions[square] = square_inv
known_inversions[dupl1] = dupl_inv(1)
known_inversions[dupl2] = dupl_inv(2)
known_inversions[prod] = prod_inv

struct FuncExpr
	vars::Array{Symbol}
	func
	args::Array{Symbol}
end

compile(expr::FuncExpr) = Expr(:(=), Expr(:tuple, expr.vars...), Expr(:call, expr.func, [eval(arg) for arg in expr.args]))

function invert_and_assign_exp(expr::FuncExpr, th)
	arg_vals = invert(expr.func)([eval(var) for var in expr.vars], th)
	for i in 1:length(expr.args)
		eval(:($(expr.args[i]) = $(arg_vals[i])))
	end
end

function compile_prog(program, input_vars, output_vars)
	function run_prog(input_vals)
		for i in 1:length(input_vars)
			eval(Expr(:(=), input_vars[i], input_vals[i]))
		end
		for expr in program
			eval(compile(expr))
		end
		output_vals = []
		for output_var in output_vars
			push!(output_vals, eval(output_var))
		end
		return output_vals
	end
end

#=
program = Array{Exp}
input_vars = Array{Symbol}
output_vars = Array{Symbol}
=#
function invert_prog(program, input_vars, output_vars)
	# output_vals = Array{Number}
	function inv_fun(output_vals, params)
		for i in 1:length(output_vals)
			eval(:($(output_vars[i]) = $(output_vals[i])))
		end
		for i in length(program):-1:1
			invert_and_assign_exp(program[i], params[i])
		end
		input_result = []
		for input_var in input_vars
			push!(input_result, eval(input_var))
		end
		return input_result
	end
	return inv_fun
end


# y = x^2
prog1 = [
	FuncExpr([:y], square, [:x])
]
in1 = [:x]
out1 = [:y]
prog1_inv = invert_prog(prog1, in1, out1)
x, = prog1_inv([4], [1])
println(compile_prog(prog1, in1, out1)([x]))

#= 
z = xy + x
-------------
t2, t3 = dupl(2)(x)
t4, = dupl(1)(y)
t1 = t3 * t4
z = t1 + t2
=#
prog2 = [
	FuncExpr([:t2, :t3], dupl2, [:x]),
	FuncExpr([:t4], dupl1, [:y]),
	FuncExpr([:t1], prod, [:t3, :t4]),
	FuncExpr([:z], plus, [:t1, :t2])
]
in2 = [:x, :y]
out2 = [:z]
prog2_inv = invert_prog(prog2, in2, out2)
x, y = prog2_inv([8], [nothing, nothing, [3, 0], 2])
println(compile_prog(prog2, in2, out2)([x, y]))

# y = (x^2)^2
prog3 = [
	FuncExpr([:t1], square, [:s])
	FuncExpr([:y], square, [:t1])
]
in3 = [:x]
out3 = [:y]
prog3_inv = invert_prog(prog3, in3, out3)
x, = prog3_inv([16], [1, 1])
println(compile_prog(prog3, in3, out3)([x]))

