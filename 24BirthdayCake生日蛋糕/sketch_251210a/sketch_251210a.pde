import processing.sound.*;

AudioIn input;
Amplitude analyzer;

boolean candleLit = true; // 蜡烛是否点燃
ArrayList<Smoke> smokeParticles = new ArrayList<Smoke>(); // 烟雾粒子
ArrayList<Confetti> confettiParticles = new ArrayList<Confetti>(); // 彩带粒子

float threshold = 0.15; // 声音阈值，超过这个值就熄灭蜡烛

void setup() {
  size(600, 850);
  
  // 初始化音频输入
  input = new AudioIn(this, 0);
  input.start();
  
  // 创建振幅分析器
  analyzer = new Amplitude(this);
  analyzer.input(input);
}

void draw() {
  background(255); // 白色背景
  
  // 检测声音强度
  float volume = analyzer.analyze();
  
  // 如果声音超过阈值且蜡烛点燃，就熄灭蜡烛
  if (volume > threshold && candleLit) {
    candleLit = false;
    // 创建烟雾粒子
    for (int i = 0; i < 15; i++) {
      smokeParticles.add(new Smoke(width/2, 195));
    }
    // 创建彩带粒子 - 100个
    for (int i = 0; i < 100; i++) {
      confettiParticles.add(new Confetti(random(width), random(-200, 0)));
    }
  }
  
  // 绘制径向渐变圆
  drawRadialGradient(width/2, height/2, 380);
  
  // 绘制盘子
  drawPlate(width/2, 620);
  
  // 绘制圆角矩形
  drawRoundRect(width/2, 480, 340, 330, 30);
  
  // 绘制线性渐变矩形
  drawLinearGradientRect(width/2, 480, 299, 294);
  
  // 绘制上层奶油
  drawCreamLayer(width/2, 410, 299, 94);
  
  // 绘制4个草莓片
  drawStrawberrySlices(width/2, 410);
  
  // 绘制下层奶油
  drawCreamLayer(width/2, 550, 299, 94);
  
  // 绘制随机散落的绿色小矩形
  drawGreenSprinkles(width/2, 550, 299, 94);
  
  // 绘制底部棕色条
  drawBottomBar(width/2, 627, 299, 8);
  
  // 绘制蜡烛
  drawCandle(width/2, 210);
  
  // 如果蜡烛点燃，绘制火焰
  if (candleLit) {
    drawFlame(width/2, 195);
  } else {
    // 如果蜡烛熄灭，绘制烟雾
    drawSmoke();
  }
  
  // 绘制彩带
  drawConfetti();
}

void keyPressed() {
  // 按空格键重新点燃蜡烛
  if (key == ' ') {
    candleLit = true;
    smokeParticles.clear();
    confettiParticles.clear();
  }
}

void drawSmoke() {
  // 更新和绘制烟雾粒子
  for (int i = smokeParticles.size() - 1; i >= 0; i--) {
    Smoke s = smokeParticles.get(i);
    s.update();
    s.display();
    
    // 移除消失的烟雾粒子
    if (s.isDead()) {
      smokeParticles.remove(i);
    }
  }
}

void drawConfetti() {
  // 更新和绘制彩带粒子
  for (int i = confettiParticles.size() - 1; i >= 0; i--) {
    Confetti c = confettiParticles.get(i);
    c.update();
    c.display();
    
    // 移除超出屏幕的彩带粒子
    if (c.isDead()) {
      confettiParticles.remove(i);
    }
  }
}

// 烟雾粒子类
class Smoke {
  float x, y;
  float vx, vy;
  float alpha;
  float size;
  
  Smoke(float x, float y) {
    this.x = x + random(-5, 5);
    this.y = y;
    this.vx = random(-1, 1);
    this.vy = random(-2, -1);
    this.alpha = 150;
    this.size = random(8, 15);
  }
  
  void update() {
    x += vx;
    y += vy;
    alpha -= 2; // 逐渐消失
    size += 0.3; // 逐渐变大
  }
  
  void display() {
    noStroke();
    fill(200, 200, 200, alpha);
    ellipse(x, y, size, size);
  }
  
