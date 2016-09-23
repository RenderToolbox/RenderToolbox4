Note on exporting the SpectralIllusion parent scene from Blender.

The scene contains a cube with rounded edges.  The rounding comes from a “subsurf” modifier applied to a “normal” cube with right angle edges.

In Blender it makes sense to keep the normal cube and the subsurf modifier as separate things.  This reduces the number of vertices that Blender needs to store for the cube.  It also makes it more convenient to modify the cube if you want—you can just treat it like a normal cube and let Blender worry about making the edges look round and pretty.  You can also fiddle with the subsurf modifier itself to change how much rounding Blender should do.

But this only works in Blender.  Collada, RenderToolbox3, PBRT, and Mitsuba don’t have the same concept of subsurf modifier.  So when exporting the scene from Blender, you must “bake in” the rounded edges so that they become part of the cube’s vertex data.  This adds lots of vertices to the cube.

Here’s how to have it both ways.  When you export SpectralIllusion from Blender:

 1. Open SpectralIllusion.blend in Blender.
 2. In the Outliner view, click on the “Cube” object.
 3. In the Properties view, click on the “Modifiers” tab (wrench icon).
 4. Find the “Subsurf” modifier and click “Apply”.  This adds the rounded edges to the cube’s vertex data.
 5. Export the scene with File -> Export -> Collada
 6. Undo step 4 by pressing Ctrl-Z (or Command-Z).

Now you have a Collada file with rounded edges “baked in”, and the Blender scene is still relatively small and convenient to work with.
