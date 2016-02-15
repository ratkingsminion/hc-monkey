Strict

#Rem
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
#End

Import vectorlight
Import polygon
Import gjk
Import spatialhash
Import mojo2

'' base class

Class Shape

	Field _type:String
	Field _rotation:Float
	Field hash:Spatialhash
	
Private

	' Field curBox:Float[] ' TODO
	Field _id:Int
	Global _idCounter:Int

Public
	
	Method New(t:String)
		_type = t
		_rotation = 0
		_id = _idCounter
		_idCounter += 1
	End

	Method MoveTo:Void(x:Float, y:Float)
		Local center:= Center()
		Move(x - center[0], y - center[1])
	End
	
	Method Rotation:Float()
		Return _rotation
	End
	
	Method SetRotation:Void(angle:Float)
		Rotate(angle - _rotation)
	End
	
	Method SetRotation:Void(angle:Float, x:Float, y:Float)
		Rotate(angle - _rotation, x, y)
	End
	

	'' collision functions
	
	Method Support:Float[] (dx:Float, dy:Float)
		Return[]
	End
	
	Method CollidesWith:Float[] (other:Shape)
		Return[]
	End

 	Method IntersectsRay:Float[] (x:Float, y:Float, d:Float[])
		Return []
	End

	Method IntersectionsWithRay:Float(x:Float, y:Float, d:Float[])
		Return[]
	End
	
	' auxiliary
	
	Method Center:Float[] ()
		Return[]
	End

	Method Outcircle:Float[] ()
		Return[]
	End

	Method BBox:Float[] ()
		Return[]
	End
	
	Method Move:Void(x:Float, y:Float)
		If x = 0.0 And y = 0.0 Then Return
		If hash Then
			Local oldBox:= BBox()
			_Move(x, y)
			hash.Update(Self, oldBox, BBox())
		Else
			_Move(x, y)
		EndIf
	End
	
	Method Rotate:Void(angle:Float)
		If angle = 0.0 Then Return
		If hash Then
			Local oldBox:= BBox()
			_Rotate(angle)
			hash.Update(Self, oldBox, BBox())
		Else
			_Rotate(angle)
		EndIf
	End
	
	Method Rotate:Void(angle:Float, x:Float, y:Float)
		If angle = 0.0 Then Return
		If hash Then
			Local oldBox:= BBox()
			_Rotate(angle, x, y)
			hash.Update(Self, oldBox, BBox())
		Else
			_Rotate(angle, x, y)
		EndIf
	End
	
	Method Scale:Void(s:Float)
		If s = 1.0 Then Return
		If hash Then
			Local oldBox:= BBox()
			_Scale(s)
			hash.Update(Self, oldBox, BBox())
		Else
			_Scale(s)
		EndIf
	End
	
Private

	Method _Move:Void(x:Float, y:Float)
	End
	
	Method _Rotate:Void(angle:Float)
		_rotation += angle
	End
	
	Method _Rotate:Void(angle:Float, x:Float, y:Float)
		_rotation += angle
	End
	
	Method _Scale:Void(s:Float)
	End
	
Public
	
	Method Draw:Void(canvas:Canvas, mode:String)
	End
End



'' class definitions

Class ConvexPolygonShape Extends Shape
	Field _polygon:Polygon
	
	Method New(poly:Polygon)
		Super.New("polygon")
		If Not poly.IsConvex() Then
			Error("Polygon is not convex!")
			Return
		End
		_polygon = poly
	End

	'' collision functions

	Method Support:Float[] (dx:Float, dy:Float)
		Local verts:= _polygon.vertices
		Local max:= -math_huge
		Local vmax:Float[]
		For Local i:= verts.Length() -1 To 0 Step - 1
			Local d:= Vector.Dot(verts.Get(i), dx, dy)
			If d > max Then
				max = d
				vmax = verts.Get(i)
			EndIf
		Next
		Return[vmax[0], vmax[1]] ' needs to be a copy!
	End

	Method CollidesWith:Float[] (other:Shape)
		If Self = other Then Return[]
		If other._type <> "polygon" Then Return other.CollidesWith(Self)
		' else: type is POLYGON
		Return GJK(Self, other)
	End
	
	' point location/ray intersection
	Method Contains:Bool(x:Float, y:Float)
		Return _polygon.Contains(x, y)
	End

	Method IntersectsRay:Float[] (x:Float, y:Float, d:Float[])
		Return _polygon.IntersectsRay(x, y, d)
	End
	
	Method IntersectionsWithRay:Float(x:Float, y:Float, d:Float[])
		Return _polygon.IntersectionsWithRay(x, y, d)
	End

	Method Center:Float[] ()
		Return[_polygon.centroid[0], _polygon.centroid[1]] ' return copy
	End

	Method Outcircle:Float[] ()
		return [_polygon.centroid[0], _polygon.centroid[1], _polygon._radius]
	End

	Method BBox:Float[] ()
		Return _polygon.BBox()
	End
	
