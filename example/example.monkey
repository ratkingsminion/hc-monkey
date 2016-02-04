Strict

Import mojo2
Import hc

Class MyApp Extends App Implements ICollisionResponse
	Field lastTime:= -1
	Field thisTime:= -1
	Field deltaTime:= -1.0
	Field canvas:Canvas
	Field circle:Shape
	Field poly:Shape
	Field mouse:Shape
	Field hc:HC
	Field mouseColliding:Bool
	' array to hold collision messages
	Field text:= New StringStack()
	Field textTimer:Float

	' implementing the CollisionResponse interface
	
	Method OnCollision:Void(shape_a:Shape, shape_b:Shape, mtv_x:Float, mtv_y:Float)
		' mtv_x = Int(mtv_x * 1000) * 0.001; mtv_y = Int(mtv_y * 1000) * 0.001
		' AddText("Collision between " + shape_a._type + " and " + shape_b._type + " (" + mtv_x + ", " + mtv_y + ")")
	End
	
	Method OnCollisionStart:Void(shape_a:Shape, shape_b:Shape, mtv_x:Float, mtv_y:Float)
		mtv_x = Int(mtv_x * 1000) * 0.001; mtv_y = Int(mtv_y * 1000) * 0.001
		AddText("Collision Start between " + shape_a._type + " and " + shape_b._type + " (" + mtv_x + ", " + mtv_y + ")")
	End
	
	' this is called when two shapes stop mouseColliding
	Method OnCollisionStop:Void(shape_a:Shape, shape_b:Shape)
		AddText("Collision Stop between " + shape_a._type + " and " + shape_b._type)
	End
	
	'
    
	Method OnCreate:Int()
		canvas = New Canvas()
		
		' initialize library
		hc = New HC(50, Self)
		
		circle = hc.Circle(100.0, 300.0, 30.0)
		poly = hc.Polygon([120.0, 120.0, 320.0, 150.0, 175.0, 240.0, 370.0, 400.0, 130.0, 400.0, 180.0, 360.0, 100.0, 300.0])
		poly.Move(130, -20)
		mouse = hc.Polygon([10.0, 10, 80, 5, 50, 40, 90, 85, 20, 80])
		mouse.MoveTo(MouseX(), MouseY())
		
		Return 0
	End
	
	Method OnUpdate:Int()
		lastTime = thisTime
		thisTime = Millisecs()
		If lastTime < 0 Then lastTime = thisTime
		deltaTime = (thisTime - lastTime) * 0.001
		
		' move and rotate shapes
		mouse.MoveTo(MouseX(), MouseY())
		poly.Rotate(deltaTime * 10.0)
		mouse.Rotate(deltaTime * -40.0)
		circle.MoveTo(circle.Center()[0], 300.0 + Sin(thisTime * 0.1) * 50.0)

		' check for collisions
		Local colls:= hc.Collisions(mouse)
		mouseColliding = False
		If colls.Count() > 0 Then mouseColliding = True
		
		' handle the texts
		While text.Length() > 10 text.Remove(0); Wend
		textTimer -= deltaTime
		If textTimer < 0.0 Then
			If text.Length() > 0 Then text.Remove(0)
			textTimer = 2.0
		EndIf
		
		Return 0
	End
    
	Method OnRender:Int()
		canvas.Clear()
	
		'canvas.SetColor(0.0, 0.0, 1.0)
		'hc.hash.Draw(canvas, "line", False, True)
		
		canvas.SetColor(0.5, 0.5, 0.5)
		circle.Draw(canvas, "fill")
		
		canvas.SetColor(0.0, 1.0, 1.0); poly.Draw(canvas, "fill")
		'canvas.SetColor(1.0, 1.0, 1.0); poly.Draw(canvas, "line")
		
		If mouseColliding Then
			canvas.SetColor(1.0, 0.0, 0.0)
		Else
			canvas.SetColor(1.0, 1.0, 0.0)
		EndIf
		mouse.Draw(canvas, "fill")
		' canvas.SetColor(1.0, 1.0, 1.0); mouse.Draw(canvas, "line")
		
		' print messages
		canvas.SetColor(1.0, 1.0, 1.0)
		canvas.DrawText("ms: " + Int(deltaTime * 1000), 10.0, 10.0)
		For Local i:= 0 Until text.Length
			canvas.DrawText(text.Get(text.Length - (i + 1)), 10.0, 35.0 + i * 15.0)
		Next
		
		canvas.Flush()

		Return 0
	End
	
	Method AddText:Void(str:String)
		text.Push(str)
		textTimer = 2.0
	End
End

Function Main:Int()
	New MyApp()
	Return 0
End