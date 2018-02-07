abstract class Graph {
  Table data;
  Visual[] visuals;

  Graph(Table data) {
    this.data = data;
  }

  void display() {
    drawGraph();
  }

  abstract void drawGraph();

  void drawAxes() {
    // Draw axes black
    stroke(BLACK);
    fill(BLACK);
    strokeWeight(width * 0.001);

    left = MARGIN * width;
    right = (1 - MARGIN) * width;
    top = MARGIN * height;
    bottom = (1 - MARGIN) * height;

    // X and Y axis lines
    // X-axis is flanked by MARGIN on sides and bottom
    line(left, bottom, right, bottom);
    // Y-axis is flanked by MARGIN on top/bottom and left
    line(left, top, left, bottom);

    // Labels are centered in the MARGINs around the graph
    textAlign(CENTER);
    text(data.xLabel, width/2, (1 - MARGIN/2) * height);
    
    // Label for y-axis is rotated 90 degrees
    drawRotatedText(data.yLabel, left/2, height/2, PI/2);

    // 10 tick marks along the y-axis
    float tickInterval = (bottom - top) / 10.0;
    float tickHalfWidth = 0.005 * width;
    float tickY = bottom - tickInterval;
    for (int i = 1; i <= 10; ++i) {
      line(left - tickHalfWidth, tickY, left + tickHalfWidth, tickY);
      text((int) (data.maxValue * i/10.0), 0.75 * left, tickY);
      tickY -= tickInterval;
    }
  }
}

class BarGraph extends Graph {
  BarGraph(Table data) {
    super(data);
    // Initialize empty bars for each data point
    visuals = new Bar[data.dataPoints.length];
    for (int i = 0; i < visuals.length; ++i) {
      visuals[i] = new Bar(data.dataPoints[i]);
    }
  }

  void drawGraph() {
    drawAxes();

    for (int i = 0; i < numDataPoints; ++i) {
      // Update position and size of bar
      visuals[i].updateInfo(i);

      color fillColor = MAIN_COLOR;
      if (visuals[i].mouseOver) {
        fillColor = HIGHLIGHT_COLOR;
      }

      visuals[i].display(fillColor);
    }

    boolean done = true;
    for (int i = 0; i < numDataPoints; ++i) {
      done = done && transitionDone[i];
    }

    if (done) {
      if (transitionOut) {
        transitionOut = false;
        graph = new LineGraph(data);
        transitionIn = true;
      } else if (transitionIn) {
        transitionIn = false;
      }
      transitionDone = new boolean[numDataPoints];
    }

    drawAxes();
  }
}

class LineGraph extends Graph {
  LineGraph(Table data) {
    super(data);
    visuals = new Point[data.dataPoints.length];
    for (int i = 0; i < visuals.length; ++i) {
      visuals[i] = new Point(data.dataPoints[i]);
    }
  }

  void drawGraph() {
    // Update position and sizes of dots but only plot lines so
    // dots are on top
    Visual prev = null;
    for (int i = 0; i < numDataPoints; ++i) {
      // Update position and size of bar
      visuals[i].updateInfo(i);

      // Since position has updated, draw line between current and previous points
      if (prev != null) {
        if (transitionOut || transitionIn) {
          color toColor = transitionOut ? WHITE : MAIN_COLOR;
          visuals[i].transitionColor = lerpColor(visuals[i].transitionColor, toColor, TRANSITION_SPEED);
          stroke(visuals[i].transitionColor);
        } else {
          stroke(MAIN_COLOR);
        }
        strokeWeight(width * 0.002);
        line(prev.x, prev.y, visuals[i].x, visuals[i].y);
      }

      // Save current point so we can draw a line between it and the next one
      prev = visuals[i];
    }

    // Plot dots
    for (int i = 0; i < numDataPoints; ++i) {
      color fillColor = MAIN_COLOR;
      if (visuals[i].mouseOver) {
        fillColor = HIGHLIGHT_COLOR;
      }

      visuals[i].display(fillColor);
    }

    boolean done = true;
    for (int i = 0; i < numDataPoints; ++i) {
      done = done && transitionDone[i];
    }

    if (done) {
      if (transitionOut) {
        transitionOut = false;
        graph = new BarGraph(data);
        transitionIn = true;
      } else if (transitionIn) {
        transitionIn = false;
      }
      transitionDone = new boolean[numDataPoints];
    }

    drawAxes();
  }
}

class PieChart extends Graph {
  PieChart(Table data) {
    super(data);
    visuals = new PieSlice[data.dataPoints.length];
    float fromAngle = 0;
    for (int i = 0; i < visuals.length; ++i) {
      visuals[i] = new PieSlice(data.dataPoints[i], data.total, fromAngle);
      fromAngle = ((PieSlice) visuals[i]).toAngle;
    }
  }

  void drawGraph() {
    fill(MAIN_COLOR);
    float diameter = min(width * (1 - 2*MARGIN), height * (1 - 2*MARGIN));
    ellipse(width/2, height/2, diameter, diameter);
    for (int i = 0; i < numDataPoints; ++i) {
      visuals[i].updateInfo(i);

      color fillColor = MAIN_COLOR;
      if (visuals[i].mouseOver) {
        fillColor = HIGHLIGHT_COLOR;
      }

      //fillColor = (int) map(i, 0, numDataPoints, 0, 255);
      visuals[i].display(fillColor);
    }
  }
}