Private
	
	Method _Move:Void(x:Float, y:Float)
		_polygon.Move(x, y)
	End
		
	Method _Rotate:Void(angle:Float)
		Local c:= Center()
		_Rotate(angle, c[0], c[1])
	End
	
	Method _Rotate:Void(angle:Float, cx:Float, cy:Float)
		_rotation += angle
		_polygon.Rotate(angle, cx, cy)
	End

	Method _Scale:Void(s:Float)
		If s <= 0 Then
			Print("Invalid argument. Scale must be greater than 0")
			Return
		EndIf
		_polygon.Scale(s, Center())
	End

Public

	Method Draw:Void(canvas:Canvas, mode:String = "line")
		If mode = "fill" Then
			canvas.DrawPoly(_polygon.Unpack())
		Else
			For Local t:= 0 Until _polygon._count
				Local t0:= _polygon.vertices.Get(t)
				Local t1:= _polygon.vertices.Get( (t + 1) Mod _polygon._count)
				canvas.DrawLine(t0[0], t0[1], t1[0], t1[1])
			Next
		EndIf
	end
End



Class ConcavePolygonShape Extends Shape
	Field _polygon:Polygon
	Field _shapes:Stack<Shape>
	
	Method New(poly:Polygon)
		Super.New("compound")
		_polygon = poly
		Local polys:= poly.SplitConvex()
		_shapes = New Stack<Shape>()
		For Local p:= EachIn polys
			_shapes.Push(New ConvexPolygonShape(p))
		Next
	End

	'' collision functions
	
	Method CollidesWith:Float[] (other:Shape)
		If Self = other Then Return[]
		If other._type = "point" Then Return other.CollidesWith(Self)

		' TODO: better way of doing this. report all the separations?
		Local collide:= False
		Local dx:= 0.0, dy:= 0.0
		For Local s:= EachIn _shapes
			Local collData:= s.CollidesWith(other)
			If collData.Length() > 0 Then
				collide = True
				If Abs(dx) < Abs(collData[0]) Then dx = collData[0]
				If Abs(dy) < Abs(collData[1]) Then dy = collData[1]
			EndIf
		Next
		If collide Then Return[dx, dy]
		Return[]
	End
	
	' point location/ray intersection
	Method Contains:Bool(x:Float, y:Float)
		Return _polygon.Contains(x, y)
	End
	
	Method IntersectsRay:Float[] (x:Float, y:Float, dx:Float, dy:Float)
		return _polygon.IntersectsRay(x,y, dx,dy)
	End
	
	Method IntersectionsWithRay:Float(x:Float, y:Float, d:Float[])
		Return _polygon.IntersectionsWithRay(x, y, d)
	End

	Method Center:Float[] ()
		Return[_polygon.centroid[0], _polygon.centroid[1]] ' return copy
	End

	Method Outcircle:Float[] ()
		return [_polygon.centroid[0], _polygon.centroid[1], _polygon._radius]
	End
	
	Method BBox:Float[] ()
		Return _polygon.BBox()
	End
	
