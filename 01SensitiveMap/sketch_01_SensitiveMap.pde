import processing.sound.*;

int cols, rows;
int spacing = 40;
Circle[][] grid;

AudioIn mic;
Amplitude amp;
float vol = 0;

void setup() {
  size(800, 800);
  cols = width / spacing;
  rows = height / spacing;

  grid = new Circle[cols][rows];

  for (int i = 0; i < cols; i++) {
    for (int j = 0; j < rows; j++) {
      grid[i][j] = new Circle(i * spacing + spacing / 2, j * spacing + spacing / 2);
    }
  }

  mic = new AudioIn(this, 0);
  mic.start();
  amp = new Amplitude(this);
  amp.input(mic);
}

void draw() {
  background(15);
  vol = amp.analyze();

  for (int i = 0; i < cols; i++) {
    for (int j = 0; j < rows; j++) {
      grid[i][j].update(vol);
      grid[i][j].display();
    }
  }
}

// Screen shot
void keyPressed() {
  if (key == 's' || key == 'S') {
    saveHighResImage(2);  // 2x 分辨率
  }
}

//
void saveHighResImage(int scaleFactor) {
  int w = width * scaleFactor;
  int h = height * scaleFactor;
  PGraphics highRes = createGraphics(w, h);

  highRes.beginDraw();
  highRes.background(15);

  for (int i = 0; i < cols; i++) {
    for (int j = 0; j < rows; j++) {
      grid[i][j].drawToGraphics(highRes, scaleFactor);
    }
  }

  highRes.endDraw();

  String filename = "breathing_wall_HQ_" + nf(frameCount, 4) + ".png";
  highRes.save(filename);
  println("已保存高清图像：" + filename);
}

// circle Properties
class Circle {
  float x, y;
  float baseSize = 10;
  float breathing = 0;
  float speed = 0.02;

  Circle(float x, float y) {
    this.x = x;
    this.y = y;
  }

  void update(float soundVolume) {
    float d = dist(mouseX, mouseY, x, y);
    float influence = constrain(1 - d / 200.0, 0, 1);
    float soundInfluence = map(soundVolume, 0, 0.2, 0.01, 0.2);
    speed = 0.02 + influence * 0.05 + soundInfluence;
    breathing += speed;
  }

  void display() {
    float size = baseSize + sin(breathing) * 10 + map(vol, 0, 0.3, 0, 10);
    float d = dist(mouseX, mouseY, x, y);
    float c = map(d, 0, 200, 255, 50);
    fill(c, 150, 200);
    noStroke();
    ellipse(x, y, size, size);
  }

  // 
  void drawToGraphics(PGraphics pg, float scale) {
    float size = (baseSize + sin(breathing) * 10 + map(vol, 0, 0.3, 0, 10)) * scale;
    float d = dist(mouseX, mouseY, x, y);
    float c = map(d, 0, 200, 255, 50);

    pg.noStroke();
    pg.fill(c, 150, 200);
    pg.ellipse(x * scale, y * scale, size, size);
  }
}
