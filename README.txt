OIT Sample in Unity using per-pixel linked lists
------------------------------------------------

Overview:
---------
1) The transparent geometry shader is writing out pixel color, depth and the next list link in a linked list StructureBuffer.
2) OnPostRender, resolve the transparent geometry by sorting the per pixel linked list by pixel depth.
2) OnRenderImage, blend the sorted transparency texture with the rest of the scene.

Improvements to be done:
------------------------
1) Experiment with different sorting algorithms
3) Integrate this into the Standard Shader
4) See how this fits and scales in a more complex scene


Based on the article by AMD: http://developer.amd.com/wordpress/media/2013/06/2041_final.pdf