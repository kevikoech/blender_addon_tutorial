
*******************
Reference API Usage
*******************

Blender has many interlinking data types which have an auto-generated reference api which often has the information
you need to write a script, but can be difficult to use.

This document is designed to help you understand how to use the reference api.


Reference API Scope
===================

The reference API covers ``bpy.types``, which stores types accessed via ``bpy.context`` - *The user context*
or ``bpy.data`` - *Blend file data*.

Other modules such as ``bge``, ``bmesh`` and ``aud`` are not using Blenders data API
so this document doesn't apply to these modules.


Data Access
===========

The most common case for using the reference API is to find out how to access data in the blend file.

Before going any further its best to be aware of ID Data-Blocks in Blender since you will often find properties
relative to them.


ID Data
-------

ID Data-Blocks are used in Blender as top-level data containers.

From the user interface this isn't so obvious, but when developing you need to know about ID Data-Blocks.

ID data types include Scene, Group, Object, Mesh, Screen, World, Armature, Image and Texture.
for a full list see the sub-classes of
`bpy.types.ID <http://www.blender.org/documentation/blender_python_api_2_64_6/bpy.types.ID.html>`_: 

Here are some characteristics ID Data-Blocks share.

- ID's are blend file data, so loading a new blend file reloads an entire new set of Data-Blocks.
- ID's can be accessed in Python from ``bpy.data.*``
- Each data-block has a unique ``.name`` attribute, displayed in the interface.
- Animation data is stored in ID's ``.animation_data``.
- ID's are the only data types that can be linked between blend files.
- ID's can be added/copied and removed via Python.
- ID's have their own garbage-collection system which frees unused ID's when saving.
- When a datablock has a reference to some external data, this is typically an ID Data-Block.


Simple Data Access
------------------

Lets start with a simple case, say you wan't a python script to adjust the objects location.

Start by finding this setting in the interface ``Properties Window -> Object -> Transform -> Location``

From the button you can right click and select **Online Python Reference**, this will link you to:
http://www.blender.org/documentation/blender_python_api_2_64_6/bpy.types.Object.html#bpy.types.Object.location

Being an API reference, this link often gives little more information then the tooltip, though some of the pages
include examples (normally at the top of the page).

At this point you may say *Now what?* - you know that you have to use ``.location`` and that its an array of 3 floats
but you're still left wondering how to access this in a script.

So the next step is to find out where to access objects, go down to the bottom of the page to the **References**
section, for objects there are many references, but one of the most common places to access objects is via the context.

It's easy to be overwhelmed at this point since there ``Object`` get referenced in so many places - modifiers,
functions, textures and constraints.

But if you want to access any data the user has selected
you typically only need to check the ``bpy.context`` references.

Even then, in this case there are quite a few though if you read over these - most are mode specific.
If you happen to be writing a tool that only runs in weight paint mode, then using ``weight_paint_object``
would be appropriate.
However to access an item the user last selected, look for the ``active`` members,
Having access to a single active member the user selects is a convention in Blender: eg. ``active_bone``,
``active_pose_bone``, ``active_node`` ... and in this case we can use - ``active_object``.


So now we have enough information to find the location of the active object.

.. code-block:: python

   bpy.context.active_object.location

You can type this into the python console to see the result.

The other common place to access objects in the reference is ``BlendData.objects``.

.. note::

   This is **not** listed as ``bpy.data.objects``,
   this is because ``bpy.data`` is an instance of the ``BlendData`` class, so the documentation points there.


With ``bpy.data.objects``, this is a collection of objects so you need to access one of its members.

.. code-block:: python

   bpy.data.objects["Cube"].location


Nested Properties
-----------------

