import processing.svg.*;
import processing.pdf.*;
import geomerative.*;

/* Set the width and height of your screen canvas in pixels */
final int CONFIG_WIDTH_PIXELS = 500;
final int CONFIG_HEIGHT_PIXELS = 500;

/*
 * When generating high-resolution images, the CONFIG_SCALE_FACTOR
 * is used as the multiplier for the number of pixels. (e.g, a canvas
 * of 1000x1000px with a scale factor of 5 gives a 5000x5000px image.
 */
final int CONFIG_SCALE_FACTOR = 5;

/*
 * Gcode-generation settings. Edit these as per your needs.
 * CONFIG_PRINT_WIDTH_MM      : The width of paper in mm 
 * CONFIG_PRINT_HEIGHT_MM     : The height of the paper in mm
 * CONFIG_GCODE_PEN_UP        : The gcode for raising up the pen 
 * CONFIG_GCODE_PEN_DOWN      : The gcode for lowering the pen
 * CONFIG_GCODE_MOVE_FEEDRATE : The feedrate during drawing moves
 * CONFIG_GCODE_RAPID_FEEDRATE: The feedrate during rapid moves
 * CONFIG_GCODE_PRE           : This is added to the top of the file
 * CONFIG_GCODE_POST          : This is added at the end of the file
 */
final int CONFIG_PRINT_WIDTH_MM = 200;
final int CONFIG_PRINT_HEIGHT_MM = 200;
final String CONFIG_GCODE_PEN_UP = "M03 S0\n";
final String CONFIG_GCODE_PEN_DOWN = "M03 S20\n";
final String CONFIG_GCODE_MOVE_FEEDRATE = "5000";
final String CONFIG_GCODE_RAPID_FEEDRATE = "10000";
final String CONFIG_GCODE_PRE =
    /* Use absolute positioning */
    "G90\n" +
    /* Raise the pen (in case it's currently lowered) */
    CONFIG_GCODE_PEN_UP +
    /* Move to origin: (0, 0) */
    "G0 F" + CONFIG_GCODE_RAPID_FEEDRATE + " X0 Y0\n";
final String CONFIG_GCODE_POST =
    /* Raise the pen (in case it's currently lowered) */
    CONFIG_GCODE_PEN_UP +
    /* Move to origin: (0, 0) */
    "G0 F" + CONFIG_GCODE_RAPID_FEEDRATE + " X0 Y0\n";
















/*
 * =========================================================
 * =========================================================
 * Ignore everything below this line! Just press '?' while
 * your sketch is running to get a list of available options
 * to export your sketch into various formats.
 * =========================================================
 * =========================================================
 */

int seed;

void settings() {
  size(CONFIG_WIDTH_PIXELS, CONFIG_HEIGHT_PIXELS);
}

void setup() {
  seed = millis();
  seededRender();
}

void draw() {
}

void seededRender() {
  randomSeed(seed);
  noiseSeed(seed);
  render();
}

void keyPressed() {
  switch(key) {
  case 'l':
    saveLowRes();
    break;
  case 'h':
    saveHighRes(CONFIG_SCALE_FACTOR);
    break;
  case 'p':
    savePDF();
    break;
  case 's':
    saveSVG();
    break;
  case 'g':
    saveGcode(true);
    break;
  case 'G':
    saveGcode(false);
    break;
  case 'n':
    seed = millis();
    seededRender();
    break;
  case '?':
    println("Keyboard shortcuts:");
    println("  n: Generate a new seeded image");
    println("  l: Save low-resolution image");
    println("  h: Save high-resolution image");
    println("  p: Save PDF version");
    println("  s: Save SVG version");
    println("  g: Save Gcode for plotter");
    println("  G: Dump Gcode to serial output");
  }
}

void saveLowRes() {
  println("Saving low-resolution image...");
  save("lowres-" + seed + ".png");
  println("Finished");
}

