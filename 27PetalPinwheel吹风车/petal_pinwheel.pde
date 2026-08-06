// 27 petal pinwheel
// Blow into the microphone to spin the translucent petal pinwheel.

import processing.sound.*;

float designW = 600;
float designH = 800;
float viewScale = 1;
float viewOffsetX = 0;
float viewOffsetY = 0;

AudioIn mic;
Amplitude amplitude;
PGraphics stageLayer;
PImage bg;

float micLevel = 0;
float quietLevel = 0.012;
float blowPower = 0;
float blowFlash = 0;

float rotationAngle = -0.18;
float rotationSpeed = 0;
float wobble = 0;
float wobbleVelocity = 0;

float pinwheelX = 300;
float pinwheelY = 305;
float stemBottomY = 676;
float paperX = 0;
float paperY = 0;
float paperW = 600;
float paperH = 800;

// ===== 风车转速更改区 =====
// blowSpinBoost：吹气瞬间给风车增加的转速。越大，吹一下转得越猛。
// steadySpinBoost：持续吹气时每帧增加的转速。越大，持续吹时越容易加速。
// spinFriction：转速阻尼。越接近 1，风停后转得越久；越小越快停。
// maxSpinSpeed：最高转速限制。
// stopSpinThreshold：低于这个转速时直接停住，避免无风时轻微抖动。
float blowSpinBoost = 0.08;
float steadySpinBoost = 0.035;
float spinFriction = 0.982;
float maxSpinSpeed = 0.72;
float stopSpinThreshold = 0.0015;

// ===== 风车形状更改区 =====
// petalCount：花瓣数量。
// petalWidth / petalHeight：单片花瓣的宽和高。
// petalDistance：花瓣中心离风车中心的距离。
int petalCount = 6;
float petalWidth = 88;
float petalHeight = 176;
float petalDistance = 86;

// ===== 风车颜色更改区 =====
// 上方更白、更不透明；下方保持白色但透明度减少。
color petalColor = color(245, 252, 255);
float petalTopAlpha = 158;
float petalBottomAlpha = 76;
float innerPetalAlphaScale = 0.66;

// ===== 背景花瓣更改区 =====
// floatingPetalCount：最多同时飘过的背景花瓣数量。
// floatingPetalMinSize / floatingPetalMaxSize：背景花瓣随机大小。
// floatingPetalAlpha：背景花瓣整体透明度。
int floatingPetalCount = 28;
float floatingPetalMinSize = 14;
float floatingPetalMaxSize = 34;
float floatingPetalAlpha = 92;
FloatingPetal[] floatingPetals = new FloatingPetal[floatingPetalCount];
float floatingPetalDebt = 0;

// ===== 底部草叶更改区 =====
// grassBladeCount：草叶数量。
// grassBaseY：草叶底部位置。
// grassMinHeight / grassMaxHeight：草叶随机高度。
// grassAlpha：草叶整体透明度。
// grassGrowSpeed / grassShrinkSpeed：有风长出、风停消失的速度。
int grassBladeCount = 30;
float grassBaseY = 724;
float grassMinHeight = 123;
float grassMaxHeight = 249;
float grassAlpha = 112;
float grassGrowSpeed = 0.055;
float grassShrinkSpeed = 0.045;
float grassGrowth = 0;
float grassSway = 0;
float grassSwayVelocity = 0;

void setup() {
  size(600, 800);
  smooth(8);
  setupView();
  bg = loadImage(sketchPath("background.jpg"));
  makeStageLayer();

  mic = new AudioIn(this, 0);
  mic.start();
  amplitude = new Amplitude(this);
  amplitude.input(mic);

  for (int i = 0; i < floatingPetalCount; i++) {
    floatingPetals[i] = new FloatingPetal();
  }
}

void draw() {
  setupView();
  updateSound();
  updatePinwheel();
  updateFloatingPetals();
  updateGrass();

  pushMatrix();
  translate(viewOffsetX, viewOffsetY);
  scale(viewScale);

  drawStage();
  drawFloatingPetals();
  drawGrass();
  drawStem();
  drawPinwheel();
  drawSoundMeter();

  popMatrix();
}

void keyPressed() {
  if (key == ' ' || key == ENTER || key == RETURN) {
    addBlow(0.7);
  }
}

