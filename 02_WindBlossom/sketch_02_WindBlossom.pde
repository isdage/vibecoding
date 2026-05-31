import processing.sound.*;

// 《风绘花境》 Processing v0.3.0 - 加入声音控制

int flowerCount = 5;
ArrayList<Flower> flowers;
PImage bgImage;

AudioIn mic;
Amplitude amp;
float vol = 0;
ArrayList<Particle> particles = new ArrayList<Particle>();

void setup() {
  size(800, 600);
  smooth();
  colorMode(HSB, 360, 100, 100, 100);

  // 加载背景图像（需将图像放入项目目录或通过 Sketch > Add File... 添加）
  bgImage = loadImage("background.jpg"); // 文件名可替换为用户上传图像名
  bgImage.resize(width, height);

  // 初始化声音监听
  mic = new AudioIn(this, 0);
  mic.start();
  amp = new Amplitude(this);
  amp.input(mic);

  flowers = new ArrayList<Flower>();
  for (int i = 0; i < flowerCount; i++) {
    float x = random(width);
    float y = random(height);
    x += random(-100, 100);
    y += random(-100, 100);
    flowers.add(new Flower(x, y));
  }
}

ArrayList<PVector> trail = new ArrayList<PVector>();

void draw() {
  // 音量控制花朵逐渐消失
  if (vol > 0.08 && flowers.size() > 5) {
    int toRemove = int(map(vol, 0.05, 0.2, 0, 2));
    toRemove = min(toRemove, flowers.size() - 5); // 至少保留5朵
    for (int i = 0; i < toRemove; i++) {
      int index = int(random(flowers.size()));
      particles.add(new Particle(flowers.get(index).x, flowers.get(index).y));
      flowers.remove(index);
    }
  }
  vol = amp.analyze(); // 获取当前音量
  image(bgImage, 0, 0);

  // 添加白色鼠标拖尾效果（圆点）
  trail.add(new PVector(mouseX, mouseY));
  if (trail.size() > 40) trail.remove(0);

  noStroke();
  for (int i = 0; i < trail.size(); i++) {
    float alpha = map(i, 0, trail.size(), 0, 50);
    float size = map(i, 0, trail.size(), 12, 4);
    fill(0, 0, 100, alpha);
    ellipse(trail.get(i).x, trail.get(i).y, size, size);
  }

  for (Flower f : flowers) {
    f.update();
    f.display();
  }

  // 更新飘落花瓣
  for (int i = particles.size() - 1; i >= 0; i--) {
    Particle p = particles.get(i);
    p.update();
    p.display();
    if (p.isOffScreen()) particles.remove(i);
  }

  // 根据音量产生飘落花瓣
  if (vol > 0.06) {
    for (int i = 0; i < int(vol * 21.6); i++) {
      particles.add(new Particle(random(width), random(height * 1.33)));
    }
  }

}

void mousePressed() {
  flowers.add(new Flower(mouseX, mouseY));
}

void keyPressed() {
  if (key == 's' || key == 'S') {
    saveFrame("wind_blossom_####.png");
  }
  if (key == ' ') {
    flowers.clear();
    for (int i = 0; i < 5; i++) {
      float x = random(width);
      float y = random(height);
      x += random(-100, 100);
      y += random(-100, 100);
      flowers.add(new Flower(x, y));
    }
  }
}

class Flower {
  float shakeOffset = 0;
  float shrinkMin;
  float x, y;
  float baseSize;
  int petalLayers;
  float bloomAmount = 0;
  color innerColor, outerColor;

  Flower(float x, float y) {
    this.x = x;
    this.y = y;
    baseSize = random(40, 55); // 更宽范围随机大小
    petalLayers = int(random(4, 6));
    innerColor = color(random(330, 360), 30, 100, 40);
    outerColor = color(random(330, 360), 20, 100, 6);
    shrinkMin = random(0.3, 0.5);
  }

  void update() {
    float d = dist(mouseX, mouseY, x, y);
    float target = (d < 90) ? 1.0 : 0.0;
    float soundInfluence = map(vol, 0, 0.2, 0.0, 0.3);
    target += soundInfluence;
    bloomAmount = lerp(bloomAmount, target, 0.08);
  }

  void display() {
    pushMatrix();
    float windShake = sin(frameCount * 0.1 + x + y) * vol * 20;
    translate(x + windShake, y);
    noFill();

    for (int i = 0; i < petalLayers; i++) {
      float angle = i * TWO_PI / petalLayers + bloomAmount * 0.2;
      float sizeFactor = 1.0 + sin(frameCount * 0.02 + i + vol * 50) * 0.12;
      pushMatrix();
      rotate(angle);
      for (int j = 0; j < 3; j++) {
        float blur = map(j, 0, 2, 1.0, 1.6);
        float alpha = map(j, 0, 2, 50, 4);
        fill(lerpColor(innerColor, outerColor, j / 2.0), alpha);
        stroke(0, 0, 100, alpha * 0.4);
        strokeWeight(1);
        float shrinkFactor = map(bloomAmount, 0, 1, shrinkMin, 1.0);
ellipse(baseSize * 0.65 * shrinkFactor * blur, 0, baseSize * 1.3 * shrinkFactor * blur, baseSize * 0.975 * shrinkFactor * blur);
      }
      popMatrix();
    }

    if (bloomAmount > 0.1) {
      noStroke();
      fill(50, 80, 100, 40);
      ellipse(0, 0, 4 + bloomAmount * 2, 4 + bloomAmount * 2);
    }

    popMatrix();
  }

}

// 飘落花瓣类
class Particle {
  float x, y;
  float speedX, speedY;
  float angle;
  float size;
  color col;

  Particle(float x, float y) {
    this.x = x;
    this.y = y;
    speedX = random(-0.5, 0.5);
    speedY = random(1, 2.5);
    angle = random(TWO_PI);
    size = random(12.1, 24.2);
    col = color(330, 30, 100, 60);
  }

  void update() {
    x += speedX;
    y += speedY;
    angle += map(y, 0, height, 0.03, 0.005);
  }

  void display() {
    pushMatrix();
    translate(x, y);
    rotate(angle);
    noStroke();
    float fade = map(y, 0, height, 1.0, 0.0);
    fill(hue(col), saturation(col), brightness(col), alpha(col) * fade);
    ellipse(0, 0, size, size * 0.6);
    popMatrix();
  }

  boolean isOffScreen() {
    return y > height;
  }
}
