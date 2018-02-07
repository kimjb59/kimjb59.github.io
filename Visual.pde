abstract class Visual {
  float x, y;
  DataPoint dataPoint;
  boolean mouseOver;
  float transitionX, transitionY;
  color transitionColor;

  Visual(DataPoint d, color transitionColor) {
    dataPoint = d;
    mouseOver = false;
    this.transitionColor = transitionColor;
  }

  Visual(DataPoint d) {
    dataPoint = d;
    mouseOver = false;
  }

  abstract void updateInfo(int i);
  abstract void display(color fillColor);
  abstract void updateMouseOver();
}

class Bar extends Visual {
  float barWidth, barHeight;

  Bar(DataPoint d) {
    super(d, WHITE);
    float maxBarHeight = (1 - 2*MARGIN) * height;
    float barTop = (dataPoint.value / data.maxValue) * maxBarHeight;
    y = bottom - barTop;
  }

  void updateInfo(int i) {
    // barWidth/2 amount of space between 2 bars
    // = 1.5 * barWidth amount of space per bar
    // So (1.5 * barWidth) * numDataPoints = length of x-axis = (1 - 2*MARGIN) * canvas width
    float fullBarWidth = (1 - 2*MARGIN) * width / (numDataPoints * 1.5);
    if (transitionOut || transitionIn) {
      float targetBarWidth = transitionOut ? 0 : fullBarWidth;
      barWidth = lerp(barWidth, targetBarWidth, TRANSITION_SPEED);
    } else {
      barWidth = fullBarWidth;
    }

    // Data point with the highest value will be same size as the y-axis
    // = (1 - 2*MARGIN) * canvas height
    // So heights of other data points is proportional to the max height:
    // (value / maxValue) * maxBarHeight
    float maxBarHeight = (1 - 2*MARGIN) * height;
    float barTop = (dataPoint.value / data.maxValue) * maxBarHeight;
    if (transitionOut || transitionIn) {
      float targetBarHeight = transitionOut ? 0 : barTop;
      barHeight = lerp(barHeight, targetBarHeight, TRANSITION_SPEED);
    } else {
      barHeight = barTop;
    }

    // barWidth/2 is empty space, so space + bar is 1.5 * barWidth, so center of
    // bar is that minus half a bar
    x = left + 1.5 * fullBarWidth * (i + 1) - 0.5 * fullBarWidth;
    // y is y value of x-axis - barHeight/2
    if (transitionOut || transitionIn) {
      float targetY = transitionOut ? bottom - barTop : bottom - barHeight/2;
      y = lerp(y, targetY, TRANSITION_SPEED);
    } else {
      y = bottom - barHeight / 2;
    }

    transitionX = x;
    transitionY = barTop;

    if (transitionOut && barWidth <= 0.01 * width && barHeight <= 0.01 * width) {
      transitionDone[i] = true;
    } else if (transitionIn && fullBarWidth - barWidth <= 1 && barTop - barHeight <= 1) {
      transitionDone[i] = true;
    }
  }
  void display(color fillColor) {
    fill(fillColor);
    stroke(fillColor);

    rect(x, y, barWidth, barHeight);

    // Display info on data point if bar is being hovered over
    if (mouseOver) {
      textAlign(CENTER);
      fill(BLACK);

      String info = "(" + dataPoint.name + ", " + dataPoint.value + ")";
      // Display text in the top MARGIN
      float infoX = width / 2;
      float infoY = top / 2;
      text(info, infoX, infoY);
    }

    // Category name at the bottom
    drawRotatedText(dataPoint.name, x, (1-0.75*MARGIN) * height, PI/4);
  }

  void updateMouseOver() {
    mouseOver = mouseX >= this.x - this.barWidth/2 &&
      mouseX <= this.x + this.barWidth/2 && 
      mouseY >= this.y - this.barHeight/2 &&
      mouseY <= bottom;
  }
}

class Point extends Visual {
  float diameter;
  float barWidth, maxHeight, pointHeight;
  float transitionY;
  float transitionWidth = 0;
  float transitionHeight = 0;

  Point(DataPoint d) {
    super(d, WHITE);
  }

  void updateInfo(int i) {
    if (transitionOut || transitionIn) {
      float targetDiameter = transitionOut ? 0 : 0.01 * width;
      diameter = lerp(diameter, targetDiameter, TRANSITION_SPEED);
    } else {
      diameter = 0.01 * width;
    }

    barWidth = (1 - 2*MARGIN) * width / (numDataPoints * 1.5);
    x = left + 1.5 * barWidth * (i + 1) - 0.5 * barWidth;

    maxHeight = (1 - 2*MARGIN) * height;
    pointHeight = (dataPoint.value / data.maxValue) * maxHeight;
    y = bottom - pointHeight;

    if (transitionOut && diameter <= 1) {
      transitionDone[i] = true;
    }
  }

  void display(color fillColor) {
    fill(fillColor);
    stroke(fillColor);

    ellipse(x, y, diameter, diameter);

    // Display info on data point if point is being hovered over
    if (mouseOver) {
      textAlign(CENTER);
      fill(0);

      String info = "(" + dataPoint.name + ", " + dataPoint.value + ")";
      // Display text in the top MARGIN
      float infoX = width / 2;
      float infoY = top / 2;
      text(info, infoX, infoY);
    }

    //if (transition) {
    //  transitionWidth = lerp(transitionWidth, barWidth, TRANSITION_SPEED);
    //  transitionHeight = lerp(transitionHeight, pointHeight, TRANSITION_SPEED);
    //  transitionY = lerp(transitionY, bottom - pointHeight/2, TRANSITION_SPEED);
    //  rect(x, transitionY, transitionWidth, transitionHeight);
    //}
    
    // Category name at the bottom
    drawRotatedText(dataPoint.name, x, (1-0.75*MARGIN) * height, PI/4);
  }

  void updateMouseOver() {
    float radius = diameter / 2;
    mouseOver = dist(mouseX, mouseY, x, y) <= radius;
  }
}

class PieSlice extends Visual {
  float fromAngle, toAngle;
  float diameter;

  PieSlice(DataPoint d, float total, float fromAngle) {
    super(d);
    float angle = radians(d.value / total * 360);
    this.fromAngle = fromAngle;
    this.toAngle = fromAngle + angle;
  }

  void updateInfo(int i) {
    x = width / 2;
    y = height / 2;
    diameter = min(width * (1 - 2*MARGIN), height * (1 - 2*MARGIN));
  }

  void display(color fillColor) {
    fill(fillColor);
    stroke(WHITE);
    arc(x, y, diameter, diameter, fromAngle, toAngle, PIE);
  }

  void updateMouseOver() {
    // Calculate angle that vector from center to (mouseX, mouseY) forms w.r.t 0 degrees
    // If that angle is between fromAngle and toAngle, then mouse overlaps this PieSlice
    // And distance from mouse to center is <= radius
    float r = diameter / 2;
    float angleX = acos(mouseX / r);
    float angleY = asin(mouseY / r);
    mouseOver = angleX > fromAngle && angleX < toAngle &&
      angleY > fromAngle && angleY < toAngle &&
      dist(mouseX, mouseY, x, y) <= r;
  }
}