void mouseDragged() {
  addBlow(map(mouseX - pmouseX, -40, 40, -0.6, 0.9));
}

void setupView() {
  viewScale = min(width / designW, height / designH);
  viewOffsetX = (width - designW * viewScale) / 2.0;
  viewOffsetY = (height - designH * viewScale) / 2.0;
}

void updateSound() {
  float rawLevel = amplitude.analyze();
  micLevel = lerp(micLevel, rawLevel, 0.24);

  if (micLevel < quietLevel + 0.012) {
    quietLevel = lerp(quietLevel, micLevel, 0.012);
  }

  float activeSound = max(0, micLevel - quietLevel);
  // 灵敏度调节：想更容易吹动，调小 0.010 和 0.115；想更稳，调大它们。
  float targetBlow = constrain(map(activeSound, 0.010, 0.115, 0, 1), 0, 1);
  blowPower = lerp(blowPower, targetBlow, 0.2);

  if (blowPower > 0.06) {
    addBlow(blowPower * blowSpinBoost);
    blowFlash = max(blowFlash, blowPower);
  }

  blowFlash *= 0.92;
}

void addBlow(float amount) {
  rotationSpeed += amount;
  rotationSpeed = constrain(rotationSpeed, -0.18, maxSpinSpeed);
  wobbleVelocity += amount * 0.018;
  floatingPetalDebt += abs(amount) * 2.2;
}

void updatePinwheel() {
  rotationSpeed += blowPower * steadySpinBoost;
  rotationSpeed *= spinFriction;
  if (blowPower < 0.025 && abs(rotationSpeed) < stopSpinThreshold) {
    rotationSpeed = 0;
  }
  rotationAngle += rotationSpeed;

  float targetWobble = 0;
  if (blowPower > 0.025 || abs(rotationSpeed) > 0.006) {
    targetWobble = sin(rotationAngle * 1.7) * (0.01 + blowPower * 0.055 + abs(rotationSpeed) * 0.03);
  }
  wobbleVelocity += (targetWobble - wobble) * 0.045;
  wobbleVelocity *= 0.86;
  wobble += wobbleVelocity;
  if (targetWobble == 0 && abs(wobble) < 0.0005 && abs(wobbleVelocity) < 0.0005) {
    wobble = 0;
    wobbleVelocity = 0;
  }
}

void updateFloatingPetals() {
  if (blowPower > 0.1) {
    floatingPetalDebt += blowPower * 0.34;
  }

  while (floatingPetalDebt >= 1) {
    spawnFloatingPetal();
    floatingPetalDebt -= 1;
  }

  for (int i = 0; i < floatingPetalCount; i++) {
    floatingPetals[i].update();
  }
}

void spawnFloatingPetal() {
  for (int i = 0; i < floatingPetalCount; i++) {
    if (!floatingPetals[i].alive) {
      floatingPetals[i].reset();
      return;
    }
  }
}

void updateGrass() {
  float targetGrowth = blowPower > 0.06 ? 1 : 0;
  float growthSpeed = targetGrowth > grassGrowth ? grassGrowSpeed : grassShrinkSpeed;
  grassGrowth = lerp(grassGrowth, targetGrowth, growthSpeed);
  if (targetGrowth == 0 && grassGrowth < 0.01) {
    grassGrowth = 0;
  }

  float targetSway = 0;
  if (grassGrowth > 0.01) {
    targetSway = constrain(rotationSpeed * 34 + blowPower * 30, -18, 34);
  }
  grassSwayVelocity += (targetSway - grassSway) * 0.055;
  grassSwayVelocity *= 0.86;
  grassSway += grassSwayVelocity;
}

void drawStage() {
  imageMode(CORNER);
  image(stageLayer, 0, 0);
}

void makeStageLayer() {
  stageLayer = createGraphics(int(designW), int(designH));
  stageLayer.beginDraw();
  stageLayer.smooth(8);
  stageLayer.background(94, 96, 94);

  if (bg != null) {
    drawCoverImage(stageLayer, bg, paperX, paperY, paperW, paperH);
  } else {
    drawFallbackPaper(stageLayer);
  }

  stageLayer.noFill();
  stageLayer.stroke(18, 18, 18, 190);
  stageLayer.strokeWeight(1.2);
  stageLayer.rect(0.6, 0.6, designW - 1.2, designH - 1.2);
  stageLayer.endDraw();
}

