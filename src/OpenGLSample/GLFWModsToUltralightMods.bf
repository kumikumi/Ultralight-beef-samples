using GLFW;
using Ultralight;

namespace UltralightBeefSamples.OpenGLSample
{
	static
	{
		public static uint32 GLFWModsToUltralightMods(int mods)
		{
			uint32 result = 0;
			if (mods & (int)GlfwInput.Modifiers.Alt != 0)
				result |= (int)ULKeyboardModifier.kMod_AltKey;
			if (mods & (int)GlfwInput.Modifiers.Control != 0)
				result |= (int)ULKeyboardModifier.kMod_CtrlKey;
			if (mods & (int)GlfwInput.Modifiers.Super != 0)
				result |= (int)ULKeyboardModifier.kMod_MetaKey;
			if (mods & (int)GlfwInput.Modifiers.Shift != 0)
				result |= (int)ULKeyboardModifier.kMod_ShiftKey;
			return result;
		}
	}
}