The previous example is quite straightforward because `location`` is a property of ``Object`` which can be accessed
from the context directly.

Here are some more complex examples:

.. code-block:: python

   # access a render layers samples
   bpy.context.scene.render.layers["RenderLayer"].samples

   # access to the current weight paint brush size
   bpy.context.tool_settings.weight_paint.brush.size  

   # check if the window is fullscreen
   bpy.context.window.screen.show_fullscreen


As you can see there are times when you want to access data which is nested
in a way that causes you to go through a few indirections.

The properties are arranged to match how data is stored internally (in blenders C code) which is often logical but
not always quite what you would expect from using Blender.

So this takes some time to learn, it helps you understand how data fits together in Blender which is important
to know when writing scripts.


When starting out scripting you will often run into the problem where you're not sure how to access the data you want.

There are a few ways to do this.

- Use the Python console's auto-complete to inspect properties. *This can be hit-and-miss but has the advantage
  that you can easily see the values of properties and assign them too to interactively see the results.*

- Copy the Data-Path from the user interface. *Explained in the next section*

- Using the documentation to follow references. *Explained further in 'Indirect Data Access'*


Copy Data Path
--------------

Blender has a feature to copy the data-path which gives the path from an ``ID`` datablock, to its property.
This shortcut can save having to use the API reference to click back up the references to find where data is accessed
from.

To see how this works we'll get the path to the Subdivision-Surface modifiers subdivision setting.

Start with the default scene and select the **Modifiers** tab, then add a **Subdivision-Surface** modifier to the cube.

Now hover your mouse over the button labeled **View**, The tooltip includes ``SubsurfModifier.levels`` but we want the
path from the object to this property.

``<ID>.<DATA_PATH>`` == ``PROPERTY`` (CB: I THINK YOU NEED TO ELABORATE ON THIS)

Type in the ID path into a Python console ``bpy.context.active_object.`` Include the trailing dot and don't hit "enter", yet. 

Now right click on the button and select **Copy Data Path**, then paste the result into the console right after ``bpy.context.active_object.``

So now you could have the answer:

.. code-block:: python

   bpy.context.active_object.modifiers["Subsurf"].levels

Hit "enter" and you'll get the current value of 1. Now try changing the value to 2:

-- code-block:: pyton
  bpy.context.active_object.modifiers["Subsurf"].levels = 2

You can see the value update in the Subdivision-Surface modifier's UI as well as the cube.


Indirect Data Access
--------------------

So for this example we'll go over something more involved,
and show the steps to access from the blur nodes size property.

Start by switching to the 'Compositing' screen, enabling **Use Nodes** from the Header and add a blur node
(Add -> Filter -> Blur).

Now lets say we want to access the ``X`` button via python, to automatically adjust the size of blur nodes for example.


- Right click on the **X** button and select the **Online Python Reference** takes you to ``bpy.types.CompositorNodeBlur.size_x``

- Knowing this is accessed via ``size_x`` isn't helpful on its own, we want to know how this node is accessed too.

  *from this page notice that there are no* **References** *to this class,
   this is because the generic parent class is referenced*

- At the top of the page click on `CompositorNode(Node)`

  *There are also no references from there*

- At the top of the page click on `Node`, And scroll down to the References.
  Now there are quite a few references here, ``bpy.context.active_node`` may be what you're after
  however this only works when the script executes in the node editor.

- In this case we'll select ``CompositorNodeTree.nodes``.

- The ``CompositorNodeTree`` is referenced from ``Scene.node_tree``.

Now you can use the python console to form the data path needed to access the nodes size_x, logically we now know. (CB: YOU'VE NOT REALLY EXPLAINED THE "data path" CONCEPT)

*Scene -> NodeTree -> Nodes -> Size X*

Since the attribute for each is given along the way we can compose the data path in the python console:

.. code-block:: python

   bpy.context.scene.node_tree.nodes["Blur"].size_x


Admittedly some of the choices made when going backwards through the references aren't so obvious,
when encountering areas like this for the first time it may take some trial and error to get the path you are
looking for.
On the other hand there can be multiple ways to access the same data, which you choose often depends on the task.

If you are writing a user tool normally you want to use the ``bpy.context`` since the user normally expects
the tool to operate on what they have selected.

For automation you are more likely to use ``bpy.data`` since you want to be able to access specific data and manipulate
it, no matter what the user currently has the view set at.


== Operators ==

TODO

