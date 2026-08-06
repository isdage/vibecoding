import processing.sound.*;

ArrayList<Snowflake> snowflakes;
ArrayList<Sparkle> sparkles;  // 闪光效果
float centerX, centerY, ballRadius;
boolean isBlowing = false;
int blowTime = 0;

// 声音相关
AudioIn input;
Amplitude analyzer;
float currentVolume = 0;
float blowThreshold = 0.2;  // 提高吹气阈值,降低灵敏度(从0.1改为0.2)

void setup() {
  size(600, 800);
  smooth(8);  // 抗锯齿,让动画更流畅
  centerX = width / 2;
  centerY = height / 2 - 20;
  ballRadius = 200;
  
  // 初始化麦克风
  input = new AudioIn(this, 0);
  input.start();
  
  // 初始化音量分析器
  analyzer = new Amplitude(this);
  analyzer.input(input);
  
  // 创建更多雪花
  snowflakes = new ArrayList<Snowflake>();
  for (int i = 0; i < 100; i++) {
    snowflakes.add(new Snowflake(centerX, centerY, ballRadius));
  }
  
  // 创建闪光 - 在整个画面
  sparkles = new ArrayList<Sparkle>();
  for (int i = 0; i < 50; i++) {
    sparkles.add(new Sparkle());
  }
}

void draw() {
  // 径向渐变背景 - 中心白色到边缘浅蓝色
  drawRadialGradientBackground();
  
  // 绘制整个画面的星光
  for (Sparkle sp : sparkles) {
    sp.update();
    sp.display();
  }
  
  // 绘制水晶球 - 径向渐变
  drawCrystalBall(centerX, centerY, ballRadius);
  
  // 绘制雪地 - 在水晶球里面 (最后面)
  drawSnowGround(centerX, centerY, ballRadius);
  
  // 绘制雪人 (在雪地前面,雪花后面)
  drawSnowman(centerX, centerY + 47);
  
  // 检测声音音量
  currentVolume = analyzer.analyze();
  
  // 如果音量超过阈值,触发吹动效果
  if (currentVolume > blowThreshold) {
    isBlowing = true;
    blowTime = 0;
  }
  
  // 更新和绘制雪花 (在最前面)
  for (Snowflake sf : snowflakes) {
    sf.update(isBlowing, currentVolume);
    sf.display();
  }
  
  // 绘制底座 - 提高2单位
  drawBase(centerX, centerY + ballRadius - 12);
  
  // 吹动效果逐渐减弱
  if (isBlowing) {
    blowTime++;
    if (blowTime > 30) {
      isBlowing = false;
      blowTime = 0;
    }
  }
}

class Sparkle {
  float x, y;
  float brightness;
  float fadeSpeed;
  boolean fadingIn;
  float maxBrightness;
  float size;  // 星星大小
  
  Sparkle() {
    reset();
  }
  
  void reset() {
    // 在整个画面随机位置
    x = random(width);
    y = random(height);
    
    brightness = 0;
    fadeSpeed = random(2, 7);
    fadingIn = true;
    maxBrightness = random(120, 200);
    size = random(3, 8);
  }
  
  void update() {
    if (fadingIn) {
      brightness += fadeSpeed;
      if (brightness >= maxBrightness) {
        brightness = maxBrightness;
        fadingIn = false;
      }
    } else {
      brightness -= fadeSpeed;
      if (brightness <= 0) {
        brightness = 0;
        fadingIn = true;
        // 随机改变最大亮度和速度
        maxBrightness = random(120, 200);
        fadeSpeed = random(2, 7);
      }
    }
  }
  
