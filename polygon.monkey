Strict

#rem
	Copyright (c) 2011 Matthias Richter

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

' -----------------
' -- Polygon class
' --
Class Polygon

Private

	' create vertex list of coordinate pairs
	Function ToVertexList:Stack<Float[] > (verts:Stack<Float[] >, coords:Float[])
		' verts = New Stack<Float[] > (coords.Length() / 2)
		For Local c:= 0 Until coords.Length() Step 2
			verts.Push([coords[c], coords[c + 1]])
		Next
		Return verts
	End
	
	Function ToVertexList:Stack<Float[] > (coords:Float[])
		Local verts:= New Stack<Float[] > ()
		For Local c:= 0 Until coords.Length() Step 2
			verts.Push([coords[c], coords[c + 1]])
		Next
		Return verts
	End

	' returns true if three vertices lie on a line
	Function AreCollinear:Bool(p:Float[], q:Float[], r:Float[], eps:Float = 1E-16)
		Return Abs(Vector.Det(q[0] - p[0], q[1] - p[1], r[0] - p[0], r[1] - p[1])) <= eps
	End

	' remove vertices that lie on a line
	Function RemoveCollinear:Stack<Float[] > (verts:Stack<Float[] >)
		Local ret:= New Stack<Float[] > ()
		Local count:= verts.Length
		Local i:= count - 2
		Local k:= count - 1
		For Local l:= 0 Until count
			Local vk:= verts.Get(k)
			If Not AreCollinear(verts.Get(i), vk, verts.Get(l)) Then ret.Push(vk)
			i = k
			k = l
		Next
		Return ret
	End

	' get index of rightmost vertex (for testing orientation)
	Function GetIndexOfleftmost:Int(verts:Stack<Float[] >)
		Local idx:= 0
		Local count:= verts.Length
		For Local i:= 1 Until count
			If verts.Get(i)[0] < verts.Get(idx)[0] Then
				idx = i
			EndIf
		Next
		Return idx
	End

	' returns true if three points make a counter clockwise turn
	Function CCW:Bool(p:Float[], q:Float[], r:Float[])
		Return Vector.Det(q[0] - p[0], q[1] - p[1], r[0] - p[0], r[1] - p[1]) >= 0.0
	End

	' test wether a and b lie on the same side of the line c->d
	Function OnSameSide:Bool(a:Float[], b:Float[], c:Float[], d:Float[])
		Local px:= d[0] - c[0]
		Local py:= d[1] - c[1]
		Local l:= Vector.Det(px, py, a[0] - c[0], a[1] - c[1])
		Local m:= Vector.Det(px, py, b[0] - c[0], b[1] - c[1])
		Return l * m >= 0
	End

	Function PointInTriangle:Bool(p:Float[], a:Float[], b:Float[], c:Float[])
		Return OnSameSide(p, a, b, c) And OnSameSide(p, b, a, c) And OnSameSide(p, c, a, b)
	End

	' test whether any point in vertices (but pqr) lies in the triangle pqr
	' note: vertices is *set*, not a list!
	Function AnyPointInTriangle:Bool(vertices:Stack<Float[] >, p:Float[], q:Float[], r:Float[])
		For Local v:= EachIn vertices
			If Not Vector.Eq(v, p) And Not Vector.Eq(v, q) And Not Vector.Eq(v, r) And PointInTriangle(v, p, q, r) Then
				Return True
			EndIf
		Next
		Return False
	End

	' test is the triangle pqr is an "ear" of the polygon
	' note: vertices is *set*, not a list!
	Function IsEar:Bool(p:Float[], q:Float[], r:Float[], vertices:Stack<Float[] >)
		Return CCW(p, q, r) And Not AnyPointInTriangle(vertices, p, q, r)
	End

	Function SegmentsInterset:Bool(a:Float[], b:Float[], p:Float[], q:Float[])
		Return Not (OnSameSide(a, b, p, q) or OnSameSide(p, q, a, b))
	End

	' returns starting/ending indices of shared edge, i.e. if p and q share the
	' edge with indices p1,p2 of p and q1,q2 of q, the return value is p1,q2
	Function GetSharedEdge:Int[] (p:Stack<Float[] >, q:Stack<Float[] >)
	
		Local pindex:= New FloatMap<FloatMap<Int>>()
		Local i:Int
	
		' record indices of vertices in p by their coordinates
		For i = 0 Until p.Length()
			Local pi:= p.Get(i)
			If Not pindex.Contains(pi[0]) Then
				pindex.Set(pi[0], New FloatMap<Int>())
			EndIf
			pindex.Get(pi[0]).Set(pi[1], i)
		Next

		' iterate over all edges in q. if both endpoints of that
		' edge are in p as well, return the indices of the starting
		' vertex
		i = q.Length() -1
		Local k:= 0
		For k = 0 Until q.Length()
			Local v:= q.Get(i)
			Local w:= q.Get(k)
			If pindex.Contains(v[0]) And pindex.Contains(w[0]) Then
				Local ww:= pindex.Get(w[0])
				If ww.Contains(w[1]) And pindex.Get(v[0]).Contains(v[1]) Then Return[ww.Get(w[1]), k]
			EndIf
			i = k
		Next
	
		Return[]
	End
	
	'''''''''

Public
	
	Field vertices:Stack<Float[] >
	Field area:Float
	Field centroid:Float[]
	Field _count:Int
	Field _radius:Float
	Field _isConvex:Int = -1
	
Public
	
	Method Vertices:Stack<Float[] > ()
		Return vertices
		' make vertices immutable
		' TODO setmetatable(Self.vertices, { __newindex = Function() error("Thou shall not change a polygon's vertices!") End })
	End

	Method New(coords:Float[])
		'Print(coords.Length)
		Local verts:= ToVertexList(coords)
		'Print(verts.Length)
		Local vertices:= RemoveCollinear(verts)
		'Print(vertices.Length)
		If vertices.Length() < 3 Then
			Error("Need at least 3 non collinear points To build polygon (got " + vertices.Length + ")")
			Return
		EndIf
		
		_count = vertices.Length()
		
		' assert polygon is oriented counter clockwise
		Local r:= GetIndexOfleftmost(vertices)
		Local t:Int, s:Int
		If r > 0 Then t = r - 1 Else t = _count - 1
		If r < _count - 1 Then
			s = r + 1
		Else
			s = 0
		EndIf
		If Not CCW(vertices.Get(t), vertices.Get(r), vertices.Get(s)) Then ' reverse order If polygon is not ccw
			Local tmp:= New Stack<Float[] > ()
			For Local b:= EachIn vertices.Backwards()
				tmp.Push(b)
			Next
			vertices = tmp
		EndIf
		
		' assert polygon is not self-intersecting
		' outer: only need to check segments #vert;1, 1;2, ..., #vert-3;#vert-2
		' inner: only need to check unconnected segments
		Local q:= vertices.Get(_count - 1)
		Local p:=[0.0, 0.0]
		For Local i:= 0 Until _count - 2
			p = q
			q = vertices.Get(i)
			For Local k:= i + 1 Until _count - 1
				Local a:= vertices.Get(k)
				Local b:= vertices.Get(k + 1)
				If SegmentsInterset(p, q, a, b) Then
					Error("Polygon may not intersect itself")
					Return
				 EndIf
			Next
		Next

		Self.vertices = vertices

		' compute polygon area and centroid
		p = vertices.Get(_count - 1)
		q = vertices.Get(0)
		Local det:= Vector.Det(p, q) ' also used below
		Self.area = det
		For Local i:= 1 Until vertices.Length()
			p = q
			q = vertices.Get(i)
			Self.area = Self.area + Vector.Det(p, q)
		Next
		Self.area = Self.area / 2.0

		p = vertices.Get(_count - 1)
		q = vertices.Get(0)
		Self.centroid =[ (p[0] + q[0]) * det, (p[1] + q[1]) * det]
		For Local i:= 1 Until _count
			p = q
			q = vertices.Get(i)
			det = Vector.Det(p, q)
			Self.centroid[0] += (p[0] + q[0]) * det
			Self.centroid[1] += (p[1] + q[1]) * det
		Next
		Vector.Div(6.0 * Self.area, Self.centroid)

		' get outcircle
		Self._radius = 0
		For Local i:= 1 Until _count
			Local v := vertices.Get(i)
			Self._radius = Max(Self._radius, Vector.Dist(v[0], v[1], Self.centroid[0], Self.centroid[1]))
		Next
	End

	' return vertices as x1,y1,x2,y2, ..., xn,yn
	Method Unpack:Float[] ()
		Local verts:= New Float[_count * 2]
		For Local i:= 0 Until _count
			Local v:= vertices.Get(i)
			verts[2 * i] = v[0]
			verts[2 * i + 1] = v[1]
		Next
		Return verts
	End

	' deep copy of the polygon
	Method Clone:Polygon()
		Return New Polygon(Unpack())
	end
	

	' get bounding box
	Method BBox:Float[] ()
		Local v:= vertices.Get(0)
		Local ulx:= v[0]
		Local uly:= v[1]
		Local lrx:= ulx
		Local lry:= uly
		For Local i:= 1 Until _count
			Local p:= vertices.Get(i)
			If ulx > p[0] Then ulx = p[0]
			If uly > p[1] Then uly = p[1]
			If lrx < p[0] Then lrx = p[0]
			If lry < p[1] Then lry = p[1]
		Next
		Return[ulx, uly, lrx, lry]
	End
	
	' a polygon is convex if all edges are oriented ccw
	Method IsConvex:Bool()
		If _isConvex >= 0 Then Return _isConvex = 1 ' already calculated
		_isConvex = 0 ' 0 = is not convex
		Local v:= vertices
		If _count = 3 Then
			_isConvex = 1 ' 1 = is convex
			Return True
		EndIf
		If Not CCW(v.Get(_count - 1), v.Get(0), v.Get(1)) Then Return False
		For Local i:= 1 Until _count - 1
			If Not CCW(v.Get(i - 1), v.Get(i), v.Get(i + 1)) Then Return False
		Next
		If Not CCW(v.Get(_count - 2), v.Get(_count - 1), v.Get(0)) Then Return False
		_isConvex = 1 ' 1 = is convex
		Return True
	End
	
	Method Move:Void(dx:Float, dy:Float)
		For Local i:= 0 Until _count
			Local v:= vertices.Get(i)
			v[0] += dx
			v[1] += dy
		Next
		Vector.Add(centroid, dx, dy)
	End
		
	Method Move:Void(p:Float[])
		For Local i:= 0 Until _count
			Vector.Add(vertices.Get(i), p)
		Next
		Vector.Add(centroid, p)
	End
	
	Method Rotate:Void(angle:Float)
		For Local i:= 0 Until _count
			Local v:= vertices.Get(i)
			Local r:= Vector.Rotate(angle, v[0] - centroid[0], v[1] - centroid[1])
			vertices.Set(i, Vector.Add(centroid[0], centroid[1], r[0], r[1]))
		Next
	End
	
	Method Rotate:Void(angle:Float, cx:Float, cy:Float)
		For Local i:= 0 Until _count
			Local v:= vertices.Get(i)
			Local r:= Vector.Rotate(angle, v[0] - cx, v[1] - cy)
			vertices.Set(i, Vector.Add(cx, cy, r[0], r[1]))
		Next
		Vector.Add(centroid, Vector.Rotate(angle, centroid[0] - cx, centroid[1] - cy))
	End
	
	Method Scale:Void(s:Float)
		Scale(s, centroid)
	End
	
	Method Scale:Void(s:Float, c:Float[])
		For Local i:= 0 Until _count
			Local v:= vertices.Get(i)
			Local v2:= Vector.Sub(v[0], v[1], c[0], c[1])
			Vector.Mul(s, v2)
			Vector.Add(v2, c)
			vertices.Set(i, v2)
		end
		_radius *= s
	End
	
	Method Scale:Void(s:Float, cx:Float, cy:Float)
		For Local i:= 0 Until _count
			' v.x, v.y = vector.add(cx, cy, vector.mul(s, v.x - cx, v.y - cy))
			Local v:= vertices.Get(i)
			Local v2:= Vector.Sub(v[0], v[1], cx, cy)
			Vector.Mul(s, v2)
			Vector.Add(v2, cx, cy)
			vertices.Set(i, v2)
		end
		_radius *= s
	End
	
	' triangulation by the method of kong
	Method Triangulate:Stack<Polygon>()
		If _count = 3 Then
			Local ret:= New Stack<Polygon>()
			ret.Push(Clone())
			Return ret
		EndIf
		Local verts:= vertices
		
		Local next_idx:= New Int[_count]
		Local prev_idx:= New Int[_count]
		For Local i:= 0 Until _count
			next_idx[i] = i + 1
			prev_idx[i] = i - 1
		Next
		next_idx[_count - 1] = 1
		prev_idx[0] = _count - 1
		
		Local concave:= New Stack<Float[] > () ' New Bool[_count]
		For Local i:= 0 Until _count
			Local v:= verts.Get(i)
			If Not CCW(verts.Get(prev_idx[i]), v, verts.Get(next_idx[i])) Then
				concave.Push(v)
			EndIf
		Next
		
		Local p:Float[], q:Float[], r:Float[]
		Local triangles:= New Stack<Polygon>()
		Local n_vert:= _count
		Local current:= 0
		Local skipped:= 0
		Local nxt:Int, prv:Int
		Local lastConcaveRemoveIdx:= 0
		While n_vert > 3
			nxt = next_idx[current]
			prv = prev_idx[current]
			p = verts.Get(prv)
			q = verts.Get(current)
			r = verts.Get(nxt)
			If IsEar(p, q, r, concave) Then
				triangles.Push(New Polygon([p[0], p[1], q[0], q[1], r[0], r[1]]))
				next_idx[prv] = nxt
				prev_idx[nxt] = prv
				
				' concave.RemoveEach(q)
				For Local i:= lastConcaveRemoveIdx Until concave.Length()
					If Vector.Eq(concave.Get(i), q) Then
						concave.Remove(i)
						lastConcaveRemoveIdx = i + 1
						Exit
					 EndIf
				Next
				
				n_vert -= 1
				skipped = 0
			Else
				skipped += 1
				If skipped > n_vert Then
					Error("Cannot triangulate polygon")
					Return Null
				EndIf
			EndIf
			current = nxt
		Wend
		
		nxt = next_idx[current]
		prv = prev_idx[current]
		p = vertices.Get(prv)
		q = vertices.Get(current)
		r = vertices.Get(nxt)
		triangles.Push(New Polygon([p[0], p[1], q[0], q[1], r[0], r[1]]))
		
		Return triangles
	End
	

	' return merged polygon if possible or nil otherwise
	Method MergedWith:Polygon(other:Polygon)
		Local e:= GetSharedEdge(vertices, other.vertices)
		
		If e.Length() = 0 Then
			'Print("Polygons do not share an edge")
			Return Null
		EndIf
		e[0] += 1
		e[1] += 1
	
		Local ret:= New Float[ (other._count + _count - 2) * 2]
		Local r:= 0
		For Local i:= 1 To e[0] - 1
			Local v:= vertices.Get(i - 1)
			ret[r + 0] = v[0]
			ret[r + 1] = v[1]
			r += 2
		Next
		For Local i:= 0 To other._count - 2
			Local v:= other.vertices.Get( ( (i - 1 + e[1]) Mod other._count))
			ret[r + 0] = v[0]
			ret[r + 1] = v[1]
			r += 2
		Next
		For Local i:= e[0] + 1 To _count
			Local v:= vertices.Get(i - 1)
			ret[r + 0] = v[0]
			ret[r + 1] = v[1]
			r += 2
		Next
		
		Return New Polygon(ret)
	end
	

	' split polygon into convex polygons.
	' note that this won't be the optimal split in most cases, as
	' finding the optimal split is a really hard problem.
	' the method is to first triangulate and then greedily merge
	' the triangles.
	Method SplitConvex:Stack<Polygon>()
		' edge case: polygon is a triangle or already convex
		If _count <= 3 or IsConvex() Then
			Local ret:= New Stack<Polygon>()
			ret.Push(Clone())
			Return ret
		End

		Local convex:= Triangulate()
		Local i:= 0
		Repeat
			Local p:= convex.Get(i)
			Local k:= i + 1
			While k < convex.Length()
				Local merged:= p.MergedWith(convex.Get(k))
				If merged <> Null And merged.IsConvex() Then
					convex.Set(i, merged)
					p = convex.Get(i)
					convex.Remove(k)
				Else
					k = k + 1
				EndIf
			Wend
			i += 1
		Until i > convex.Length
	
		return convex
	End
	
	Private
	
	' test if an edge cuts the ray
	Function cut_ray:Bool(x:Float, y:Float, p:Float[], q:Float[])
		Return ( (p[1] > y and q[1] < y) or (p[1] < y and q[1] > y)) and (x - p[0] < (y - p[1]) * (q[0] - p[0]) / (q[1] - p[1]))
	End

	' test if the ray crosses boundary from interior to exterior.
	' this is needed due to edge cases, when the ray passes through
	' polygon corners
	Function cross_boundary:Bool(x:Float, y:Float, p:Float[], q:Float[])
		Return (p[1] = y and p[0] > x and q[1] < y) or (q[1] = y and q[0] > x and p[1] < y)
	End
	
	Public
	
	Method Contains:Bool(x:Float, y:Float)
		Local v:= vertices
		Local in_polygon:= False
		Local p:= v[_count - 1]
		Local q:= v[_count - 1]
		For Local i:= 0 Until _count
			p = q
			q = v[i]
			If cut_ray(x, y, p, q) Or cross_boundary(x, y, p, q) Then
				in_polygon = Not in_polygon
			EndIf
		Next
		Return in_polygon
	End
	
	Method IntersectionsWithRay:FloatStack(x:Float, y:Float, d:Float[])
		Local n:= Vector.Perpendicular(d)
		Local w:= New Float[2]
		Local det:Float

		Local ts:= New FloatStack() ' ray parameters of each intersection
		Local q1:Float[]
		Local q2:= vertices[_count - 1]
		For Local i:= 0 Until Count
			q1 = q2
			q2 = vertices[i]
			w[0] = q2[0] - q1[0]
			w[1] = q2[1] - q1[1]
			det = Vector.Det(d, w)

			If det <> 0 Then
				' there is an intersection point. check if it lies on both
				' the ray and the segment.
				Local r:=[q2[0] - x, q2[1] - y]
				Local l:= Vector.Det(r, w) / det
				Local m:= Vector.Det(d, r) / det
				If m >= 0 and m <= 1 Then
					' we cannot jump out early here (i.e. when l > tmin) because
					' the polygon might be concave
					ts.Push(l)
				EndIf
			else
				' lines parralel or incident. get distance of line to
				' anchor point. if they are incident, check if an endpoint
				' lies on the ray
				Local dist:= Vector.Dot(q1[0] - x, q1[1] - y, n[0], n[1])
				If dist = 0 Then
					Local l:= Vector.Dot(d[0], d[1], q1[0] - x, q1[1] - y)
					Local m:= Vector.Dot(d[0], d[1], q2[0] - x, q2[1] - y)
					If l >= m Then
						ts.Push(l)
					Else
						ts.Push(m)
					EndIf
				EndIf
			EndIf
		end

		return ts
	end
	
	Method IntersectsRay:Float[] (x:Float, y:Float, d:Float[])
		Local tmin:= math_huge
		For Local t:= EachIn IntersectionsWithRay(x, y, dx)
			tmin = Min(tmin, t)
		Next
		If tmin <> math_huge Then Return[tmin]
		Return Null
	End
	
End