  boolean isDead() {
    return alpha <= 0;
  }
}

// 彩带粒子类
class Confetti {
  float x, y;
  float vx, vy;
  float rotation;
  float rotationSpeed;
  color c;
  int shapeType; // 0=波浪线, 1=星星, 2=心形, 3=圆形, 4=长方形条
  float size;
  float alpha;
  
  Confetti(float x, float y) {
    this.x = x;
    this.y = y;
    this.vx = random(-2.5, 2.5); // 增加水平范围
    this.vy = random(0.5, 1.5);  // 减慢垂直速度
    this.rotation = random(TWO_PI);
    this.rotationSpeed = random(-0.08, 0.08); // 减慢旋转速度
    this.shapeType = int(random(5));
    this.size = random(10, 20);
    this.alpha = 255;
    
    // 使用指定的5种颜色
    int colorChoice = int(random(5));
    if (colorChoice == 0) {
      this.c = color(167, 216, 196); // #A7D8C4 薄荷绿
    } else if (colorChoice == 1) {
      this.c = color(192, 217, 239); // #C0D9EF 浅蓝
    } else if (colorChoice == 2) {
      this.c = color(255, 199, 214); // #FFC7D6 粉红
    } else if (colorChoice == 3) {
      this.c = color(255, 236, 181); // #FFECB5 浅黄
    } else {
      this.c = color(255, 251, 242); // #FFFBF2 米白
    }
  }
  
  void update() {
    x += vx;
    y += vy;
    rotation += rotationSpeed;
    vy += 0.04; // 减小重力（原来是0.08）
    vx *= 0.995; // 减小空气阻力，让水平移动更持久
  }
  
  void display() {
    pushMatrix();
    translate(x, y);
    rotate(rotation);
    
    if (shapeType == 0) {
      // 波浪线
      stroke(c);
      strokeWeight(3);
      noFill();
      beginShape();
      for (float i = 0; i < size * 2; i += 2) {
        float yPos = sin(i * 0.3 + rotation * 2) * 5;
        vertex(i - size, yPos);
      }
      endShape();
    } else if (shapeType == 1) {
      // 星星
      fill(c);
      noStroke();
      drawStar(0, 0, size * 0.4, size, 5);
    } else if (shapeType == 2) {
      // 心形
      fill(c);
      noStroke();
      drawHeart(0, 0, size * 0.8);
    } else if (shapeType == 3) {
      // 圆形
      fill(c);
      noStroke();
      ellipse(0, 0, size, size);
    } else {
      // 长方形条
      fill(c);
      noStroke();
      rect(-size * 0.3, -size * 0.7, size * 0.6, size * 1.4, 2);
    }
    
    popMatrix();
  }
  
  void drawStar(float x, float y, float radius1, float radius2, int npoints) {
    float angle = TWO_PI / npoints;
    float halfAngle = angle / 2.0;
    beginShape();
    for (float a = -PI/2; a < TWO_PI - PI/2; a += angle) {
      float sx = x + cos(a) * radius2;
      float sy = y + sin(a) * radius2;
      vertex(sx, sy);
      sx = x + cos(a + halfAngle) * radius1;
      sy = y + sin(a + halfAngle) * radius1;
      vertex(sx, sy);
    }
    endShape(CLOSE);
  }
  
  void drawHeart(float x, float y, float size) {
    beginShape();
    for (float t = 0; t < TWO_PI; t += 0.1) {
      float hx = size * 16 * pow(sin(t), 3);
      float hy = -size * (13 * cos(t) - 5 * cos(2*t) - 2 * cos(3*t) - cos(4*t));
      vertex(x + hx * 0.03, y + hy * 0.03);
    }
    endShape(CLOSE);
  }
  
  boolean isDead() {
    return y > height + 50;
  }
}

