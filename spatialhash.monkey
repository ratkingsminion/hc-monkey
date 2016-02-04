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

'Import mojo2

Import shapes

Class Spatialhash

	Field cell_size:Int
	Field cells:IntMap<IntMap<ShapeSet>>
	
	''
		
	Method New(cell_size:Int = 100)
		Self.cell_size = cell_size
		cells = New IntMap<IntMap<ShapeSet>>()
	End

	Method CellCoord:Int(v:Float)
		Return Floor(v / cell_size)
	End

	Method Cell:ShapeSet(i:Int, k:Int)
		Local row:= Self.cells.Get(i)
		If row = Null Then
			row = New IntMap<ShapeSet>()
			cells.Set(i, row)
		EndIf
		Local cell:= row.Get(k)
		If cell = Null Then
			cell = New ShapeSet()
			row.Set(k, cell)
		EndIf
		Return cell
	End

	Method CellAt:Stack<Shape>(x:Int, y:Int)
		Return Cell(CellCoords(x, y))
	End

	' get all shapes
	Method Shapes:ShapeSet()
		Local set:= New ShapeSet()
		For Local row:= EachIn cells
			For Local cell:= EachIn row
				Local count:= cell.Length()
				For Local c:= 0 Until count
					set.Push(cell[c])
				Next
			Next
		Next
	End

	' get all shapes that are in the same cells as the bbox x1,y1 '--. x2,y2
	Method InSameCells:ShapeSet(x1:Float, y1:Float, x2:Float, y2:Float)
		Local set:= New ShapeSet
		Local ix2:= CellCoord(x2), iy2:= CellCoord(y2)
		For Local i:= CellCoord(x1) To ix2
			For Local k:= CellCoord(y1) To iy2
				Local cell:= Cell(i, k)
				For Local c:= EachIn cell
					set.Insert(c)
				Next
			Next
		Next
		Return set
	End

	Method InSameCells:ShapeSet(box:Float[])
		Local set:= New ShapeSet
		Local ix2:= CellCoord(box[2]), iy2:= CellCoord(box[3])
		For Local i:= CellCoord(box[0]) To ix2
			For Local k:= CellCoord(box[1]) To iy2
				Local cell:= Cell(i, k)
				For Local c:= EachIn cell
					set.Insert(c)
				Next
			Next
		Next
		Return set
	end

	Method Register:Void(obj:Shape, x1:Float, y1:Float, x2:Float, y2:Float)
		Local ix2:= CellCoord(x2), iy2:= CellCoord(y2)
		For Local i:= CellCoord(x1) To ix2
			For Local k:= CellCoord(y1) To iy2
				Cell(i, k).Insert(obj)
			Next
		Next
		obj.hash = Self
	End

	Method Register:Void(obj:Shape, box:Float[])
		Local ix2:= CellCoord(box[2]), iy2:= CellCoord(box[3])
		For Local i:= CellCoord(box[0]) To ix2
			For Local k:= CellCoord(box[1]) To iy2
				Cell(i, k).Insert(obj)
			Next
		Next
		obj.hash = Self
	End

	Method Remove:Void(obj:Shape)
		' no bbox given => must check all cells
		For Local row:= EachIn cells
			For Local cell:= EachIn row
				cell.Remove(obj)
			Next
		Next
		If obj.hash = Self Then obj.hash = Null
	End

	Method Remove:Void(obj:Shape, x1:Float, y1:Float, x2:Float, y2:Float)
		' else -> remove only from bbox
		Local ix2:= CellCoord(x2), iy2:= CellCoord(y2)
		For Local i:= CellCoord(x1) To ix2
			For Local k:= CellCoord(y1) To iy2
				Cell(i, k).Remove(obj)
			Next
		Next
		If obj.hash = Self Then obj.hash = Null
	End

	Method Remove:Void(obj:Shape, box:Float[])
		' else -> remove only from bbox
		Local ix2:= CellCoord(box[2]), iy2:= CellCoord(box[3])
		For Local i:= CellCoord(box[0]) To ix2
			For Local k:= CellCoord(box[1]) To iy2
				Cell(i, k).Remove(obj)
			Next
		Next
		If obj.hash = Self Then obj.hash = Null
	end

	' update an objects position
	Method Update:Void(obj:Shape, old_x1:Float, old_y1:Float, old_x2:Float, old_y2:Float, new_x1:Float, new_y1:Float, new_x2:Float, new_y2:Float)
		old_x1 = CellCoord(old_x1); old_y1 = CellCoord(old_y1)
		old_x2 = CellCoord(old_x2); old_y2 = CellCoord(old_y2)
		new_x1 = CellCoord(new_x1); new_y1 = CellCoord(new_y1)
		new_x2 = CellCoord(new_x2); new_y2 = CellCoord(new_y2)
		If old_x1 = new_x1 And old_y1 = new_y1 And old_x2 = new_x2 And old_y2 = new_y2 Then
			Return
		End
	
		For Local i:= old_x1 To old_x2
			For Local k:= old_y1 To old_y2
				Cell(i, k).Remove(obj)
			Next
		Next
		For Local i:= new_x1 To new_x2
			For Local k:= new_y1 To new_y2
				Cell(i, k).Insert(obj)
			End
		end
	End

	' update an objects position
	Method Update:Void(obj:Shape, oldBox:Float[], newBox:Float[])
		Local old_x1:= CellCoord(oldBox[0]), old_y1:= CellCoord(oldBox[1])
		Local old_x2:= CellCoord(oldBox[2]), old_y2:= CellCoord(oldBox[3])
		Local new_x1:= CellCoord(newBox[0]), new_y1:= CellCoord(newBox[1])
		Local new_x2:= CellCoord(newBox[2]), new_y2:= CellCoord(newBox[3])
		If old_x1 = new_x1 And old_y1 = new_y1 And old_x2 = new_x2 And old_y2 = new_y2 Then
			Return
		End
	
		For Local i:= old_x1 To old_x2
			For Local k:= old_y1 To old_y2
				Cell(i, k).Remove(obj)
			Next
		Next
		For Local i:= new_x1 To new_x2
			For Local k:= new_y1 To new_y2
				Cell(i, k).Insert(obj)
			End
		end
	end
	
	Method Draw:Void(canvas:DrawList, how:String)
		Draw(canvas, how, True, False)
	End
	
	Method Draw:Void(canvas:DrawList, how:String, show_empty:Bool, print_key:Bool)
		''' TODO: use "how" (can be "line" or "fill")
		For Local it1:= EachIn cells
			Local k1:= it1.Key
			Local v:= it1.Value
			For Local it2:= EachIn v
				Local k2:= it2.Key
				Local cell:= it2.Value
				Local is_empty:= cell.Count() = 0
				If show_empty Or Not is_empty Then
					Local x:= k1 * cell_size
					Local y:= k2 * cell_size
					If how = "fill" Then
						canvas.DrawRect(x, y, cell_size, cell_size)
					Else
						canvas.DrawLine(x, y, x + cell_size, y)
						canvas.DrawLine(x + cell_size, y, x + cell_size, y + cell_size)
						canvas.DrawLine(x + cell_size, y + cell_size, x, y + cell_size)
						canvas.DrawLine(x, y + cell_size, x, y)
					EndIf
					If print_key Then
						If how = "fill" Then
							Local c:Float[]
							canvas.GetColor(c)
							canvas.SetColor(c[2], c[0], c[1])
							canvas.DrawText(k1 + ":" + k2, x + 3, y + 3)
							canvas.SetColor(c[0], c[1], c[2])
						Else
							canvas.DrawText(k1 + ":" + k2, x + 3, y + 3)
						EndIf
					EndIf
				EndIf
			Next
		Next
	End
	
End