Private

	Method _Move:Void(x:Float, y:Float)
		_polygon.Move(x, y)
		For Local p:= EachIn _shapes
			p.Move(x, y)
		Next
	End
		
	Method _Rotate:Void(angle:Float)
		Local c:= Center()
		_Rotate(angle, c[0], c[1])
	End
	
	Method _Rotate:Void(angle:Float, cx:Float, cy:Float)
		_rotation += angle
		_polygon.Rotate(angle, cx, cy)
		For Local p:= EachIn _shapes
			p.Rotate(angle, cx, cy)
		Next
	End


	Method _Scale:Void(s:Float)
		If s <= 0.0 Then
			Print("Invalid argument. Scale must be greater than 0")
			Return
		EndIf
		Local c:= Center()
		_polygon.Scale(s, c[0], c[1])
		For Local p:= EachIn _shapes
			Local pc:= p.Center()
			Local d:= Vector.Sub(c[0], c[1], pc[0], pc[1])
			p.Scale(s)
			p.MoveTo(c[0] - d[0] * s, c[1] - d[1] * s)
		End
	End
	
Public

	Method Draw:Void(canvas:Canvas, mode:String = "line")
		If mode = "fill" Then
			For Local ss:= EachIn _shapes
				Local s:= ConvexPolygonShape(ss)
				If s <> Null Then s.Draw(canvas, mode)
			Next
		Else
			For Local ss:= EachIn _shapes
				Local s:= ConvexPolygonShape(ss)
				If s <> Null Then
					For Local t:= 0 Until s._polygon._count
						Local t0:= s._polygon.vertices.Get(t)
						Local t1:= s._polygon.vertices.Get( (t + 1) Mod s._polygon._count)
						canvas.DrawLine(t0[0], t0[1], t1[0], t1[1])
					Next
				EndIf
			Next
		EndIf
	End
End

Class CircleShape Extends Shape
	Field _center:Float[]
	Field _radius:Float
	
	Method New(cx:Float, cy:Float, radius:Float)
		Super.New("circle")
		_center =[cx, cy]
		_radius = radius
	End

	'' collision functions

	Method Support:Float[] (dx:Float, dy:Float)
		Local v:= Vector.Normalize(dx, dy)
		Vector.Mul(_radius, v)
		Vector.Add(v, _center)
		Return v
	End
	
	Method CollidesWith:Float[] (other:Shape)
		If Self = other Then Return[]
		If other._type = "circle" Then
			Local otherCircle:= CircleShape(other)
			Local p:=[_center[0] - otherCircle._center[0], _center[1] - otherCircle._center[1]]
			Local d:= Vector.Len2(p)
			Local radii:= _radius + otherCircle._radius
			If d < radii * radii Then
				' if circles overlap, push it out upwards
				If d = 0 Then Return[0.0, radii]
				' otherwise push out in best direction
				Vector.Normalize(p)
				Vector.Mul(radii - Sqrt(d), p)
				Return p
			EndIf
			Return[]
		ElseIf other._type = "polygon" Then
			Return GJK(Self, other)
		End
		' else: let the other shape decide
		Local collData:= other.CollidesWith(Self)
		If collData.Length() > 0 Then Return[ - collData[0], -collData[1]]
		Return[]
	End

	Method Contains:Bool(x:Float, y:Float)
		Return Vector.Len2(x - _center.x, y - _center.y) < _radius * _radius
	End
	
	' circle intersection if distance of ray/center is smaller
	' than radius.
	' with r(s) = p + d*s = (x,y) + (dx,dy) * s defining the ray and
	' (x - cx)^2 + (y - cy)^2 = r^2, this problem is eqivalent to
	' solving [with c = (cx,cy)]:
	'     d*d s^2 + 2 d*(p-c) s + (p-c)*(p-c)-r^2 = 0
	Method IntersectionsWithRay:Float[] (x:Float, y:Float, d:Float[])
		Local pcx:= x - _center.x
		Local pcy:= y - _center.y
		Local a:= Vector.Len2(d)
		Local b:= 2.0 * Vector.Dot(dx, dy, pcx, pcy)
		Local c:= Vector.Len2(pcx, pcy) - _radius * _radius
		Local discr:= b * b - 4.0 * a * c
		If discr < 0 Then Return[]
		discr = Sqrt(discr)
		Local t1:= discr - b
		Local t2:= -discr - b
		If t1 >= 0 Then
			If t2 >= 0 Then Return[t1 / (2.0 * a), t2 / (2.0 * a)]
			Return[t1 / (2.0 * a)]
		EndIf
		If t2 >= 0 Then Return[t2 / (2.0 * a)]
		Return[]
	End

	Method IntersectsRay:Float[] (x:Float, y:Float, d:Float[])
		Local tmin:= math_huge
		For Local t:= EachIn IntersectionsWithRay(x, y, d)
			tmin = Min(t, tmin)
		Next
		If tmin <> math_huge Then Return[tmin]
		Return Null
	End
	
	Method Center:Float[] ()
		Return[_center[0], _center[1]] ' return copy
	End
	
	Method Outcircle:Float[] ()
		Return[_center[0], _center[1], _radius]
	End

	Method BBox:Float[] ()
		Return[_center[0] - _radius, _center[1] - _radius, _center[0] + _radius, _center[1] + _radius]
	End

