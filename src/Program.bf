using System;
using System.Diagnostics;

//using OpenGL;
//using glfw_beef;
//using BeefUtils;

namespace UltralightBeefSamples
{
	class Program
	{
		public static void Main()
		{
			Debug.WriteLine("Hello world");

			// Uncomment to try png render sample (result will be saved to disk)
			//PngSample.RenderPngSample();
			OpenGLSample.RenderOpenGLSample();
		}
	}
}