void saveHighRes(int scaleFactor) {
  PGraphics hires = createGraphics(
    width * scaleFactor, 
    height * scaleFactor, 
    JAVA2D);
  println("Saving high-resolution image...");
  beginRecord(hires);
  hires.scale(scaleFactor);
  seededRender();
  endRecord();
  hires.save(seed + "highres-" + seed + ".png");
  println("Finished");
}

void savePDF() {
  println("Saving PDF image...");
  beginRecord(PDF, "vector-" + seed + ".pdf");
  seededRender();
  endRecord();
  println("Finished");
}

void saveSVG() {
  println("Saving SVG image...");
  beginRecord(SVG, "vector-" + seed + ".svg"); 
  seededRender();
  endRecord();
  println("Finished");
}

void saveGcode(boolean writeToFile) {
  println("Saving Gcode...");
  /* Write image to temporaray SVG file */
  beginRecord(SVG, "temp-" + seed + ".svg"); 
  seededRender();
  endRecord();
  
  /* Generate Gcode */
  __saveGcode(writeToFile);
  
  /* Delete temporaray SVG file */
  File file = sketchFile("temp-" + seed + ".svg");
  file.delete();
  println("Finished");
}

/*
 * Encode a given point (x, y) into the different regions of
 * a clip window as specified by its top-left corner (cx, cy)
 * and it's width and height (cw, ch).
 */
int encode_endpoint(
  float x, float y,
  float clipx, float clipy, float clipw, float cliph)
{
  int code = 0; /* Initialized to being inside clip window */

  /* Calculate the min and max coordinates of clip window */
  float xmin = clipx;
  float xmax = clipx + clipw;
  float ymin = clipy;
  float ymax = clipy + clipw;

  if (x < xmin)       /* to left of clip window */
    code |= (1 << 0);
  else if (x > xmax)  /* to right of clip window */
    code |= (1 << 1);

  if (y < ymin)       /* below clip window */
    code |= (1 << 2);
  else if (y > ymax)  /* above clip window */
    code |= (1 << 3);

  return code;
}

class ClippedLineResponse {
  public float x0, y0;
  public float x1, y1;
  public boolean clipped;
  public boolean reject;
  
  ClippedLineResponse() {
    clipped = false;
    reject = false;
  }
  
  void set(float px0, float py0, float px1, float py1) {
    x0 = px0;
    y0 = py0;
    x1 = px1;
    y1 = py1;
  }
};

ClippedLineResponse line_clipped(
  float x0, float y0, float x1, float y1,
  float clipx, float clipy, float clipw, float cliph) {

  /* Stores encodings for the two endpoints of our line */
  int e0code, e1code;
  
  ClippedLineResponse ret = new ClippedLineResponse();

  /* Calculate X and Y ranges for our clip window */
  float xmin = clipx;
  float xmax = clipx + clipw;
  float ymin = clipy;
  float ymax = clipy + cliph;

  /* Whether the line should be drawn or not */
  //boolean accept = false;
  ret.reject = true;

  do {
    /* Get encodings for the two endpoints of our line */
    e0code = encode_endpoint(x0, y0, clipx, clipy, clipw, cliph);
    e1code = encode_endpoint(x1, y1, clipx, clipy, clipw, cliph);

    if (e0code == 0 && e1code == 0) {
      /* If line inside window, accept and break out of loop */
      //accept = true;
      ret.reject = false;
      break;
    } else if ((e0code & e1code) != 0) {
      /*
       * If the bitwise AND is not 0, it means both points share
       * an outside zone. Leave accept as 'false' and exit loop.
       */
      break;
    } else {
      /* Pick an endpoint that is outside the clip window */
      int code = e0code != 0 ? e0code : e1code;

      float newx = 0, newy = 0;
      
      /*
       * Now figure out the new endpoint that needs to replace
       * the current one. Each of the four cases are handled
       * separately.
       */
      if ((code & (1 << 0)) != 0) {
        /* Endpoint is to the left of clip window */
        newx = xmin;
        newy = ((y1 - y0) / (x1 - x0)) * (newx - x0) + y0;
      } else if ((code & (1 << 1)) != 0) {
        /* Endpoint is to the right of clip window */
        newx = xmax;
        newy = ((y1 - y0) / (x1 - x0)) * (newx - x0) + y0;
      } else if ((code & (1 << 3)) != 0) {
        /* Endpoint is above the clip window */
        newy = ymax;
        newx = ((x1 - x0) / (y1 - y0)) * (newy - y0) + x0;
      } else if ((code & (1 << 2)) != 0) {
        /* Endpoint is below the clip window */
        newy = ymin;
        newx = ((x1 - x0) / (y1 - y0)) * (newy - y0) + x0;
      }
      
      /* Now we replace the old endpoint depending on which we chose */
      if (code == e0code) {
        x0 = newx;
        y0 = newy;
      } else {
        x1 = newx;
        y1 = newy;
      }
      
      ret.clipped = true;
    }
  } while (true);

  /* Only draw the line if it was not rejected */
  if (!ret.reject)
    ret.set(x0, y0, x1, y1);

  return ret;
}

