// Fragment Sea v0.3 — 更细字体 & 浅灰色 & 更大吸附/炸开范围
ArrayList<Letter> letters = new ArrayList<Letter>();
PFont font;
String charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
int letterCount = 100;

void setup() {
  size(800, 600);
  background(255);
  // 细体字体（需要本地安装 Helvetica Neue Light 或类似细体）
  font = createFont("Helvetica-Light", 32, true);
  textFont(font);
  textAlign(CENTER, CENTER);

  // 生成随机漂浮文字
  for (int i = 0; i < letterCount; i++) {
    char c = charset.charAt(int(random(charset.length())));
    float x = random(width);
    float y = random(height);
    float s = random(16, 40); // 字号随机
    letters.add(new Letter(c, x, y, s));
  }
}

void draw() {
  background(255);
  // 更新并绘制
  for (Letter l : letters) {
    l.update();
    l.display();
  }
}

// 点击触发更大范围的爆炸
void mousePressed() {
  for (Letter l : letters) {
    float d = dist(mouseX, mouseY, l.x, l.y);
    if (d < 120) {
      float angle = atan2(l.y - mouseY, l.x - mouseX);
      float force = map(d, 0, 120, 10, 0);  // 力度加强
      l.vx += cos(angle) * force;
      l.vy += sin(angle) * force;
    }
  }
}

class Letter {
  char c;
  float x, y;
  float targetX, targetY;
  float vx = 0, vy = 0;
  float size;

  Letter(char c, float x, float y, float size) {
    this.c = c;
    this.x = x;
    this.y = y;
    this.targetX = x;
    this.targetY = y;
    this.size = size;
  }

  void update() {
    // 更大范围吸附：150
    float d = dist(mouseX, mouseY, x, y);
    if (d < 150) {
      float angle = atan2(mouseY - y, mouseX - x);
      float pull = map(d, 0, 150, 1.2, 0);  // 拉力也稍强
      vx += cos(angle) * pull;
      vy += sin(angle) * pull;
    }
    // 回弹至原位
    float dx = targetX - x;
    float dy = targetY - y;
    vx += dx * 0.01;
    vy += dy * 0.01;
    // 摩擦
    vx *= 0.90;
    vy *= 0.90;
    // 应用速度
    x += vx;
    y += vy;
  }

  void display() {
    textSize(size);
    fill(180);  // 浅灰色
    text(c, x, y);
  }
}
