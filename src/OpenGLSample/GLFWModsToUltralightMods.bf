using glfw_beef;
using Ultralight.Ultralight;

namespace UltralightBeefSamples.OpenGLSample
{
	static
	{
		public static uint32 GLFWModsToUltralightMods(int mods)
		{
			uint32 result = 0;
			if (mods & (int)GlfwInput.Modifiers.Alt != 0)
				result |= (int)ULModifier.kMod_AltKey;
			if (mods & (int)GlfwInput.Modifiers.Control != 0)
				result |= (int)ULModifier.kMod_CtrlKey;
			if (mods & (int)GlfwInput.Modifiers.Super != 0)
				result |= (int)ULModifier.kMod_MetaKey;
			if (mods & (int)GlfwInput.Modifiers.Shift != 0)
				result |= (int)ULModifier.kMod_ShiftKey;
			return result;
		}
	}
}
