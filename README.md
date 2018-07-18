OIT Sample in Unity using per-pixel linked lists
------------------------------------------------

Overview:
---------
1) The transparent geometry shader is writing out pixel color, depth and the next list link in a linked list StructureBuffer.
2) OnRenderImage, composite the transparent geometry in the scene by sorting the current pixel's linked list by pixel depth. Blend the sorted colors with the rest of the scene.

Known issues:
-------------
For some reason there is a lot of flickering when writing the full rgb color. I haven't had the chance to investigate yet, but it could be a syncing/race condition problem.
A workaround for now is it write only the blue channel as output of the OIT composition.

Improvements to be done:
------------------------
1) Experiment with different sorting algorithms
3) Integrate this into the Standard Shader
4) See how this fits and scales in a more complex scene


Based on the article by AMD: http://developer.amd.com/wordpress/media/2013/06/2041_final.pdf