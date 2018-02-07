final String DATA_FILE = "data.csv";
final float MARGIN = 0.15;
final color MAIN_COLOR = #50C9CE;
final color HIGHLIGHT_COLOR = #7FD7DB;
final color BUTTON_COLOR = #FFB4D0;
final color BUTTON_HIGHLIGHT = #FFBFD7;
final float LINE_WEIGHT = 0.002 * width;
final color WHITE = #FFFFFF;
final color BLACK = #000000;
final float TRANSITION_SPEED = 0.08;

Table data;
int numDataPoints;
Graph graph;
float left, right, top, bottom; // Border of graph area
boolean buttonOver = false;

boolean transitionOut = false;
boolean transitionIn = false;
boolean[] transitionDone;
float lerpDiam = 0;
color transitionColor = WHITE;

void setup() {
  data = new Table(DATA_FILE);
  graph = new BarGraph(data);
  transitionDone = new boolean[numDataPoints];
  size(800, 800);
  //surface.setResizable(true);
  rectMode(CENTER);
}

void draw() {
  textSize(height * 0.02);

  // White background
  background(WHITE);

  graph.display();
  // Check if mouse is hovering over a data point
  for (Visual v : graph.visuals) {
    v.updateMouseOver();
  }

  drawButton();
}

void drawButton() {
  float buttonX = (1 - MARGIN/2) * width;
  float buttonY = top;
  float buttonWidth = width * MARGIN * 0.85;
  float buttonHeight = height * MARGIN/2;

  buttonOver = overButton(buttonX, buttonY, buttonWidth, buttonHeight);

  if (buttonOver) {
    fill(BUTTON_HIGHLIGHT);
    stroke(BUTTON_HIGHLIGHT);
  } else {
    fill(BUTTON_COLOR);
    stroke(BUTTON_COLOR);
  }

  rect(buttonX, buttonY, buttonWidth, buttonHeight);

  String buttonText = "Switch to Line";
  if (graph instanceof LineGraph) {
    buttonText = "Switch to Bar";
  } else if (graph instanceof PieChart) {
    buttonText = "Switch to Bar";
  }

  // calculate minimum size to fit width
  float minSizeW = 12/textWidth(buttonText) * buttonWidth;
  // calculate minimum size to fit height
  float minSizeH = 12/(textDescent() + textAscent()) *buttonWidth;

  textSize(min(minSizeW, minSizeH));
  fill(BLACK);
  textAlign(CENTER, CENTER);
  text(buttonText, buttonX, buttonY);
}

boolean overButton(float x, float y, float width, float height) {
  return mouseX >= x-width/2 && mouseX <= x + width/2 &&
    mouseY >= y-height/2 && mouseY <= y + height/2;
}

void mousePressed() {
  if (buttonOver) {
    transitionOut = true;
  }
}

void drawRotatedText(String s, float x, float y, float deg) {
  fill(BLACK);
  translate(x, y);
  rotate(-deg);
  text(s, 0, 0);
  rotate(deg);
  translate(-x, -y);
}

class Table {
  String xLabel;
  String yLabel;
  DataPoint[] dataPoints;
  float maxValue;
  float total;

  Table(String path) {
    String[] lines = loadStrings(path);

    // Headers
    String[] headers = split(lines[0], ",");
    xLabel = headers[0];
    yLabel = headers[1];

    // Actual data
    dataPoints = new DataPoint[lines.length - 1];
    for (int i = 1; i < lines.length; ++i) {
      String[] row = split(lines[i], ",");
      dataPoints[i - 1] = new DataPoint(row[0], parseFloat(row[1]));
    }

    // Find max,  value and total
    maxValue = dataPoints[0].value;
    total = dataPoints[0].value;
    for (int i = 1; i < dataPoints.length; ++i) {
      if (dataPoints[i].value > maxValue) {
        maxValue = dataPoints[i].value;
      }
      total += dataPoints[i].value;
    }

    numDataPoints = dataPoints.length;
  }
}

class DataPoint {
  String name;
  float value;

  DataPoint(String name, float value) {
    this.name = name;
    this.value = value;
  }
}
