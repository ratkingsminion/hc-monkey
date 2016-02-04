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

Import polygon
Import shapes
Import spatialhash
Import vectorlight
Import gjk

Interface ICollisionResponse
	' this is called when two shapes collide
	Method OnCollision:Void(shape_a:Shape, shape_b:Shape, mtv_x:Float, mtv_y:Float)
	' this is called when two shapes start colliding
	Method OnCollisionStart:Void(shape_a:Shape, shape_b:Shape, mtv_x:Float, mtv_y:Float)
	' this is called when two shapes stop colliding
	Method OnCollisionStop:Void(shape_a:Shape, shape_b:Shape)
End

Class HC
	Field hash:Spatialhash
	Field responder:ICollisionResponse
	
Private
	
	Field previousCollisions:= New ShapeMap<ShapeSet>()
	
Public
	
	''
	
	Method New(cell_size:Int = 100, responder:ICollisionResponse = Null)
		hash = New Spatialhash(cell_size)
		Self.responder = responder
	End
	
	' spatial hash management
	
	Method ResetHash:HC(cell_size:Int = 100)
		Local h:= hash
		hash = New Spatialhash(cell_size)
		For Local shape:= EachIn h.Shapes()
			hash.Register(shape, shape.BBox())
		Next
		Return Self
	End

	Method Register:Shape(shape:Shape)
		hash.Register(shape, shape.BBox())
		previousCollisions.Add(shape, New ShapeSet())
#Rem		
		' keep track of where/how big the shape is
		For _, f in ipairs( {'move', 'rotate', 'scale'}) do
			local old_function = shape[f]
			shape[f] = function(this, ...)
				Local x1, y1, x2, y2 = this:bbox()
				old_function(this, ...)
				Self.hash:update(this, x1, y1, x2, y2, this:bbox())
				Return this
			End
		End
#End
		Return shape
	End
	

	Method Remove:HC(shape:Shape)
		hash.Remove(shape, shape.Bbox())
#Rem
		for _, f in ipairs({'move', 'rotate', 'scale'}) do
				shape[f] = Function()
				error(f.."() called on a removed shape")
			end
		End
#End
		Return Self
	end
	
	' shape constructors
	Method Polygon:Shape(coords:Float[])
		' TODO convex / concav
		Local poly:= New Polygon(coords)
		Local shape:Shape
		If poly.IsConvex() Then
			shape = New ConvexPolygonShape(poly)
		Else
			Local concaveShape:= New ConcavePolygonShape(poly)
			shape = concaveShape
		EndIf
		Return Register(shape)
	End
	
	Method Rectangle:Shape(x:Float, y:Float, w:Float, h:Float)
		Return Polygon([x, y, x + w, y, x + w, y + h, x, y + h])
	end
	
	Method Circle:Shape(x:Float, y:Float, r:Float)
		Return Register(New CircleShape(x, y, r))
	End
	
	Method Point:Shape(x:Float, y:Float)
		Return Register(New PointShape(x, y))
	end
	
	' collision detection
	Method Neighbors:ShapeSet(shape:Shape)
		Local neighbors:= hash.InSameCells(shape.BBox())
		neighbors.Remove(shape)
		Return neighbors
	end
	
	Method Collisions:ShapeMap<Float[] > (shape:Shape)
		If responder Then Return CollisionsWithResponse(shape)
		Return CollisionsWithoutResponse(shape)
	End
	
	Private
	
	Method CollisionsWithResponse:ShapeMap<Float[] > (shape:Shape)
		Local candidates:= Neighbors(shape)
		Local curColls:= New ShapeMap<Float[] > ()
		Local prevColls:= previousCollisions.Get(shape)
		' check collisions
		For Local other:= EachIn candidates
			Local coll:= shape.CollidesWith(other)
			If coll.Length() > 0 Then
				curColls.Set(other,[coll[0], coll[1]])
				responder.OnCollision(shape, other, coll[0], coll[1])
				If Not prevColls.Contains(other) Then
					responder.OnCollisionStart(shape, other, coll[0], coll[1])
				EndIf
			EndIf
		Next
		' check the previous collisions
		For Local other:= EachIn prevColls
			If Not curColls.Contains(other) Then
				responder.OnCollisionStop(shape, other)
				prevColls.Remove(other)
			EndIf
		Next
		For Local other:= EachIn curColls.Keys()
			prevColls.Insert(other)
		Next
		Return curColls
	End
	
	Method CollisionsWithoutResponse:ShapeMap<Float[] > (shape:Shape)
		Local candidates:= Neighbors(shape)
		Local collData:= New ShapeMap<Float[] > ()
		For Local other:= EachIn candidates
			Local coll:= shape.CollidesWith(other)
			If coll.Length() > 0 Then
				collData.Set(other,[coll[0], coll[1]])
			EndIf
		Next
		Return collData
	End
End