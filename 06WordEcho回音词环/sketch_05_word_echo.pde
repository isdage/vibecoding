// Word Echo v0.3 – 可响应窗口大小 + 圆形排列文字 + 声音驱动回音扩散
import processing.sound.*;

ArrayList<Echo> echoes = new ArrayList<Echo>();
PFont font;
AudioIn mic;
Amplitude amp;
float vol = 0;

String currentText = "";
boolean freeze = false;

void settings() {
  size(800, 600);
}

void setup() {
  // 允许窗口可调整大小
  surface.setResizable(true);

  // 在此处替换字体名称："Courier" 可以改成你想要的字体名（需系统已安装或放在 data/ 目录下）
  font = createFont("Courier", 32);
  textFont(font);
  textAlign(CENTER, CENTER);

  mic = new AudioIn(this, 0);
  mic.start();
  amp = new Amplitude(this);
  amp.input(mic);
}

void draw() {
  if (!freeze) {
    background(0);
  }

  vol = amp.analyze();

  // 每帧重新计算中心点（宽度/2，高度/2），确保响应式布局
  float cx = width / 2.0;
  float cy = height / 2.0;

  // 绘制中央圆形文字阵列
  if (currentText.length() > 0) {
    drawCircularText(currentText, cx, cy, 80, 32, 255);
  }

  // 根据声音产生回音
  int echoCount = int(map(vol, 0, 0.2, 0, 4));
  for (int i = 0; i < echoCount; i++) {
    if (currentText.length() > 0) {
      echoes.add(new Echo(currentText, cx, cy));
    }
  }

  // 更新并显示所有回音
  for (int i = echoes.size() - 1; i >= 0; i--) {
    Echo e = echoes.get(i);
    e.update();
    e.display();
    if (e.isDead()) {
      echoes.remove(i);
    }
  }
}

void keyPressed() {
  if (key == BACKSPACE && currentText.length() > 0) {
    currentText = currentText.substring(0, currentText.length() - 1);
  } else if (key == ENTER || key == RETURN) {
    currentText = "";
  } else if (key != CODED) {
    currentText += key;
  }
}

void mousePressed() {
  freeze = !freeze;
}

// 在 (cx, cy) 位置以半径 r 绘制圆形排列的字符串 str
// textSize 为字号，alpha 为文字透明度
void drawCircularText(String str, float cx, float cy, float r, float txtSize, float alpha) {
  int n = str.length();
  textSize(txtSize);
  fill(255, alpha);
  for (int i = 0; i < n; i++) {
    float ang = TWO_PI * i / n - HALF_PI; // 从画面顶部开始
    float x = cx + cos(ang) * r;
    float y = cy + sin(ang) * r;
    pushMatrix();
    translate(x, y);
    rotate(ang + HALF_PI); // 让文字始终朝外
    text(str.charAt(i), 0, 0);
    popMatrix();
  }
}

class Echo {
  String txt;
  float cx, cy;
  float radius;
  float maxRadius;
  float alpha;
  float speed;

  Echo(String txt, float cx, float cy) {
    this.txt = txt;
    this.cx = cx;
    this.cy = cy;
    this.radius = 80;         
    this.maxRadius = max(width, height) * 0.8; // 随窗口大小自适应最大扩散范围
    this.alpha = 200;
    this.speed = random(1.5, 3.0);
  }

  void update() {
    radius += speed;
    alpha -= 1.2;
  }

  void display() {
    if (radius < maxRadius) {
      drawCircularText(txt, cx, cy, radius, 32, alpha);
    }
  }

  boolean isDead() {
    return alpha <= 0 || radius >= maxRadius;
  }
}
