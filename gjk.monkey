Strict

#rem
	Copyright (c) 2012 Matthias Richter

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:
	
	The above copyright notice and this permission notice shall be included in
	all copies or substantial portions of the Software.
	
	Except as contained in this notice, the name(s) of the above copyright holders
	shall not be used in advertising or otherwise to promote the sale, use or
	other dealings in this Software without prior written authorization.
	
	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
	THE SOFTWARE.
#end

Import vectorlight
Import shapes

Global math_huge:Float = 9999999999999.0

Function Support:Float[] (shape_a:Shape, shape_b:Shape, dx:Float, dy:Float)
	Local a:= shape_a.Support(dx, dy)
	Local b:= shape_b.Support(-dx, -dy)
	Vector.Sub(a, b)
	Return a
End

' returns closest edge to the origin
Function ClosestEdge:Float[] (simplex:FloatStack)
	Local edge:=[0.0, 0.0, math_huge, 0] ' 2 = dist, 3 = i
	Local i:= simplex.Length - 2
	For Local k:= 0 Until simplex.Length - 1 Step 2
		Local ax:= simplex.Get(i)
		Local ay:= simplex.Get(i + 1)
		Local bx:= simplex.Get(k)
		Local by:= simplex.Get(k + 1)
		i = k
		Local e:= Vector.Perpendicular(bx - ax, by - ay)
		Vector.Normalize(e)
		Local d:= Vector.Dot(ax, ay, e[0], e[1])
		If d < edge[2] Then
			edge[0] = e[0]
			edge[1] = e[1]
			edge[2] = d
			edge[3] = k
		EndIf
	Next
	Return edge
End

' returns closest edge to the origin
Function ClosestEdge:Float[] (simplex:Float[])
	Local edge:=[0.0, 0.0, math_huge, 0] ' 2 = dist, 3 = i
	Local i:= simplex.Length - 2
	For Local k:= 0 Until simplex.Length - 2 Step 2
		Local ax:= simplex[i]
		Local ay:= simplex[i + 1]
		Local bx:= simplex[k]
		Local by:= simplex[k + 1]
		i = k
		Local e:= Vector.Perpendicular(bx - ax, by - ay)
		Vector.Normalize(e)
		Local d:= Vector.Dot(ax, ay, e[0], e[1])
		If d < edge[2] Then
			edge[0] = e[0]
			edge[1] = e[1]
			edge[2] = d
			edge[3] = k
		EndIf
	Next
	Return edge
End

Function EPA:Float[] (shape_a:Shape, shape_b:Shape, simplex:Float[])
	' make sure simplex is oriented counter clockwise
	Local cx:= simplex[0], cy:= simplex[1]
	If Vector.Dot(simplex[4] - simplex[2], simplex[5] - simplex[3], cx - simplex[2], cy - simplex[3]) < 0.0 Then
		simplex[0] = simplex[4]
		simplex[1] = simplex[5]
		simplex[4] = cx
		simplex[5] = cy
	EndIf
	
	' the expanding polytype algorithm
	Local is_either_circle:= shape_a._type = "circle" or shape_b._type = "circle"
	Local last_diff_dist:= math_huge
	Local resizableSimplex:= New FloatStack();
	resizableSimplex.Push(simplex)
	' Local i:= 0 ' TEST
	Repeat
		Local edge:= ClosestEdge(resizableSimplex)
		Local p:= Support(shape_a, shape_b, edge[0], edge[1])
		Local d:= Vector.Dot(p, edge)
		Local diff_dist:= d - edge[2]
		'If is_either_circle Then Print(i + " -> " + Int(edge[3]) + " -> " + resizableSimplex.Length() + " -- " + diff_dist + " Or " + last_diff_dist + " -> " + Abs(last_diff_dist - diff_dist))
		' i += 1
		If diff_dist < 1E-6 Or (is_either_circle And Abs(last_diff_dist - diff_dist) < 1E-10) Or resizableSimplex.Length() > 100 Then
			Return Vector.Mul(-d, edge[0], edge[1])
		EndIf
		last_diff_dist = diff_dist
		' simplex = {..., simplex[edge.i-1], px, py, simplex[edge.i]
		resizableSimplex.Insert(Int(edge[3]), p[1])
		resizableSimplex.Insert(Int(edge[3]), p[0])
	Forever
End

'   :      :     origin must be in plane between A and B
' B o------o A   since A is the furthest point on the MD
'   :      :     in direction of the origin.
Function DoLine:Float[][] (simplex:Float[])
	Local bx:= simplex[0], by:= simplex[1]
	Local ax:= simplex[2], ay:= simplex[3]
	Local abx:= bx - ax
	Local aby:= by - ay
	Local d:= Vector.Perpendicular(abx, aby)
	If Vector.Dot(d[0], d[1], -ax, -ay) < 0.0 Then Vector.Mul(-1.0, d)
	Return[simplex, d]