Private

	Method _Move:Void(x:Float, y:Float)
		Vector.Add(_center, x, y)
	End

	Method _Rotate:Void(angle:Float)
		_rotation += angle
	End
	
	Method _Rotate:Void(angle:Float, cx:Float, cy:Float)
		_rotation += angle
		_center = Vector.Rotate(angle, _center[0] - cx, _center[1] - cy)
		Vector.Add(_center, cx, cy)
	End

	Method _Scale:Void(s:Float)
		If s < 0.0 Then
			Print("Invalid argument. Scale must be greater than 0")
			Return
		EndIf
		_radius *= s
	End
	
Public

	Method Draw:Void(canvas:Canvas, mode:String = "line")
		If mode = "fill" Then
			canvas.DrawCircle(_center[0], _center[1], _radius)
		Else
			' no method do draw a hollow circle in mojo2?
		EndIf
	end
End

Class PointShape Extends Shape
	Field _posX:Float
	Field _posY:Float
	
	Method New(x:Float, y:Float)
		Super.New("point")
		_posX = x
		_posY = y
	End

	Method CollidesWith:Float[] (other:Shape)
		If Self = other Then Return False
		If other._type = "point" Then
			If _posX = other._posX And _posY = other._posY Then Return[0.0, 0.0]
			Return[]
		EndIf
		If other.Contains(_posX, Self._posY) Then Return[0.0, 0.0]
		Return[]
	End

	Method Contains:Bool(x:Float, y:Float)
		Return x = _pos.x and y = _pos.y
	End
	
	' point shape intersects ray if it lies on the ray
	Method IntersectsRay:Float[] (x:Float, y:Float, d:Float[])
		Local px:= _posX - x
		Local py:= _posY - y
		Local t:= Vector.Dot(px, py, d[0], d[1]) / Vector.Len2(d)
		If t >= 0 Then Return[t]
		Return Null
	End

	Method IntersectionsWithRay:Float[] (x:Float, y:Float, d:Float[])
		Local intersect:= IntersectsRay(x, y, d)
		If intersect <> Null Then Return intersect
		Return[]
	End
	
	Method Center:Float[]()
		Return[_posX, _posY]
	End
	
	Method Outcircle:Float[] ()
	 	Return[_posX, _posY, 0.0]
	End

	Method BBox:Float[] ()
		Return[_posX, _posY, _posX, _posY]
	End
	
Private

	Method _Move:Void(x:Float, y:Float)
		_posX += x
		_posY += y
	End

	Method _Rotate:Void(angle:Float)
		_rotation += angle
	end

	Method _Rotate:Void(angle:Float, cx:Float, cy:Float)
		_rotation += angle
		Local pos:= Vector.Rotate(angle, _posX - cx, posY - cy)
		Vector.Add(pos, cx, cy)
		_posX = pos[0]
		_posY = pos[1]
	End
	
	Method _Scale:Void(s:Float)
		' nothing
	End
	
Public

	Method Draw:Void(canvas:Canvas, mode:String = "line")
		canvas.DrawPoint(_posX, _posY)
	end
End

Class ShapeMap<T> Extends Map<Shape, T>
	Method Compare:Int(a:Shape, b:Shape)
		Return a._id - b._id
	End
End

Class ShapeSet Extends Set<Shape>
	Method New()
		Super.New(New ShapeMap<Object>())
	End
End