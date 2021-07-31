using System;
using System.Diagnostics;

using OpenGL;
using glfw_beef;

using UltralightBeefSamples.OpenGLSurface;

using Ultralight.AppCore;
using Ultralight.Ultralight;

namespace UltralightBeefSamples.OpenGLSample
{
	static
	{
		public static GlfwWindow* window;
		public static ULView view;

		public static void RenderOpenGLSample()
		{
			Glfw.Init();
			Glfw.WindowHint(.ContextVersionMajor, 3);
			Glfw.WindowHint(.ContextVersionMinor, 3);
			Glfw.WindowHint(.OpenGlProfile, Glfw.OpenGlProfile.CoreProfile);

			const let INITIAL_WIDTH = 800;
			const let INITIAL_HEIGHT = 600;

			window = Glfw.CreateWindow(INITIAL_WIDTH, INITIAL_HEIGHT, "Ultralight Beef Sample", null, null);

			if (window == null)
			{
				Debug.WriteLine("Failed to create GLFW window");
				Glfw.Terminate();
			}

			Glfw.MakeContextCurrent(window);
			Glfw.SetKeyCallback(window, new => WindowGLFW_key_callback);
			Glfw.SetCharCallback(window, new => WindowGLFW_char_callback);
			Glfw.SetFramebufferSizeCallback(window, new => WindowGLFW_framebuffer_size_callback);
			Glfw.SetCursorPosCallback(window, new => WindowGLFW_cursor_pos_callback);
			Glfw.SetMouseButtonCallback(window, new => WindowGLFW_mouse_button_callback);
			Glfw.SetScrollCallback(window, new => WindowGLFW_scroll_callback);
			GL.Init( => Glfw.GetProcAddress);

			// INIT ULTRALIGHT
			ulEnablePlatformFontLoader();

			ULClipboard clipboard;
			clipboard.clear = => Clipboard_Clear_Callback;
			clipboard.read_plain_text = => Clipboard_ReadPlainText_Callback;
			clipboard.write_plain_text = => Clipboard_WritePlainText_Callback;
			ulPlatformSetClipboard(clipboard);

			ULSurfaceDefinition surfaceDefinition;

			surfaceDefinition.create = => OpenGLSurface.Create;
			surfaceDefinition.destroy = => OpenGLSurface.Destroy;
			surfaceDefinition.get_width = => OpenGLSurface.GetWidth;
			surfaceDefinition.get_height = => OpenGLSurface.GetHeight;
			surfaceDefinition.get_row_bytes = => OpenGLSurface.GetRowBytes;
			surfaceDefinition.get_size = => OpenGLSurface.GetSize;
			surfaceDefinition.lock_pixels = => OpenGLSurface.LockPixels;
			surfaceDefinition.unlock_pixels = => OpenGLSurface.UnlockPixels;
			surfaceDefinition.resize = => OpenGLSurface.Resize;

			ulPlatformSetSurfaceDefinition(surfaceDefinition);

			ULConfig config = ulCreateConfig();
			ulConfigSetUseGPURenderer(config, false);
			ULString resourcePathString = ulCreateString("./libs/Ultralight-beef/dist/sdk/bin/resources/");
			ulConfigSetResourcePath(config, resourcePathString);

			let renderer = ulCreateRenderer(config);

			let session = ulDefaultSession(renderer);

			const let TRANSPARENT = false;
			const let FORCE_CPU_RENDERER = true;

			view = ulCreateView(renderer, INITIAL_WIDTH,
				INITIAL_HEIGHT, TRANSPARENT,
				session, FORCE_CPU_RENDERER);

			const String htmlString =
				"""
				<h1>Hello World!</h1>
				<p>Here's some elements to interact with. Also try resizing the window, selecting text and copy pasting to/from the application.</p>
				<button>Button</button>
				<input type="text">
				<div style="background: lightgreen; overflow-y: auto; width: 200px; height: 100px;">
					<ul>
						<li>Scrollable</li>
						<li>Scrollable</li>
						<li>Scrollable</li>
						<li>Scrollable</li>
						<li>Scrollable</li>
						<li>Scrollable</li>
						<li>Scrollable</li>
						<li>Scrollable</li>
						<li>Scrollable</li>
						<li>Scrollable</li>
						<li>Scrollable</li>
						<li>Scrollable</li>
					</ul>
				</div>
				<textarea style="margin-top: 10px; width: 200px; height: 100px;"></textarea>
				""";
			ULString helloWorld = ulCreateStringUTF8(htmlString, (uint)htmlString.Length);
			ulViewLoadHTML(view, helloWorld);
			ulViewFocus(view);
			// END OF INIT ULTRALIGHT

			let shader = scope Shader("assets/4.1.texture.vert", "assets/4.1.texture.frag");

			float[?] vertices = .(// positions          // texture coords
				1.0f, 1.0f, 0.0f, 1.0f, 0.0f,// bottom right
				1.0f, -1.0f, 0.0f, 1.0f, 1.0f,// top right
				-1.0f, -1.0f, 0.0f, 0.0f, 1.0f,// top left
				-1.0f, 1.0f, 0.0f, 0.0f, 0.0f// bottom left
				);

			uint32[?] indices = .(
				0, 1, 3,// first triangle
				1, 2, 3// second triangle
				);

			uint32 VBO = 0, VAO = 0, EBO = 0;

			GL.glGenVertexArrays(1, &VAO);
			GL.glGenBuffers(1, &VBO);
			GL.glGenBuffers(1, &EBO);

			GL.glBindVertexArray(VAO);

			GL.glBindBuffer(GL.GL_ARRAY_BUFFER, VBO);
			GL.glBufferData(GL.GL_ARRAY_BUFFER, vertices.Count * sizeof(float), &vertices, GL.GL_STATIC_DRAW);

			GL.glBindBuffer(GL.GL_ELEMENT_ARRAY_BUFFER, EBO);
			GL.glBufferData(GL.GL_ELEMENT_ARRAY_BUFFER, vertices.Count * sizeof(uint32), &indices, GL.GL_STATIC_DRAW);

			// position attribute
			GL.glVertexAttribPointer(0, 3, GL.GL_FLOAT, GL.GL_FALSE, 5 * sizeof(float), (void*)0);
			GL.glEnableVertexAttribArray(0);

			// texture coord attribute
			GL.glVertexAttribPointer(1, 2, GL.GL_FLOAT, GL.GL_FALSE, 5 * sizeof(float), (void*)(int)(3 * sizeof(float)));
			GL.glEnableVertexAttribArray(1);

			while (!Glfw.WindowShouldClose(window))
			{
				// input
				// -----
				ProcessInput(window);

				// render
				// ------
				GL.glClearColor(0.2f, 0.3f, 0.3f, 1.0f);
				GL.glClear(GL.GL_COLOR_BUFFER_BIT);

				ulUpdate(renderer);
				ulRender(renderer);

				// Get texture from Ultralight
				ULSurface surface = ulViewGetSurface(view);
				void* userData = ulSurfaceGetUserData(surface);
				GLSurface glSurface = (GLSurface)System.Internal.UnsafeCastToObject(userData);
				uint32 textureId = glSurface.GetTextureAndSyncIfNeeded(surface);

				// bind Texture
				GL.glBindTexture(GL.GL_TEXTURE_2D, textureId);

				// render container
				shader.Bind();
				GL.glBindVertexArray(VAO);
				GL.glDrawElements(GL.GL_TRIANGLES, 6, GL.GL_UNSIGNED_INT, (void*)0);

				// glfw: swap buffers and poll IO events (keys pressed/released, mouse moved etc.)
				// -------------------------------------------------------------------------------
				Glfw.SwapBuffers(window);
				Glfw.PollEvents();
			}

			// optional: de-allocate all resources once they've outlived their purpose:
			// ------------------------------------------------------------------------
			GL.glDeleteVertexArrays(1, &VAO);
			GL.glDeleteBuffers(1, &VBO);
			GL.glDeleteBuffers(1, &EBO);

			// glfw: terminate, clearing all previously allocated GLFW resources.
			// ------------------------------------------------------------------
			Glfw.Terminate();

			ulDestroyConfig(config);
			ulDestroyRenderer(renderer);
			ulDestroyView(view);
			ulDestroyString(helloWorld);
		}

		private static void ProcessInput(GlfwWindow* window)
		{
			if (Glfw.GetKey(window, .Escape) == .Press)
				Glfw.SetWindowShouldClose(window, true);
		}

		public static void WindowGLFW_framebuffer_size_callback(GlfwWindow* window, int width, int height)
		{
			// make sure the viewport matches the new window dimensions; note that width and 
			// height will be significantly larger than specified on retina displays.
			GL.glViewport(0, 0, width, height);
			ulViewResize(view, (uint32)width, (uint32)height);
		}

		public static void WindowGLFW_key_callback(GlfwWindow* window, GlfwInput.Key key, int scancode, GlfwInput.Action action, int mods)
		{
			let type = action == GlfwInput.Action.Press || action == GlfwInput.Action.Repeat ?
				ULKeyEventType.kKeyEventType_RawKeyDown : ULKeyEventType.kKeyEventType_KeyUp;

			let virtualKeyCode = GLFWKeyCodeToUltralightKeyCode(key);
			let nativeKeyCode = scancode;
			let modifiers = GLFWModsToUltralightMods(mods);

			let emptyString = ulCreateString("");
			let isKeypad = false;
			let isAutoRepeat = false;
			let isSystemKey = false;

			let event = ulCreateKeyEvent(type, modifiers, (int)virtualKeyCode, nativeKeyCode, emptyString, emptyString, isKeypad, isAutoRepeat, isSystemKey);

			ulViewFireKeyEvent(view, event);
			ulDestroyString(emptyString);
			ulDestroyKeyEvent(event);

			if (type == ULKeyEventType.kKeyEventType_RawKeyDown &&
				(key == .Enter || key == .Tab))
			{

				// We have to synthesize the Char Event for these keys.
				let type1 = ULKeyEventType.kKeyEventType_Char;
				let text = key == .Enter ? ulCreateString("\r") : ulCreateString("\t");

				let event1 = ulCreateKeyEvent(type1, modifiers, 0, 0, text, text, isKeypad, isAutoRepeat, isSystemKey);
				ulViewFireKeyEvent(view, event1);
				ulDestroyString(text);
				ulDestroyKeyEvent(event1);
			}
		}

		public static void WindowGLFW_char_callback(GlfwWindow* window, uint codepoint)
		{
			//uint char = codepoint;
			//char8 char8 = (char8)codepoint;
			uint16 char16 = (uint16)codepoint;

			//let text = ulCreateStringUTF8(&char8, 1);

			// TODO: Replace with a way to utilize whole 32 bits
			let text = ulCreateStringUTF16((uint16*)&char16, 1);

			let mods = 0;
			let virtualKeyCode = 0;
			let nativeKeyCode = 0;
			let isKeypad = false;
			let isAutoRepeat = false;
			let isSystemKey = false;

			let evt = ulCreateKeyEvent(ULKeyEventType.kKeyEventType_Char, mods, virtualKeyCode, nativeKeyCode, text, text, isKeypad, isAutoRepeat, isSystemKey);

			ulViewFireKeyEvent(view, evt);

			ulDestroyKeyEvent(evt);
			ulDestroyString(text);
		}

		public static void WindowGLFW_cursor_pos_callback(GlfwWindow* window, double xpos, double ypos)
		{
			ULMouseButton button = Glfw.GetMouseButton(window, GlfwInput.MouseButton.ButtonLeft) == GlfwInput.Action.Press ?
				ULMouseButton.kMouseButton_Left : Glfw.GetMouseButton(window, GlfwInput.MouseButton.ButtonRight) == GlfwInput.Action.Press ?
				ULMouseButton.kMouseButton_Right : Glfw.GetMouseButton(window, GlfwInput.MouseButton.ButtonMiddle) == GlfwInput.Action.Press ?
				ULMouseButton.kMouseButton_Middle :
				ULMouseButton.kMouseButton_None;

			let evt = ulCreateMouseEvent(ULMouseEventType.kMouseEventType_MouseMoved, (int)xpos, (int)ypos, button);
			ulViewFireMouseEvent(view, evt);
			ulDestroyMouseEvent(evt);
		}

		public static void WindowGLFW_mouse_button_callback(GlfwWindow* window, GlfwInput.MouseButton button,
			GlfwInput.Action action, int mods)
		{
			let type = action == .Press ? ULMouseEventType.kMouseEventType_MouseDown :
				ULMouseEventType.kMouseEventType_MouseUp;


			double xpos = 0, ypos = 0;
			Glfw.GetCursorPos(window, ref xpos, ref ypos);
			let x = PixelsToDevice((int)xpos);
			let y = PixelsToDevice((int)ypos);

			ULMouseButton btn = ULMouseButton.kMouseButton_None;

			switch (button) {
			case .ButtonLeft:
				btn = ULMouseButton.kMouseButton_Left;
				break;
			case .ButtonMiddle:
				btn = ULMouseButton.kMouseButton_Middle;
				break;
			case .ButtonRight:
				btn = ULMouseButton.kMouseButton_Right;
				break;
			default:
			}

			let evt = ulCreateMouseEvent(type, x, y, btn);
			ulViewFireMouseEvent(view, evt);
			ulDestroyMouseEvent(evt);
		}

		public static void WindowGLFW_scroll_callback(GlfwWindow* window, double xoffset, double yoffset)
		{
			let deltaX = PixelsToDevice((int)xoffset * 32);
			let deltaY = PixelsToDevice((int)yoffset * 32);

			let evt = ulCreateScrollEvent(ULScrollEventType.kScrollEventType_ScrollByPixel, deltaX, deltaY);
			ulViewFireScrollEvent(view, evt);
			ulDestroyScrollEvent(evt);
		}

		public static void Clipboard_Clear_Callback()
		{
			Glfw.SetClipboardString(window, "");
		}

		public static void Clipboard_ReadPlainText_Callback(ULString result)
		{
			String buffer = scope String();
			Glfw.GetClipboardString(window, buffer);
			let temp = ulCreateStringUTF8(buffer, (uint)(buffer.Length));
			ulStringAssignString(result, temp);
			ulDestroyString(temp);
		}

		public static void Clipboard_WritePlainText_Callback(ULString text)
		{
			// TODO: Make this work. Replace manual UTF16 decode with a supported way
			// to get UTF8 data from ULString, once available.
			let data = ulStringGetData(text);
			String str = scope String();
			System.Text.UTF16.Decode((char16*)data, str);
			Glfw.SetClipboardString(window, str);
		}

		private static double scale()
		{
			float xScale = 0.0f, yScale = 0.0f;
			Glfw.GetMonitorContentScale(Glfw.GetPrimaryMonitor(), ref xScale, ref yScale);
			return (double)xScale;
		}

		public static int DeviceToPixels(int val)
		{
#if BF_PLATFORM_MACOS
			return val;
#else
			return (int)Math.Round(val * scale());
#endif
		}

		public static int PixelsToDevice(int val)
		{
#if BF_PLATFORM_MACOS
			  return val;
#else
			return (int)Math.Round(val / scale());
#endif
		}
	}
}
