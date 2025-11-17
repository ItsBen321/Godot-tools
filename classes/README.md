# Classes

## Dialogue
Simple extention of RichTextLabel that introduces a few new functions to easily load and display text.
Handles text buffers, a basic text animation, auto formatting and signals!

## Debugger
A very flexibly way to store and load any data in your game. Can be used for troubleshooting,
collecting stats, finding bugs, saving logs...
Can be part of an autoload script or be separated amongst Nodes. Could be incorporated in different tools.
Allows for a quick way to save .txt and .csv files as well!

## ObjectPooler
Improves performance by reusing the same repetitive scenes instead of having to instantiate and free every time.
Mainly designed for quick visual effects. Supports auto-starting or can be dynamically changed at runtime.
Also allows to recall _ready() and _exit() whenever you call take() or put() on the ObjectPooler.