  void display() {
    // 绘制四角星光效果 - 不旋转
    pushMatrix();
    translate(x, y);
    
    noStroke();
    fill(255, 255, 220, brightness);
    
    // 绘制四角星形状
    beginShape();
    // 上尖
    vertex(0, -size);
    vertex(size * 0.15, -size * 0.25);
    // 右尖
    vertex(size, 0);
    vertex(size * 0.25, size * 0.15);
    // 下尖
    vertex(0, size);
    vertex(-size * 0.15, size * 0.25);
    // 左尖
    vertex(-size, 0);
    vertex(-size * 0.25, -size * 0.15);
    endShape(CLOSE);
    
    popMatrix();
  }
}

class Snowflake {
  float x, y;
  float vx, vy;
  float size;
  float alpha;
  float centerX, centerY, radius;
  float targetVx, targetVy;  // 目标速度,用于平滑过渡
  
  Snowflake(float cx, float cy, float r) {
    centerX = cx;
    centerY = cy;
    radius = r;
    reset();
  }
  
  void reset() {
    // 在球内随机位置
    float angle = random(TWO_PI);
    float dist = random(radius * 0.8);
    x = centerX + cos(angle) * dist;
    y = centerY + sin(angle) * dist;
    
    vx = random(-0.4, 0.4);  // 减少初始速度
    vy = random(0.6, 1.2);   // 减少初始速度
    targetVx = vx;
    targetVy = vy;
    size = random(4, 8);
    alpha = random(180, 255);
  }
  
  void update(boolean blowing, float volume) {
    if (blowing) {
      // 根据音量大小调整吹动强度
      float blowStrength = map(volume, blowThreshold, 0.5, 1.5, 3.5);  // 减少吹动强度
      blowStrength = constrain(blowStrength, 1.5, 3.5);
      
      // 设置目标速度 - 减少变化幅度
      targetVx += random(-0.5, 0.5) * blowStrength;
      targetVy += random(-0.8, 0.3) * blowStrength;
      
      // 限制目标速度 - 降低速度上限
      targetVx = constrain(targetVx, -4, 4);
      targetVy = constrain(targetVy, -4, 3);
    } else {
      // 正常缓慢下落
      targetVy += 0.04;  // 稍微减少重力
      targetVx *= 0.96;
      targetVy = constrain(targetVy, -2, 2.5);
      targetVx = constrain(targetVx, -1, 1);
    }
    
    // 平滑过渡到目标速度
    vx = lerp(vx, targetVx, 0.2);
    vy = lerp(vy, targetVy, 0.2);
    
    // 更新位置
    x += vx;
    y += vy;
    
    // 检查是否在球内
    float distFromCenter = dist(x, y, centerX, centerY);
    if (distFromCenter > radius * 0.9) {
      // 限制在球内
      float angle = atan2(y - centerY, x - centerX);
      x = centerX + cos(angle) * radius * 0.9;
      y = centerY + sin(angle) * radius * 0.9;
      
      // 柔和反弹
      vx *= -0.5;
      vy *= -0.5;
      targetVx *= -0.5;
      targetVy *= -0.5;
    }
    
    // 如果落到雪地上
    if (y > centerY + radius * 0.5) {
      if (!blowing) {
        // 不吹气时重置到顶部
        x = centerX + random(-radius * 0.6, radius * 0.6);
        y = centerY - radius * 0.8;
        vy = random(0.6, 1.2);
        vx = random(-0.4, 0.4);
        targetVy = vy;
        targetVx = vx;
      } else {
        // 吹气时在雪地上反弹
        y = centerY + radius * 0.5;
        vy *= -0.5;
        targetVy *= -0.5;
      }
    }
  }
  
  void display() {
    noStroke();
    fill(255, alpha);
    circle(x, y, size);
  }
}

void drawRadialGradientBackground() {
  float maxDist = dist(0, 0, width, height);
  
  for (float r = maxDist; r > 0; r -= 2) {
    float inter = map(r, 0, maxDist, 0, 1);
    int c = lerpColor(color(0xDD, 0xF6, 0xFF), color(0xFF, 0xFF, 0xFF), inter);
    fill(c);
    noStroke();
    ellipse(width/2, height/2, r * 2, r * 2);
  }
}

