/*
MIT License

Copyright (c) 2018 Pantelis Lekakis

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

[ExecuteInEditMode]
public class OITCamera : MonoBehaviour
{
    public Shader m_compositeShader;            // shader to composite the sorted transparency target with the rest of the scene
    public ComputeShader m_clearBuffersShader;  // shader to clear the headPointer buffer when the camera starts rendering the scene

    private ComputeBuffer m_headPointers;       // buffer where each element is a pointer to the linked list node head
    private ComputeBuffer m_listNodes;          // per-pixel linked list, containing color & depth information

    private int m_width;                        // target width
    private int m_height;                       // target height

    private Material m_compositeMat;            // composition material

    private const int kMaxPerPixelNodes = 20;   // How many levels deep we store information per-pixel
        
    //-------------------------------------------------------------
    private void Awake ()
    {
        m_width = 0;
        m_height = 0;
	}

    //-------------------------------------------------------------
    private void DestroyResources()
    {
        if (m_compositeMat != null)
            DestroyImmediate(m_compositeMat);
        m_compositeMat = null;
        
        if (m_headPointers != null)
            m_headPointers.Dispose();
        m_headPointers = null;

        if (m_listNodes != null)
            m_listNodes.Dispose();
        m_listNodes = null;
    }

    //-------------------------------------------------------------
    private void CreateResources()
    {
        m_width = Screen.width;
        m_height = Screen.height;

        DestroyResources();

        m_compositeMat = new Material(m_compositeShader);

        // The following must match the OITNode declaration in the shader-side.
        int nodeSizeInBytes = sizeof(float) * 4 + sizeof(float) + sizeof(uint);

        m_headPointers = new ComputeBuffer(m_width * m_height, sizeof(uint), ComputeBufferType.Default | ComputeBufferType.Counter);
        m_listNodes = new ComputeBuffer(m_width * m_height * kMaxPerPixelNodes, nodeSizeInBytes, ComputeBufferType.Default);
        
        Shader.SetGlobalBuffer("_OITHeadPointers", m_headPointers);
        Shader.SetGlobalBuffer("_OITNodes", m_listNodes);
    }

    //-------------------------------------------------------------
    private void OnPreRender()
    {
        // Reset the counter in the headPointers StructuredBuffer
        m_headPointers.SetCounterValue(0);

        // Now reset all the head pointers to 0xffffffff
        m_clearBuffersShader.SetBuffer(0, "_OITHeadPointers", m_headPointers);
        m_clearBuffersShader.Dispatch(0, (m_headPointers.count / 64) * 64, 1, 1);

        // I am not sure why this is required.
        // If I don't specify to descriptor registers when writing to UAV from the pixel shader, it's never writen to.
        Graphics.ClearRandomWriteTargets();
        
        Graphics.SetRandomWriteTarget(1, m_headPointers);
        Graphics.SetRandomWriteTarget(2, m_listNodes);
    }

    //-------------------------------------------------------------
    private void LateUpdate ()
    {
        // target dimensions have changed, re-create resources
        if ((Screen.width != m_width) || (Screen.height != m_height))
        {
            CreateResources();
        }
    }

    //-------------------------------------------------------------
    private void OnDestroy()
    {
        DestroyResources();        
    }

    //-------------------------------------------------------------
    private void OnDisable()
    {
        DestroyResources();
    }

    //-------------------------------------------------------------
    private void OnEnable()
    {
        CreateResources();
    }

    //-------------------------------------------------------------
    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        Graphics.Blit(source, destination, m_compositeMat);
    }
}
