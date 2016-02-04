Strict

#Rem
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
#End

Class Vector
	
	Function Str:String(x:Float, y:Float)
		Return "(" + x + "," + y + ")"
	End

	Function Mul:Float[] (s:Float, x:Float, y:Float)
		Return[x * s, y * s]
	End
	
	Function Mul:Void(s:Float, p:Float[])
		p[0] *= s
		p[1] *= s
	End

	Function Div:Float[] (s:Float, x:Float, y:Float)
		Return[x / s, y / s]
	End

	Function Div:Void(s:Float, p:Float[])
		p[0] /= s
		p[1] /= s
	End

	Function Add:Float[] (x1:Float, y1:Float, x2:Float, y2:Float)
		Return[x1 + x2, y1 + y2]
	End

	Function Add:Void(p:Float[], x2:Float, y2:Float)
		p[0] += x2
		p[1] += y2
	End

	Function Add:Void(p:Float[], q:Float[])
		p[0] += q[0]
		p[1] += q[1]
	End

	Function Sub:Float[] (x1:Float, y1:Float, x2:Float, y2:Float)
		Return[x1 - x2, y1 - y2]
	End

	Function Sub:Void(p:Float[], q:Float[])
		p[0] -= q[0]
		p[1] -= q[1]
	End

	Function Permul:Float[] (x1:Float, y1:Float, x2:Float, y2:Float)
		Return[x1 * x2, y1 * y2]
	End

	Function Dot:Float(x1:Float, y1:Float, x2:Float, y2:Float)
		Return x1 * x2 + y1 * y2
	End

	Function Dot:Float(p:Float[], qx:Float, qy:Float)
		Return p[0] * qx + p[1] * qy
	End

	Function Dot:Float(p:Float[], q:Float[])
		Return p[0] * q[0] + p[1] * q[1]
	End

	Function Det:Float(x1:Float, y1:Float, x2:Float, y2:Float)
		Return x1 * y2 - y1 * x2
	End

	Function Det:Float(p:Float[], q:Float[])
		Return p[0] * q[1] - p[1] * q[0]
	End

	Function Eq:Bool(x1:Float, y1:Float, x2:Float, y2:Float, eps:Float = 0.0001)
		' Return x1 = x2 And y1 = y2
		Return x1 < x2 + eps And x1 > x2 - eps And y1 < y2 + eps And y1 > y2 - eps
	End

	Function Eq:Bool(p:Float[], q:Float[], eps:Float = 0.0001)
		'Return p[0] = q[0] And p[1] = q[1]
		Return p[0] < q[0] + eps And p[0] > q[0] - eps And p[1] < q[1] + eps And p[1] > q[1] - eps
	End

	Function Lt:Bool(x1:Float, y1:Float, x2:Float, y2:Float)
		Return x1 < x2 Or (x1 = x2 And y1 < y2)
	End
	
	Function Le:Bool(x1:Float, y1:Float, x2:Float, y2:Float)
		Return x1 <= x2 And y1 <= y2
	End
	
	Function Len2:Float(x:Float, y:Float)
		Return x * x + y * y
	End
	
	Function Len2:Float(p:Float[])
		Return p[0] * p[0] + p[1] * p[1]
	End
	
	Function Len:Float(x:Float, y:Float)
		Return Sqrt(x * x + y * y)
	End
	
	Function Len:Float(p:Float[])
		Return Sqrt(p[0] * p[0] + p[1] * p[1])
	End
	
	Function Dist:Float(x1:Float, y1:Float, x2:Float, y2:Float)
		Return Len(x1 - x2, y1 - y2)
	end
	
	Function Normalize:Float[] (x:Float, y:Float)
		Local l:= 1.0 / Len(x, y)
		Return[x * l, y * l]
	End
	
	Function Normalize:Void(p:Float[])
		Local l:= 1.0 / Len(p)
		p[0] *= l
		p[1] *= l
	end
	
	Function Rotate:Float[] (phi:Float, x:Float, y:Float)
		Local c:= Cos(phi)
		Local s:= Sin(phi)
		Return[c * x - s * y, s * x + c * y]
	end
	
	Function Perpendicular:Float[] (x:Float, y:Float)
		Return[-y, x]
	End
	
	Function Perpendicular:Float[] (p:Float[])
		Return[-p[1], p[0]]
	end
	
	Function Project:Float[] (x:Float, y:Float, u:Float, v:Float)
		Local s:= (x * u + y * v) / (u * u + v * v)
		Return[s * u, s * v]
	end
	
	Function Mirror:Float[] (x:Float, y:Float, u:Float, v:Float)
		Local s:= 2.0 * (x * u + y * v) / (u * u + v * v)
		Return[s * u - x, s * v - y]
	End
	
End