void drawRadialGradient(float x, float y, float maxRadius) {
  noStroke();
  
  // 从外到内绘制同心圆,创建渐变效果
  for (float r = maxRadius; r > 0; r -= 1) {
    // 计算从中心到边缘的比例 (0在中心,1在边缘)
    float ratio = r / maxRadius;
    
    // 中心颜色 #FF6767 (255, 103, 103)
    // 边缘颜色 #FFFFFF (255, 255, 255)
    float red = lerp(255, 255, ratio);    // R: 255 -> 255
    float green = lerp(103, 255, ratio);  // G: 103 -> 255
    float blue = lerp(103, 255, ratio);   // B: 103 -> 255
    
    fill(red, green, blue);
    ellipse(x, y, r * 2, r * 2);
  }
}

void drawPlate(float x, float y) {
  
  // 盘子外圈（浅灰色描边）
  fill(255);
  noStroke();
  strokeWeight(3);
  ellipse(x, y, 480, 300);
  
  // 盘子内圈
  stroke(235, 235, 235);
  strokeWeight(6);
  ellipse(x, y, 400, 220);
}

void drawRoundRect(float x, float y, float w, float h, float radius) {
  // 颜色 #FCF3E6 (252, 243, 230)
  fill(252, 243, 230);
  noStroke();
  rectMode(CENTER);
  rect(x, y, w, h, radius);
  rectMode(CORNER); // 恢复默认模式
}

void drawLinearGradientRect(float x, float y, float w, float h) {
  noStroke();
  
  // 从上到下绘制线性渐变
  for (float i = 0; i < h; i++) {
    float ratio = i / h;
    
    // 顶部颜色 #FFFABA (255, 250, 186)
    // 底部颜色 #FFFEF2 (255, 254, 242)
    float red = lerp(255, 255, ratio);
    float green = lerp(250, 254, ratio);
    float blue = lerp(186, 242, ratio);
    
    fill(red, green, blue);
    rect(x - w/2, y - h/2 + i, w, 1);
  }
}

void drawCreamLayer(float x, float y, float w, float h) {
  noStroke();
  
  // 从上到下绘制线性渐变
  for (float i = 0; i < h; i++) {
    float ratio = i / h;
    
    // 顶部颜色 #FFFFFF (255, 255, 255)
    // 底部颜色 #FFF6F6 (255, 246, 246)
    float red = lerp(255, 255, ratio);
    float green = lerp(255, 246, ratio);
    float blue = lerp(255, 246, ratio);
    
    fill(red, green, blue);
    rect(x - w/2, y - h/2 + i, w, 1);
  }
}

void drawStrawberrySlices(float centerX, float centerY) {
  float spacing = 72; // 圆之间的间距
  float startX = centerX - 1.5 * spacing; // 起始位置
  
  // 绘制4个草莓片
  for (int i = 0; i < 4; i++) {
    float x = startX + i * spacing;
    drawStrawberrySlice(x, centerY, 66);
  }
}

void drawStrawberrySlice(float x, float y, float diameter) {
  noStroke();
  float maxRadius = diameter / 2;
  
  // 从外到内绘制径向渐变
  for (float r = maxRadius; r > 0; r -= 0.5) {
    float ratio = r / maxRadius;
    
    // 中心80%是纯白，只有外围20%渐变到红
    if (ratio < 0.65) {
      ratio = 0;  // 前80%保持白色
    } else {
      ratio = map(ratio, 0.65, 1, 0, 1);  // 后20%渐变到红色
    }
    
    // 中心颜色 #FEFEF2 (254, 254, 242)
    // 边缘颜色 #E3460A (227, 70, 10)
    float red = lerp(254, 227, ratio);
    float green = lerp(254, 70, ratio);
    float blue = lerp(242, 10, ratio);
    
    fill(red, green, blue);
    ellipse(x, y, r * 2, r * 2);
  }
}

// 存储绿色小矩形的位置和角度
ArrayList<Sprinkle> sprinkles = new ArrayList<Sprinkle>();

class Sprinkle {
  float x, y, angle;
  
  Sprinkle(float x, float y, float angle) {
    this.x = x;
    this.y = y;
    this.angle = angle;
  }
}

