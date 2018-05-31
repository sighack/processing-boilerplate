# A Processing Boilerplate for Generative Artists

This repository contains a simple boilerplate for generative artists working
with creating images in Processing. Features include:

- **Reproducible images via a random seeds**: Many times, you want to be able to predictably reproduce an image exactly as it was but in a different format (e.g., a higher resolution version). This is done by seeding the random-number generator in Processing and re-using the same seed. This boilerplate provides all the needed code to do this.
- **Lots of export options**: You can export images on screen to a multitude of formats. This includes low-resolution PNGs, high-resolution PNG, PDF, SVG, as well as Gcode suitable for sending to a plotter.
- **Non-intrusive**: All of this is highly configurable and only involves adding a single file to your Processing sketch. It's relatively non-intrusive to normal workflows and existing sketches can be adapted fairly easily.
- **Gcode generation for pen plotters**: Currently, generating Gcode requires exporting SVGs, importing them into Inkscape, and generating the Gcode. This script lets you avoid that annoying intermediate step with a highly configurable Gcode generator.

## Usage

You will first need to install the [Geomerative](http://www.ricardmarxer.com/geomerative/) Processing library. This can be done from `Sketch --> Import Library --> Add Library`. Just search for Geomerative and click `Install` in the bottom left of the window.

The `code` folder contains a `boilerplate` folder with two files (`boilerplate.pde` and `scaffold.pde`). The folder can be duplicated for any new sketches you write. The `scaffold.pde` file contains all the configuration options at the top of the file (variables starting with the prefix `CONFIG_` can be modified).

The `boilerplate.pde` file contains an example of how to write a sketch that works with the scaffolding code. Basically, you just implement a `render()` function in `boilerplate.pde`

If you're starting a new sketch, just copy over the two files, and rename `boilerplate.pde` to a file name of your choice. If you're using an existing sketch, you'll have to re-arrange your code to have all your drawing logic in a single `render()` function that draws everything on screen.

### Configuring Screen Size

In Processing, you would normally call `size()` to set the screen size. However, the scaffolding code does this for you using two parameters called `CONFIG_WIDTH_PIXELS` and `CONFIG_HEIGHT_PIXELS`. Just modify these in `scaffold.pde` to change your screen size.

### Runtime Help

Some keyboard shortcuts are bound to specific actions and these can be viewed by pressing `?` while running the sketch. Here is the output it gives:

	Keyboard shortcuts:
	  n: Generate a new seeded image
	  l: Save low-resolution image
	  h: Save high-resolution image
	  p: Save PDF version
	  s: Save SVG version
	  g: Save Gcode for plotter
	  G: Dump Gcode to serial output

Pressing `n` generates a new seeded image, while `l`, `h`, `p`, `s`, and `g` write files into your sketch folder. Files are consistently named in the format `prefix-<seed>.<extension>`. The prefix specifies the export type (can be `lowres`, `highres`, `vector`, or `gcode`). The seed specifies the number used as the seed for the random-number generator in case you need to regenerate an identical image in the future. Finally, extension is one of `svg`, `pdf`, `png`, or `gcode`.

### High-Resolution PNG Output

To generate a high-resolution version of your image, just set the `CONFIG_SCALE_FACTOR` in `scaffold.pde` to an appropriate value. The `CONFIG_SCALE_FACTOR` value is used as the multiplier for the number of pixels. (e.g, a canvas of 500x500px with a scale factor of 10 gives a 5000x5000px image when `h` is pressed).

### GCode Configuration

The scaffolding code contains basic code to output most shapes to standard Gcode for use with pen plotters.

**NOTE: CURRENTLY, USING THE `arc()` CALL DOES NOT WORK DUE TO A BUG IN THE GEOMERATIVE LIBRARY**.

The following configuration parameters exist to allow you to configure the Gcode generation to your needs:

- **CONFIG\_PRINT\_WIDTH_MM**: Specifies the width of paper you'll be plotting on (in mm). The millimeters doesn't really matter and really depends on what units you configure in your Gcode sender program.
- **CONFIG\_PRINT\_HEIGHT_MM**: The height of the paper in mm.
- **CONFIG\_GCODE\_PEN_UP**: This contains a string of Gcode for raising up the pen. This is typically done in [Grbl](https://github.com/gnea/grbl/)-based plotters using the `M3` code with a speed setting specified by the `S` parameter. So something like `M3 S0`. This may vary depending on your exact plotter so you'll have to test for the right value to give to the `S` parameter. My approach is to open up a Gcode sender (like [Universal Gcode Sender](https://github.com/winder/Universal-G-Code-Sender)), connect to the Grbl serial console, and manually type out `M3` commands to see which one works best. You only need to do this once for each plot to figure out the best settings.
- **CONFIG\_GCODE\_PEN_DOWN**: The Gcode for lowering the pen. This is similar to the `CONFIG_GCODE_PEN_UP` option but typically changes the value passed to the `S` parameter.
- **CONFIG\_GCODE\_MOVE\_FEEDRATE**: This specifies the feedrate to use during drawing moves (in mm/min, which is the standard unit in Grbl). That is, when the pen is lowered onto the paper and drawing.
- **CONFIG\_GCODE\_RAPID\_FEEDRATE**: The feedrate used during rapid moves. These are moves to starting points of lines or curves where you don't want the plotter to draw, or moves to the origin. This can typically be set to be higher.
- **CONFIG\_GCODE\_PRE**: This is custom Gcode that is automatically added to the top of the file. You can put anything in here. In the current version, the default actions performed here are: _(1)_ the controller is configured to use absolute positioning, _(ii)_ the pen is raised (in case it's currently lowered), and finally _(iii)_ the pen is moved to the configured origin (done in the Gcode sender program). You can modify this to be anything.
- **CONFIG\_GCODE\_POST**: This is code that is automatically added at the end of the file. Currently, it simply raises the pen and moves back to the origin.
