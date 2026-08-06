// Floating Text Field v0.6 - 支持动态重排，键盘左右键调节影响范围，黑底白字，等宽字体，带光标

ArrayList<CharCell> chars = new ArrayList<CharCell>();
int cellSize = 20;
int maxCols;
int fontSize = 16;
float influenceRadius = 100.0;
PFont font;

void settings() {
  size(800, 600);
}

void setup() {
  surface.setResizable(true);
  background(0);
  font = createFont("Courier", fontSize);
  textFont(font);
  textAlign(CENTER, CENTER);
  updateCols();
}

void draw() {
  // 动态更新列数
  if (width / cellSize != maxCols) {
    updateCols();
  }
  background(0);
  // 绘制字符
  for (int i = 0; i < chars.size(); i++) {
    CharCell c = chars.get(i);
    c.index = i;
    c.update();
    c.display();
  }
  // 绘制光标
  int nextIndex = chars.size();
  int col = nextIndex % maxCols;
  int row = nextIndex / maxCols;
  float cx = col * cellSize + cellSize/2;
  float cy = row * cellSize + cellSize/2;
  // 光标闪烁
  if ((frameCount / 30) % 2 == 0) {
    noStroke();
    fill(255);
    rectMode(CENTER);
    rect(cx, cy, 2, fontSize);
  }
}

void updateCols() {
  maxCols = width / cellSize;
}

void keyPressed() {
  // 键盘左右键调节鼠标影响范围
  if (keyCode == LEFT) {
    influenceRadius += 20;
  } else if (keyCode == RIGHT) {
    influenceRadius = max(20, influenceRadius - 20);
  }
  // 字号调节
  else if (keyCode == UP) {
    fontSize += 2;
    font = createFont("Courier", fontSize);
    textFont(font);
  } else if (keyCode == DOWN) {
    fontSize = max(8, fontSize - 2);
    font = createFont("Courier", fontSize);
    textFont(font);
  }
  // 删除与换行
  else if (key == BACKSPACE && chars.size() > 0) {
    chars.remove(chars.size() - 1);
  } else if (key == ENTER || key == RETURN) {
    // 填充空格到行尾，实现换行
    int remainder = maxCols - (chars.size() % maxCols);
    for (int i = 0; i < remainder; i++) {
      chars.add(new CharCell(' '));
    }
  }
  // 普通字符输入
  else if (key != CODED) {
    chars.add(new CharCell(key));
  }
}

class CharCell {
  char ch;
  int index;
  float x, y, opacity;

  CharCell(char ch) {
    this.ch = ch;
    this.index = chars.size();
    this.opacity = 255;
  }

  void update() {
    int col = index % maxCols;
    int row = index / maxCols;
    float baseX = col * cellSize + cellSize / 2;
    float baseY = row * cellSize + cellSize / 2;
    float d = dist(mouseX, mouseY, baseX, baseY);
    float influence = constrain(1 - d / influenceRadius, 0, 1);
    x = baseX + influence * 10 * sin(frameCount * 0.05 + baseX);
    y = baseY + influence * 10 * cos(frameCount * 0.05 + baseY);
    opacity = lerp(opacity, 255 - influence * 180, 0.1);
  }

  void display() {
    fill(255, opacity);
    text(ch, x, y);
  }
}
