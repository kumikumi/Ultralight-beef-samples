using System;
using System.Diagnostics;
using System.IO;
using System.Collections;

using static OpenGL.GL;

namespace OpenGL
{
	class Shader
	{
		public uint handle ~ glDeleteProgram(_);
		public uint vertexShader;
		public uint fragmentShader;

		private Dictionary<StringView, int> locations = new .(1) ~ delete _;

		public this(StringView vertexPath, StringView fragmentPath)
		{
			// Vertex shader
			String vertexSource = scope .();
			switch (File.ReadAllText(vertexPath, vertexSource, true)) {
			case .Ok:
			case .Err(let err): Console.WriteLine(err); return;
			}

			vertexShader = glCreateShader(GL_VERTEX_SHADER);
			char8* vertexSourceData = vertexSource.Ptr;
			glShaderSource(vertexShader, 1, &vertexSourceData, null);
			glCompileShader(vertexShader);

			int32 vertexSuccess = 0;
			glGetShaderiv(vertexShader, GL_COMPILE_STATUS, &vertexSuccess);
			if (vertexSuccess == GL_FALSE)
			{
				char8* msg = new char8[512]*;
				glGetShaderInfoLog(vertexShader, 512, null, msg);
				Debug.WriteLine("Failed to compile vertex shader: {}", scope String(msg));
				delete msg;
			}

			// Fragment shader
			String fragmentSource = scope .();
			switch (File.ReadAllText(fragmentPath, fragmentSource, true)) {
			case .Ok:
			case .Err(let err): Console.WriteLine(err); return;
			}

			fragmentShader = glCreateShader(GL_FRAGMENT_SHADER);
			char8* fragmentSourceData = fragmentSource.Ptr;
			glShaderSource(fragmentShader, 1, &fragmentSourceData, null);
			glCompileShader(fragmentShader);

			int32 fragmentSuccess = 0;
			glGetShaderiv(fragmentShader, GL_COMPILE_STATUS, &fragmentSuccess);
			if (fragmentSuccess == GL_FALSE)
			{
				char8* msg = new char8[512]*;
				GL.glGetShaderInfoLog(fragmentShader, 512, null, msg);
				Debug.WriteLine("Failed to compile fragment shader: {}", scope String(msg));
				delete msg;
			}

			// Shader program
			handle = glCreateProgram();
			glAttachShader(handle, vertexShader);
			glAttachShader(handle, fragmentShader);
			glLinkProgram(handle);

			glDeleteShader(vertexShader);
			glDeleteShader(fragmentShader);
		}

		public void Bind()
		{
			GL.glUseProgram(handle);
		}
	}
}