void drawCrystalBall(float x, float y, float radius) {
  noStroke();
  for (int r = int(radius); r > 0; r--) {
    float inter = map(r, 0, radius, 0, 1);
    int c = lerpColor(color(0xA0, 0xD9, 0xFF), color(0xFF, 0xFF, 0xFF), inter);
    fill(c, 150);
    circle(x, y, r * 2);
  }
}

void drawSnowGround(float x, float y, float radius) {
  fill(255);
  noStroke();
  
  pushMatrix();
  translate(x, y);
  beginShape();
  for (float angle = 0; angle <= PI; angle += 0.1) {
    float px = cos(angle) * radius * 0.95;
    float py = sin(angle) * radius * 0.95;
    if (py > radius * 0.5) {
      vertex(px, py);
    }
  }
  endShape(CLOSE);
  popMatrix();
}

void drawBase(float x, float y) {
  noStroke();
  
  // 梯形底座 - 线性渐变从上到下
  float baseWidth = 100;
  float baseHeight = 60;
  
  // 绘制线性渐变
  for (float i = 0; i < baseHeight; i++) {
    float inter = map(i, 0, baseHeight, 0, 1);
    color c = lerpColor(color(0xB4, 0xC6, 0xE3), color(0x85, 0xA5, 0xDC), inter);
    fill(c);
    
    // 计算当前高度的梯形宽度
    float topWidthRatio = 0.7;
    float currentTopWidth = baseWidth * topWidthRatio + (baseWidth - baseWidth * topWidthRatio) * (i / baseHeight);
    float nextTopWidth = baseWidth * topWidthRatio + (baseWidth - baseWidth * topWidthRatio) * ((i + 1) / baseHeight);
    
    quad(x - currentTopWidth, y + i,
         x + currentTopWidth, y + i,
         x + nextTopWidth, y + i + 1,
         x - nextTopWidth, y + i + 1);
  }
}

void drawSnowman(float x, float y) {
  drawLinearGradientCircle(x, y + 45, 110, color(0xFF, 0xFF, 0xFF), color(0xE4, 0xF8, 0xFF), true);
  drawLinearGradientCircle(x, y - 25, 80, color(0xE4, 0xF8, 0xFF), color(0xFF, 0xFF, 0xFF), false);
  
  fill(0x9A, 0x9C, 0xBA);
  noStroke();
  triangle(x - 15, y - 60, x + 15, y - 60, x, y - 100);
  
  fill(180, 190, 200);
  noStroke();
  circle(x - 12, y - 30, 5);
  circle(x + 12, y - 30, 5);
  
  fill(240, 130, 60);
  triangle(x, y - 22, x + 16, y - 18, x, y - 14);
  
  fill(100, 110, 130);
  noStroke();
  circle(x, y + 25, 6);
  circle(x, y + 40, 6);
  circle(x, y + 55, 6);
  
  stroke(180, 160, 140);
  strokeWeight(3);
  noFill();
  
  line(x - 45, y + 10, x - 80, y - 5);
  line(x - 80, y - 5, x - 88, y - 2);
  line(x - 80, y - 5, x - 88, y - 10);
  
  line(x + 45, y + 10, x + 80, y - 5);
  line(x + 80, y - 5, x + 88, y - 2);
  line(x + 80, y - 5, x + 88, y - 10);
}

void drawLinearGradientCircle(float x, float y, float diameter, color c1, color c2, boolean leftToRight) {
  noStroke();
  float radius = diameter / 2;
  
  for (float i = -radius; i <= radius; i++) {
    float inter = map(i, -radius, radius, 0, 1);
    if (!leftToRight) {
      inter = 1 - inter;
    }
    color c = lerpColor(c1, c2, inter);
    fill(c);
    
    float h = sqrt(radius * radius - i * i) * 2;
    if (h > 0) {
      rect(x + i, y - h/2, 1, h);
    }
  }
}