void drawCoverImage(PGraphics pg, PImage img, float x, float y, float w, float h) {
  float targetRatio = w / h;
  float imageRatio = img.width / float(img.height);
  int sourceX = 0;
  int sourceY = 0;
  int sourceW = img.width;
  int sourceH = img.height;

  if (imageRatio > targetRatio) {
    sourceW = int(img.height * targetRatio);
    sourceX = (img.width - sourceW) / 2;
  } else {
    sourceH = int(img.width / targetRatio);
    sourceY = (img.height - sourceH) / 2;
  }

  pg.copy(img, sourceX, sourceY, sourceW, sourceH, int(x), int(y), int(w), int(h));
}

void drawFallbackPaper(PGraphics pg) {
  pg.noStroke();
  for (int y = 0; y < int(paperH); y++) {
    float yy = paperY + y;
    float t = y / paperH;
    color c1 = lerpColor(color(250, 252, 255), color(207, 234, 244), t);
    color c2 = lerpColor(color(214, 225, 255), color(236, 253, 250), t);
    for (int x = 0; x < int(paperW); x += 3) {
      float gx = x / paperW;
      color c = lerpColor(c1, c2, gx);
      pg.fill(c, 72);
      pg.rect(paperX + x, yy, 3, 1.2);
    }
  }

  drawGlow(pg, paperX + paperW * 0.55, paperY + paperH * 0.43, 490, color(101, 196, 242), 55);
  drawGlow(pg, paperX + paperW * 0.35, paperY + paperH * 0.31, 380, color(115, 151, 244), 34);
}

void drawGlow(PGraphics pg, float x, float y, float diameter, color c, float maxAlpha) {
  pg.noStroke();
  for (float r = diameter; r > 0; r -= 12) {
    float a = pow(r / diameter, 1.6) * maxAlpha;
    pg.fill(red(c), green(c), blue(c), a);
    pg.ellipse(x, y, r, r);
  }
}

void drawStem() {
  float sway = wobble * 42;
  strokeCap(ROUND);
  stroke(226, 239, 244, 150);
  strokeWeight(6);
  line(pinwheelX, pinwheelY + 2, pinwheelX + sway * 0.5, stemBottomY);
  stroke(255, 255, 255, 105);
  strokeWeight(2);
  line(pinwheelX - 4, pinwheelY + 14, pinwheelX + sway * 0.5 - 4, stemBottomY - 8);
}

void drawPinwheel() {
  pushMatrix();
  translate(pinwheelX, pinwheelY);
  rotate(rotationAngle + wobble);

  for (int i = 0; i < petalCount; i++) {
    float a = TWO_PI / petalCount * i;
    drawPetal(a, 1.0, 1.0);
  }

  rotate(-rotationAngle * 0.09);
  for (int i = 0; i < petalCount; i++) {
    float a = TWO_PI / petalCount * i + 0.18;
    drawPetal(a, 0.72, innerPetalAlphaScale);
  }

  noStroke();
  fill(255, 255, 255, 190);
  ellipse(0, 0, 25, 25);
  fill(207, 232, 244, 160);
  ellipse(0, 0, 12, 12);

  popMatrix();
}

void drawPetal(float angle, float scaleFactor, float alphaScale) {
  pushMatrix();
  rotate(angle);
  translate(0, -petalDistance * scaleFactor);

  float spinTint = constrain(abs(rotationSpeed) * 190, 0, 60);
  noStroke();
  float w = petalWidth * scaleFactor;
  float h = petalHeight * scaleFactor;
  for (float y = -h / 2.0; y <= h / 2.0; y += 1.0) {
    float verticalPosition = map(y, -h / 2.0, h / 2.0, 0, 1);
    float halfWidth = w * 0.5 * sqrt(max(0, 1 - sq(y / (h * 0.5))));
    float alphaValue = lerp(petalTopAlpha + spinTint, petalBottomAlpha + spinTint * 0.35, verticalPosition) * alphaScale;
    fill(red(petalColor), green(petalColor), blue(petalColor), alphaValue);
    rect(-halfWidth, y, halfWidth * 2.0, 1.35);
  }

  popMatrix();
}

void drawFloatingPetals() {
  for (int i = 0; i < floatingPetalCount; i++) {
    floatingPetals[i].draw();
  }
}

