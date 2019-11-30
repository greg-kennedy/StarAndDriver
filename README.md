Starship Trader Monthly
=======================
A [NaNoGenMo 2019](https://github.com/NaNoGenMo/2019) entry by Greg Kennedy.

## Read the novel here: <https://archive.org/details/nanogenmo_2019_starshiptradermonthly> ##
(126MB PDF file, 54 pages)

**View the code here: <https://github.com/greg-kennedy/StarAndDriver>**

**See the NaNo issue here: <https://github.com/NaNoGenMo/2019/issues/7>**

Overview
--------
**Starship Trader Monthly** is a catalog of generated science fiction space vehicles.  Presented in a "classified ads" format, each item in the catalog comes with a brief description, and a 3d rendered picture of the subject.

The actual text of the book is significantly less than 50,000 words.  But since the book is mainly a frame to show pretty pictures, and the common exchange rate is "**One Picture == One Thousand Words**", there is another way to meet the NaNo requirement: the book contains 50 pages of generated pictures (48 pages, plus front and back cover), thus the *equivalent* of 50,000 words.

The code used to produce the catalog is called "Star And Driver", a pun on the popular auto magazine that I am too stubborn to change now.  It is written in Perl, as a main script and several modules.  The images are rendered by passing a procedurally generated script to [POV-Ray](https://povray.org).  Text generation is through custom Perl text smashing, with data sources taken from [dariusk/corpora](https://github.com/dariusk/corpora).  [PDF::API2](https://metacpan.org/pod/PDF::API2) is used to collect all text and images together, laying them out into the final format.

More details about the code follows.

Text
----
Text generation routines are collected in `Text.pm` using an ad-hoc system for pasting together substrings.  Data files are in the `data/` subfolder.  The top-level script `text.pl`, used for testing, will generate one description and print it to stdout.

Descriptions are composed of these items (with sources in parentheses):

* a name (animals, Greek titans, Roman gods),
* a manufacturer (NSA declassified projects),
* a line or two of backstory (culled from various Craigslist ads for trucks),
* some features (assembled from fictional materials / chemical elements, sci-fi energy sources, and a list of technology buzzwords),
* a location (lists of planets and planetoids),
* a seller (names combined from Star Wars and Star Trek),
* contact number (a silly function to create futuristic phone numbers), and
* a price.

There are some other modifiers sprinkled in, e.g. planet names may have "Alpha", "Beta", or ship names may have a "II" or "Limited" suffix.  I did not have a chance to learn [Tracery](https://tracery.io/) (again) this year, which is too bad, because the templates seem like a natural fit for that grammar system.

When laying out on the page, lines that don't fit are simply cut off.  This can happen on the smallest square layout with a lot of text - unfortunately I ran out of time to figure out an appropriate "resizing" method to retain all the text.

Images
------
The bulk of time, both in developer effort and in actual novel generation, is spent on image generation.  Images are produced by feeding procedurally generated scripts to the Persistence of Vision Raytracer.  POV-Ray's human-friendly script format, from a time before GUI modeling tools were the norm, is an excellent fit for generative art.  The language includes a large collection of 3d primitives which is WAY easier than having to calculate triangle vertices for meshes and so on.

Image generation code begins in `Image.pm`.  Here a basic scene is set up, a background and ship type are chosen, and a script generated.  Calling `render()` on the Image object causes a system call to POV-Ray, and then (optionally) OptiPNG, and returns the filename of the rendered .png image.  (An example render can be run from the top-level script `image.pl`, which simply includes the Image module and some configuration, and executes the `render()` function once.)

Originally, there were plans to feature several backgrounds in random rotation - solid color, or parked on a planet surface, etc.  Due to time this was scaled back to have only the single `Space.pm` background, though the loading code for other modules remains.  The Space background is a large sphere with starfield texture, plus zero or more layers of colorful semitransparent noise to create nebula-like gasses.  There is always a planet in the scene, with a 20% chance to have a ring, but because it is randomly rotated about the camera it often simply doesn't appear.

Ships are created from "components", short objects that contain a POV-Ray script snippet, and an optional "links" array that lists the points for future expansion.  For example, the Tube object is a cylinder with the base at <0, 0, 0>, the top at <0, height, 0> and a varying radius.  It has one link, at the top of the cylinder, in the same direction as the incoming vector.  A Box object has five links (one each for +/- X, +/- Z, and +Y directions).  Some objects have no Links - these are terminating objects, like the glass half-sphere or pyramid cap.

Beginning from the "seed" component, this tool (ab)uses nested CSG Union to create recursive sub-objects, each with their own cumulative rotation and translation.  Child components are built assuming <0, 0, 0> as the base point and +y as "up", while the coordinate space has been pre-adjusted to place it in the right position.  Doing it this way spares me from having to calculate 3d vector rotation, but has the drawback that all coordinates are relative... thus, some features (like, engines with colorful trails that always pointed "backwards") had to be cut.

As components lead to deeper recursion they also pass their dimensions to the children, so that the subcomponents are smaller than their parents.  Depending on the object type, recursion can terminate at a certain depth, or once a subcomponent is smaller than some threshold.

Overall, there are three major types of Object that can be created:

* "Hulk".  This is the simplest object: a 1x1x1 cube that grows randomly outward from all six faces.  The Hulk has no symmetry and often looks like a mass of space junk, a strange alien craft, or some kind of probe/satellite in simpler cases.
* "Ship".  This is a near-cube that grows in five directions: +/- Y, +/- Z, and +X.  After recursively adding components, the entire structure is clipped by a plane such that everything in the -X hemisphere is discarded.  The remaining portion is copied and mirrored across the YZ plane to create an object with bilateral symmetry.
* "Radial".  This generator makes starbase-type objects with radial symmetry.  A cylinder with links at top, bottom, and three points along the side is created and added to.  Then, the object is clipped by two planes lengthwise.  The remaining segment is copied and rotated to complete the full 360 degrees.

The final necessary step is texture generation.  Each component chooses one of five random textures, named "Tex1" through "Tex5" (or in the case of glass spheres, "Tex_Glass").  These five texture definitions are created at the top of the script by Image.pm using one of two methods, randomly selected:

* "Paint".  Each texture has a base pigment of closely grouped R, G, and B components, to simulate a grayish base coat.  Over this is added one patterned texture, chosen from POV-Ray's extensive pattern library, with a random color assigned.  This top coat gives the detailed neon stripes, swirls, etc. to the object it's applied to.
* "Metal".  Highly reflective surfaces chosen at random from the POV-Ray metals library.  One of five main classes ("Silver", "Chrome", "Gold", "Brass", "Copper") is picked, then a random variant and finish is added.

In either case a normal map is added to simulate dents, dings, weird ripples and so on.

Overall quality settings are controlled by the Image class constructor, which in turn inherits from the constant definitions of `main.pl`.

PDF
---
Star and Driver uses the fantastic PDF::API2 Perl module to assemble its PDF document.  I did my best to hide the details in `Document.pm`, a class that wraps a PDF and exposes methods to make working with it easier.  PDF has no concept of paragraphs or multi-line text: all text must be written line-by-line and word wrapping handled manually.

Internally, PDF treats pages as having a DPI of 72, so the page size for the 8.5" by 11" book is 612x792.  Margins are set at 1/4" for all sides.  However, fractional point values are permitted (necessary for getting the borders to align right), and images can be stored from any DPI and will be resized to fit.  All renders for the final version of this book are calculated to achieve 300 DPI when embedded in the PDF.  Zoom in for more detail!

For catalog pages, the layout is divided into 2 column by 3 row blocks, then filled by horizontal or vertical boxes that may take one or more cells.  The list of potential layouts is specified in `main.pl` and chosen at random.  For each layout, the text is first generated and placed on the page, possibly aligned to the top, left, or right sides.  In these cases a border is created first, then text added, and finally the border is filled and stroked.  The remaining space is then used as dimensions for the image render.

Working with this library is a bit nerve-wracking because, if the script dies midway through, recovery from a damaged PDF can be difficult or impossible and hours of work is lost.  Most of the methods attempt to call `finishobjects()` and write to file when possible, to minimize memory use.  It would be nice to be able to save a "partial" PDF as a checkpoint and continue processing, but I was unable to figure this out.

Closing Notes
-------------
The beginning of this project was ported over from [last year's abandoned attempt](https://github.com/NaNoGenMo/2018/issues/7), and had some effort made to modularize the code: this is when I wrote most of the dynamic loading parts.  As the deadline drew nearer I started to add more hacks... for example, Hulk types were too common, so there is a line in Image.pm which will try to re-roll the object class if Hulk is returned!

NaNoGenMo projects can be perhaps categorized into either "text" books - those which mimic a traditional novel and attempt narrative techniques - and "art" books, which are geared towards visual presentation.  _Starship Trader Monthly_ is definitely the latter, and probably the last one I'll attempt.  It's very flashy, but ultimately doesn't do much to push the limits on narrative generation, which is what got me interested in NaNoGenMo to begin with.  I do think the individual excerpts and renderings would make a nice Twitter bot or similar, or maybe something fun to do in ProcJam.  Next year, though, it's back to work on the Great ~~American~~ Computerized Novel.