End

' B .'
'  o-._  1
'  |   `-. .'     The origin can only be in regions 1, 3 or 4:
'  |  4   o A 2   A lies on the edge of the MD and we came
'  |  _.-' '.     from left of BC.
'  o-'  3
' C '.
Function DoTriangle:Float[] (simplex:FloatStack)
#if debug
	If simplex.Length() < 6 Then Print("error with DoTriangle " + simplex.Length())
#end
	Local cx:= simplex.Get(0), cy:= simplex.Get(1)
	Local bx:= simplex.Get(2), by:= simplex.Get(3)
	Local ax:= simplex.Get(4), ay:= simplex.Get(5)
	Local aox:= -ax, aoy:= -ay
	Local abx:= bx - ax, aby:= by - ay
	Local acx:= cx - ax, acy:= cy - ay

	' test region 1
	Local d:= Vector.Perpendicular(abx, aby)
	If Vector.Dot(d[0], d[1], acx, acy) > 0.0 Then Vector.Mul(-1.0, d)
	If Vector.Dot(d[0], d[1], aox, aoy) > 0.0 Then
		' simplex = {bx,by, ax,ay}
		simplex.Set(0, bx); simplex.Set(1, by)
		simplex.Set(2, ax); simplex.Set(3, ay)
		'simplex.Remove(4); simplex.Remove(5)
		simplex.Length(4)
		Return d
	end

	' test region 3
	d = Vector.Perpendicular(acx, acy)
	If Vector.Dot(d[0], d[1], abx, aby) > 0.0 Then Vector.Mul(-1.0, d)
	If Vector.Dot(d[0], d[1], aox, aoy) > 0.0 Then
		' simplex = {cx,cy, ax,ay}
		simplex.Set(2, ax); simplex.Set(3, ay)
		simplex.Length(4)
		'If simplex.Length() > 4 Then
		'simplex.Remove(4); simplex.Remove(5)
		'EndIf
		Return d
	End

	' must be in region 4
	Return d
end

Function GJK:Float[] (shape_a:Shape, shape_b:Shape)
	Local a:= Support(shape_a, shape_b, 1, 0)
	If a[0] = 0 and a[1] = 0 Then
		' only true if shape_a and shape_b are touching in a vertex, e.g.
		'  .---                .---.
		'  | A |           .-. | B |   support(A, 1,0)  = x
		'  '---x---.  or  : A :x---'   support(B, -1,0) = x
		'      | B |       `-'         => support(A,B,1,0) = x - x = 0
		'      '---'
		' Since CircleShape:support(dx,dy) normalizes dx,dy we have to opt
		' out or the algorithm blows up. In accordance to the cases below
		' choose to judge this situation as not colliding.
		Return[]
	End

	Local simplex:= New FloatStack();
	simplex.Push(a)
	Local n:= 2
	Local d:= Vector.Mul(-1.0, a[0], a[1])

	' first iteration: line case
	a = Support(shape_a, shape_b, d[0], d[1])
	If Vector.Dot(a, d) <= 0.0 Then Return[]

	SaveSetFloatStack(simplex, n + 0, a[0])
	SaveSetFloatStack(simplex, n + 1, a[1])
	a[0] = simplex.Get(2)
	a[1] = simplex.Get(3)
	' same as DoLine()
	d = Vector.Perpendicular(simplex.Get(0) - a[0], simplex.Get(1) - a[1])
	If Vector.Dot(d[0], d[1], -a[0], -a[1]) < 0.0 Then Vector.Mul(-1.0, d)
	n = 4

	' all other iterations must be the triangle case
	Repeat
		a = Support(shape_a, shape_b, d[0], d[1])
		If Vector.Dot(a, d) <= 0.0 Then Return[]
		
		SaveSetFloatStack(simplex, n + 0, a[0])
		SaveSetFloatStack(simplex, n + 1, a[1])
		d = DoTriangle(simplex)
		n = simplex.Length
		If n = 6 Then
			Local epa:= EPA(shape_a, shape_b, simplex.ToArray())
			Return[epa[0], epa[1]]
		EndIf
		'Return[-1.0] ' for test only, DELETE
	Forever
End

Private

Function SaveSetFloatStack:Void(stack:FloatStack, idx:Int, value:Float)
	If stack.Length() < idx + 1 Then stack.Length(idx + 1)
	stack.Set(idx, value)
End

Public