void drawGrass() {
  if (grassGrowth <= 0.001) return;

  float easedGrowth = 1 - pow(1 - grassGrowth, 3);
  noStroke();
  for (int i = 0; i < grassBladeCount; i++) {
    float t = i / float(max(1, grassBladeCount - 1));
    float x = lerp(64, 538, t);
    float h = lerp(grassMinHeight, grassMaxHeight, noise(i * 0.83)) * easedGrowth;
    float w = lerp(19.5, 36, noise(i * 1.17 + 40));
    float individualSway = grassSway * lerp(0.45, 1.0, noise(i * 0.51 + 9));
    float idleWave = sin(frameCount * 0.045 + i * 0.67) * blowPower * 9;
    float tipX = x + individualSway + idleWave + lerp(-11, 13, noise(i * 0.71 + 90));
    float tipY = grassBaseY - h;
    float baseLeft = x - w * 0.42;
    float baseRight = x + w * 0.42;

    fill(235, 244, 247, grassAlpha * 0.72);
    beginShape();
    vertex(baseLeft, grassBaseY);
    bezierVertex(x - w * 0.72, grassBaseY - h * 0.34, tipX - w * 0.18, grassBaseY - h * 0.72, tipX, tipY);
    bezierVertex(tipX - w * 0.02, grassBaseY - h * 0.60, x + w * 0.68, grassBaseY - h * 0.28, baseRight, grassBaseY);
    endShape(CLOSE);

    fill(255, 255, 255, grassAlpha * 0.42);
    beginShape();
    vertex(x - w * 0.16, grassBaseY);
    bezierVertex(x - w * 0.36, grassBaseY - h * 0.30, tipX - w * 0.10, grassBaseY - h * 0.66, tipX, tipY);
    bezierVertex(tipX - w * 0.03, grassBaseY - h * 0.50, x + w * 0.20, grassBaseY - h * 0.24, x + w * 0.11, grassBaseY);
    endShape(CLOSE);
  }
}

void drawSoundMeter() {
  float meterX = paperX + 30;
  float meterY = paperY + paperH - 42;
  float meterW = 118;
  float meterH = 5;
  noStroke();
  fill(255, 255, 255, 90);
  rect(meterX, meterY, meterW, meterH, 4);
  fill(120, 196, 232, 115 + blowFlash * 90);
  rect(meterX, meterY, meterW * blowPower, meterH, 4);
}

class FloatingPetal {
  boolean alive = false;
  float x, y, vx, vy, life, maxLife, size, spin, spinSpeed, flapOffset;

  void reset() {
    alive = true;
    x = random(-90, pinwheelX - 20);
    y = random(pinwheelY + 50, paperH + 60);
    vx = random(1.8, 4.5) + blowPower * 4.5;
    vy = random(-3.8, -1.6) - blowPower * 1.8;
    maxLife = random(90, 145);
    life = maxLife;
    size = random(floatingPetalMinSize, floatingPetalMaxSize);
    spin = random(TWO_PI);
    spinSpeed = random(-0.045, 0.045) + rotationSpeed * 0.025;
    flapOffset = random(TWO_PI);
  }

  void update() {
    if (!alive) return;
    x += vx;
    y += vy + sin(frameCount * 0.06 + flapOffset + x * 0.01) * 0.45;
    vx *= 0.992;
    vy += sin(frameCount * 0.035 + flapOffset) * 0.012 + 0.006;
    spin += spinSpeed;
    life--;
    if (life <= 0 || x > paperX + paperW + 80 || y < paperY - 80 || y > paperY + paperH + 80) {
      alive = false;
    }
  }

  void draw() {
    if (!alive) return;
    float a = constrain(life / maxLife, 0, 1);
    pushMatrix();
    translate(x, y);
    rotate(spin);
    noStroke();
    drawFloatingPetalShape(size, floatingPetalAlpha * a);
    popMatrix();
  }
}

void drawFloatingPetalShape(float sizeValue, float alphaValue) {
  fill(245, 252, 255, alphaValue);
  ellipse(0, 0, sizeValue * 0.54, sizeValue);

  fill(255, 255, 255, alphaValue * 0.28);
  ellipse(-sizeValue * 0.08, -sizeValue * 0.16, sizeValue * 0.22, sizeValue * 0.48);
}
