using System.Collections;
using System.Diagnostics;

using OpenGL;
using static OpenGL.GL;

using Ultralight.Ultralight;

namespace UltralightBeefSamples.OpenGLSurface
{
	static
	{
		// to shut up leak detection
		private static List<GLSurface> surfaceList = new List<GLSurface>() ~ delete _;

		public static void* Create(uint32 width, uint32 height)
		{
			GLSurface surface = new GLSurface(width, height);
			surfaceList.Add(surface);
			void* ptr = System.Internal.UnsafeCastToPtr(surface);
			return ptr;
		}

		public static void Destroy(void* user_data)
		{
			GLSurface surface = (GLSurface)System.Internal.UnsafeCastToObject(user_data);
			surfaceList.Remove(surface);

			delete surface;
		}

		public static uint32 GetWidth(void* user_data)
		{
			GLSurface surface = (GLSurface)System.Internal.UnsafeCastToObject(user_data);
			return surface.GetWidth();
		}

		public static uint32 GetHeight(void* user_data)
		{
			GLSurface surface = (GLSurface)System.Internal.UnsafeCastToObject(user_data);
			return surface.GetHeight();
		}

		public static uint32 GetRowBytes(void* user_data)
		{
			GLSurface surface = (GLSurface)System.Internal.UnsafeCastToObject(user_data);
			return surface.GetRowBytes();
		}

		public static uint GetSize(void* user_data)
		{
			GLSurface surface = (GLSurface)System.Internal.UnsafeCastToObject(user_data);
			return surface.GetSize();
		}

		public static void* LockPixels(void* user_data)
		{
			GLSurface surface = (GLSurface)System.Internal.UnsafeCastToObject(user_data);
			return surface.LockPixels();
		}

		public static void UnlockPixels(void* user_data)
		{
			GLSurface surface = (GLSurface)System.Internal.UnsafeCastToObject(user_data);
			surface.UnlockPixels();
		}

		public static void Resize(void* user_data, uint32 width, uint32 height)
		{
			GLSurface surface = (GLSurface)System.Internal.UnsafeCastToObject(user_data);
			surface.Resize(width, height);
		}
	}

	class GLSurface
	{
		public uint32 width_ = 640;
		public uint32 height_ = 480;
		public uint32 pbo_id_ = 0;
		public uint32 texture_id_ = 0;
		public uint32 row_bytes_ = 0;
		public uint32 size_ = 0;

		public this(uint32 width, uint32 height)
		{
			Debug.WriteLine("Create surface with dimensions: {}, {}", width, height);
			this.Resize(width, height);
		}

		public ~this()
		{
			if (pbo_id_ !== 0)
			{
				glDeleteBuffers(1, &pbo_id_);
				pbo_id_ = 0;
				glDeleteTextures(1, &texture_id_);
				texture_id_ = 0;
			}
		}

		public uint32 GetWidth()
		{
			return this.width_;
		}

		public uint32 GetHeight()
		{
			return this.height_;
		}

		public uint32 GetRowBytes()
		{
			return this.row_bytes_;
		}

		public uint GetSize()
		{
			return this.size_;
		}

		public void* LockPixels()
		{
			///
			/// Map our PBO to system memory so Ultralight can draw to it.
			///
			glBindBuffer(GL_PIXEL_UNPACK_BUFFER, this.pbo_id_);
			void* result = glMapBuffer(GL_PIXEL_UNPACK_BUFFER, GL_READ_WRITE);
			glBindBuffer(GL_PIXEL_UNPACK_BUFFER, 0);
			return result;
		}

		public void UnlockPixels()
		{
			///
			/// Unmap our PBO.
			///
			glBindBuffer(GL_PIXEL_UNPACK_BUFFER, this.pbo_id_);
			glUnmapBuffer(GL_PIXEL_UNPACK_BUFFER);
			glBindBuffer(GL_PIXEL_UNPACK_BUFFER, 0);
		}

		public void Resize(uint32 width, uint32 height)
		{
			Debug.WriteLine("Resize surface to {}, {}", width, height);
			if (this.pbo_id_ != 0 && this.width_ == width && this.height_ == height)
				return;

			///
			/// Destroy any existing PBO and texture.
			///
			if (this.pbo_id_ != 0)
			{
				glDeleteBuffers(1, &pbo_id_);
				pbo_id_ = 0;
				glDeleteTextures(1, &texture_id_);
				texture_id_ = 0;
			}

			this.width_ = width;
			this.height_ = height;
			this.row_bytes_ = width_ * 4;
			this.size_ = row_bytes_ * height_;

			///
			/// Create our PBO (pixel buffer object), with a size of 'size_'
			///
			glGenBuffers(1, &this.pbo_id_);
			glBindBuffer(GL_PIXEL_UNPACK_BUFFER, pbo_id_);
			glBufferData(GL_PIXEL_UNPACK_BUFFER, size_, (void*)0, GL_DYNAMIC_DRAW);
			glBindBuffer(GL_PIXEL_UNPACK_BUFFER, 0);

			///
			/// Create our Texture object.
			///
			glGenTextures(1, &this.texture_id_);
			glBindTexture(GL_TEXTURE_2D, texture_id_);
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);// IS GL_CLAMP_TO_EDGE CORRECT?
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);// IS GL_CLAMP_TO_EDGE CORRECT?
			glBindTexture(GL_TEXTURE_2D, 0);
		}

		public uint32 GetTextureAndSyncIfNeeded(ULSurface surface)
		{
		///
		/// This is NOT called by Ultralight.
		///
		/// This helper function is called when our application wants to draw this
		/// Surface to an OpenGL quad. (We return an OpenGL texture handle)
		///
		/// We take this opportunity to upload the PBO to the texture if the
		/// pixels have changed since the last call (indicated by dirty_bounds()
		/// being non-empty)
		///
			let dirtyBounds = ulSurfaceGetDirtyBounds(surface);
			let skipRender = ulIntRectIsEmpty(dirtyBounds);

			if (!skipRender)
			{
				///
				/// Update our Texture from our PBO (pixel buffer object)
				///
				glBindTexture(GL_TEXTURE_2D, this.texture_id_);
				glBindBuffer(GL_PIXEL_UNPACK_BUFFER, this.pbo_id_);
				glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, this.width_, this.height_,
					0, GL_BGRA, GL_UNSIGNED_BYTE, null);
				glBindBuffer(GL_PIXEL_UNPACK_BUFFER, 0);
				glBindTexture(GL_TEXTURE_2D, 0);


				// Clear our Surface's dirty bounds to indicate we've handled any
				// pending modifications to our pixels.
				ulSurfaceClearDirtyBounds(surface);
			}

			return this.texture_id_;
		}
	}
}