boolean penDown = false;

String __moveTo(float x, float y, boolean rapid) {
  String feed = rapid ? CONFIG_GCODE_RAPID_FEEDRATE : CONFIG_GCODE_MOVE_FEEDRATE;
  return "G1 F" + feed +
         " X" + str(x) +
         " Y" + str(y) + "\n";
}

String __drawLine(float x0, float y0, float x1, float y1, boolean rapid) {
  String snippet = "";
  ClippedLineResponse ret = line_clipped(x0, y0, x1, y1, 0, 0, CONFIG_PRINT_WIDTH_MM, CONFIG_PRINT_HEIGHT_MM);
  
  if (ret.reject) {
    if (penDown) {
      snippet += CONFIG_GCODE_PEN_UP;
      penDown = false;
    }
    return snippet;
  }
  
  snippet += __moveTo(ret.x0, ret.y0, rapid);
  if (!penDown) {
    snippet += CONFIG_GCODE_PEN_DOWN;
    penDown = true;
  }
  snippet += __moveTo(ret.x1, ret.y1, rapid);
  
  if (ret.clipped) {
    snippet += CONFIG_GCODE_PEN_UP;
    penDown = false;
  }
  
  return snippet;
}

void __saveGcode(boolean writeToFile) {
  RShape grp;
  RPoint[][] paths;
  boolean ignoringStyles = false;
  String gcode = CONFIG_GCODE_PRE;

  /* Load SVG file and convert to paths */
  RG.init(this);
  RG.ignoreStyles(ignoringStyles);
  RG.setPolygonizer(RG.ADAPTATIVE);
  grp = RG.loadShape("temp-" + seed + ".svg");
  grp.centerIn(g, 0, 0, 0);
  paths = grp.getPointsInPaths();

  for (int i = 0; i < paths.length; i++) {
    if (paths[i] == null)
      continue;

    //boolean outOfClip = true;
    boolean initialized = false; 
    float lastx = 0;
    float lasty = 0;
    for (int j = 0; j < paths[i].length; j++) {
      //vertex(pointPaths[i][j].x, pointPaths[i][j].y);
      float xmapped = map(paths[i][j].x, 0, width, 0, CONFIG_PRINT_WIDTH_MM);
      /* Flip Y axis since GRBL expects (0, 0) to be at the bottom left */
      float ymapped = map(paths[i][j].y, 0, height, CONFIG_PRINT_HEIGHT_MM, 0);
      
      if (!initialized) {
        lastx = xmapped;
        lasty = ymapped;
        initialized = true;
        continue;
      }
      
      gcode += __drawLine(lastx, lasty, xmapped, ymapped, false);
      lastx = xmapped;
      lasty = ymapped;
    }
    gcode += CONFIG_GCODE_PEN_UP;
    penDown = false;
  }
  
  gcode += CONFIG_GCODE_POST;
  
  if (writeToFile) {
    /* Write out the Gcode file */
    PrintWriter out = createWriter("gcode-" + seed + ".gcode");
    out.println(gcode);
    out.flush();
    out.close();
  } else {
    println(gcode);
  }
}