void drawGreenSprinkles(float centerX, float centerY, float w, float h) {
  randomSeed(42); // 固定随机种子
  sprinkles.clear(); // 清空之前的记录
  
  int numSprinkles = 20; // 矩形数量
  int maxAttempts = 100; // 每个矩形的最大尝试次数
  
  for (int i = 0; i < numSprinkles; i++) {
    boolean placed = false;
    int attempts = 0;
    
    while (!placed && attempts < maxAttempts) {
      // 随机位置
      float x = centerX - w/2 + random(20, w - 20);
      float y = centerY - h/2 + random(10, h - 10);
      float angle = random(-PI/6, PI/6);
      
      // 检查是否与已有矩形重叠
      boolean overlaps = false;
      for (Sprinkle s : sprinkles) {
        float distance = dist(x, y, s.x, s.y);
        if (distance < 35) { // 最小间距
          overlaps = true;
          break;
        }
      }
      
      if (!overlaps) {
        sprinkles.add(new Sprinkle(x, y, angle));
        drawGreenSprinkle(x, y, 30, 14, angle);
        placed = true;
      }
      
      attempts++;
    }
  }
}

void drawGreenSprinkle(float x, float y, float w, float h, float angle) {
  pushMatrix();
  translate(x, y);
  rotate(angle);
  
  noStroke();
  
  // 从左到右绘制线性渐变
  for (float i = 0; i < w; i++) {
    float ratio = i / w;
    
    // 左边颜色 #F7FFE9 (247, 255, 233)
    // 右边颜色 #E0FFB5 (224, 255, 181)
    float red = lerp(247, 224, ratio);
    float green = lerp(255, 255, ratio);
    float blue = lerp(233, 181, ratio);
    
    fill(red, green, blue);
    rect(-w/2 + i, -h/2, 1, h);
  }
  
  popMatrix();
}

void drawCandle(float x, float y) {
  float candleWidth = 28;
  float candleHeight = 106;
  
  noStroke();
  
  // 蓝色底色 #BCD7F4 (188, 215, 244)
  fill(188, 215, 244);
  rect(x - candleWidth/2, y, candleWidth, candleHeight);
  
  // 黄色条纹 #FFEFCA (255, 239, 202) - 不规则分布
  fill(255, 239, 202);
  float[] stripePositions = {15, 35, 55, 75, 90}; // 条纹的y位置
  
  for (int i = 0; i < stripePositions.length; i++) {
    rect(x - candleWidth/2, y + stripePositions[i], candleWidth, 8);
  }
}

void drawFlame(float x, float y) {
  noStroke();
  
  // 使用时间创建动画效果
  float time = millis() * 0.003; // 控制动画速度
  
  // 火焰摆动偏移量
  float sway = sin(time * 2) * 2;
  
  // 火焰大小变化（闪烁效果）
  float flicker = 1 + sin(time * 4) * 0.1;
  
  // 火焰高度变化
  float heightVar = sin(time * 3) * 2;
  
  pushMatrix();
  translate(x + sway, y);
  scale(flicker * 1.4); // 整体放大1.4倍
  
  // 外层火焰（黄色）
  fill(255, 230, 120, 200);
  beginShape();
  vertex(0, -30 + heightVar);  // 顶点
  bezierVertex(-12, -20, -15, -5, -10, 5);  // 左侧曲线
  bezierVertex(-5, 10, 5, 10, 10, 5);   // 底部曲线
  bezierVertex(15, -5, 12, -20, 0, -30 + heightVar);      // 右侧曲线
  endShape(CLOSE);
  
  // 中层火焰（亮黄色）
  fill(255, 245, 180, 220);
  beginShape();
  vertex(0, -25 + heightVar * 0.8);
  bezierVertex(-8, -18, -10, -5, -6, 3);
  bezierVertex(-3, 6, 3, 6, 6, 3);
  bezierVertex(10, -5, 8, -18, 0, -25 + heightVar * 0.8);
  endShape(CLOSE);
  
  // 内层火焰（白色高光）
  fill(255, 255, 220, 180);
  ellipse(0, -15 + heightVar * 0.5, 8, 12);
  
  popMatrix();
}

void drawBottomBar(float x, float y, float w, float h) {
  // 颜色 #AC5D14 (172, 93, 20)
  fill(172, 93, 20);
  noStroke();
  rectMode(CENTER);
  rect(x, y, w, h);
  rectMode(CORNER); // 恢复默认模式
}
