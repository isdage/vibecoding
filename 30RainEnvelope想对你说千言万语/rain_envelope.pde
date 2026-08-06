// 白底信封 - 点击打开/关闭

PImage openFlapImg;
PImage pageBackgroundImg;
PImage waterRippleImg;
PFont floatingTextFont;
ArrayList<DrizzleDrop> drizzle = new ArrayList<DrizzleDrop>();
ArrayList<FloatingText> floatingTexts = new ArrayList<FloatingText>();
float[][] waterCurrent;
float[][] waterPrevious;
int waterCols;
int waterRows;
float waterOriginX;
float waterOriginY;

float openProgress = 0;
float openVelocity = 0;
boolean envelopeOpen = false;
float envelopeAngle = radians(30);

// ===== 信封底部长方形调整区 =====
float rectCenterX = 300;
float rectCenterY = 455;
float rectW = 330;
float rectH = 200;

// ===== 左右白色折片调整区 =====
float leftFlapTopInset = 32;
float leftFlapBottomW = 205;
float rightFlapTopInset = 32;
float rightFlapBottomW = 205;

// ===== 底部白色正梯形调整区 =====
float bottomFlapTopW = 75;
float bottomFlapTopY = 445;

// ===== 底部正梯形阴影调整区 =====
float bottomShadowBlur = 8.5;
float bottomShadowOpacity = 40;
color bottomShadowColor = color(137, 148, 150);
color paperCastShadowColor = color(120, 164, 190);
float paperCastShadowOpacity = 34;

// ===== 上盖半圆调整区 =====
float closedFlapH = 230;
float closedFlapShadowOpacity = 18;
float openFlapH = 230;
color envelopeBackColor = #ffffff;
color flapCoverColor = #ffffff;
color openFlapColor = #ffffff;
float photoBrightnessOverlay = 36;

// ===== 打开动画调整区 =====
float openSpring = 0.018;
float openDamping = 0.86;

// ===== 图片水波纹调整区 =====
float rippleDampening = 0.986;
float rippleStrength = 1600;
float rippleDrawStrength = 0.11;
int rippleDropRadius = 4;
color rippleLightColor = color(242, 252, 255);
color rippleDarkColor = color(62, 142, 196);

// ===== 打开后背景毛毛雨调整区 =====
int drizzleTargetCount = 260;
color drizzleColor = color(255);
float drizzleAlpha = 128;

// ===== 点击后白色文字生长调整区 =====
String[] floatingTextOptions = {
  "雨落下来，像没说完的话，",
  "一滴一滴，敲在夜的窗纱。",
  "我把你的名字藏进伞下，",
  "却遮不住，想你的潮湿与沙哑。",
  "爱你，是雨中不肯熄灭的灯，",
  "明知风冷，也偏要为你亮着。",
  "我在旧路口等到街声变轻，",
  "等一朵伞影，像你，慢慢靠近。",
  "若你不来，雨也会陪我等，",
  "把这一夜，淋成温柔的伤痕。",
  "我不问归期，也不怪黄昏，",
  "只是爱你，爱到雨停，仍在等。"
};
float floatingTextLife = 168;
float floatingTextSize = 13;
color floatingTextColor = color(255);

void setup() {
  size(600, 800, P2D);
  smooth(8);
  openFlapImg = loadImage("background.jpg");
  pageBackgroundImg = loadImage("background2.jpg");
  floatingTextFont = createFont(sketchPath("方正兰亭刊宋_GBK.TTF"), floatingTextSize, true);
  setupWaterRipples();
}

void draw() {
  drawPageBackground();
  updateOpenAnimation();
  updateWaterRipples();
  updateDrizzle();
  updateFloatingTexts();
  drawDrizzle();

  pushMatrix();
  translate(rectCenterX, rectCenterY);
  rotate(envelopeAngle);
  translate(-rectCenterX, -rectCenterY);
  drawOpenTopFlap();
  drawBaseRectangle();
  drawPhotoBrightnessOverlay();
  drawWaterRipples();
  drawPaperCastShadows();
  drawLeftFlap();
  drawRightFlap();
  drawBottomFlap();
  drawClosedTopFlap();
  drawFloatingTexts();
  popMatrix();
}

void drawPageBackground() {
  if (pageBackgroundImg != null) {
    imageMode(CORNER);
    image(pageBackgroundImg, 0, 0, width, height);
  } else {
    background(#ededed);
  }
}

void mousePressed() {
  PVector localMouse = screenToEnvelope(mouseX, mouseY);

  if (isVisiblePhotoPoint(localMouse.x, localMouse.y)) {
    addWaterDrop(localMouse.x, localMouse.y);
    addFloatingText(localMouse.x, localMouse.y);
    return;
  }

  envelopeOpen = !envelopeOpen;
  if (!envelopeOpen) {
    clearWaterRipples();
    drizzle.clear();
    floatingTexts.clear();
  }
}

void addFloatingText(float x, float y) {
  String content = floatingTextOptions[int(random(floatingTextOptions.length))];
  floatingTexts.add(new FloatingText(content, x + random(-10, 10), y + random(-8, 8)));
}

void updateFloatingTexts() {
  for (int i = floatingTexts.size() - 1; i >= 0; i--) {
    FloatingText floatingText = floatingTexts.get(i);
    floatingText.update();
    if (floatingText.finished) {
      floatingTexts.remove(i);
    }
  }
}

void drawFloatingTexts() {
  if (floatingTextFont != null) {
    textFont(floatingTextFont);
  }

  textAlign(CENTER, CENTER);
  for (FloatingText floatingText : floatingTexts) {
    floatingText.display();
  }
}

void updateDrizzle() {
  if (envelopeOpen) {
    while (drizzle.size() < drizzleTargetCount) {
      drizzle.add(new DrizzleDrop(true));
    }
  }

  for (int i = drizzle.size() - 1; i >= 0; i--) {
    DrizzleDrop drop = drizzle.get(i);
    drop.update();

    if (drop.finished) {
      if (envelopeOpen) {
        drizzle.set(i, new DrizzleDrop(false));
      } else {
        drizzle.remove(i);
      }
    }
  }
}

void drawDrizzle() {
  strokeCap(SQUARE);
  for (DrizzleDrop drop : drizzle) {
    drop.display();
  }
}

PVector screenToEnvelope(float x, float y) {
  float dx = x - rectCenterX;
  float dy = y - rectCenterY;
  float cosA = cos(-envelopeAngle);
  float sinA = sin(-envelopeAngle);
  float localX = rectCenterX + dx * cosA - dy * sinA;
  float localY = rectCenterY + dx * sinA + dy * cosA;
  return new PVector(localX, localY);
}

void updateOpenAnimation() {
  float target = envelopeOpen ? 1 : 0;
  float force = (target - openProgress) * openSpring;
  openVelocity = (openVelocity + force) * openDamping;
  openProgress += openVelocity;

  if (abs(target - openProgress) < 0.001 && abs(openVelocity) < 0.001) {
    openProgress = target;
    openVelocity = 0;
  }

  openProgress = constrain(openProgress, 0, 1);
}

void setupWaterRipples() {
  waterCols = int(rectW);
  waterRows = int(rectH + openFlapH * 0.5);
  waterOriginX = rectCenterX - rectW * 0.5;
  waterOriginY = rectCenterY - rectH * 0.5 - openFlapH * 0.5;
  waterCurrent = new float[waterCols][waterRows];
  waterPrevious = new float[waterCols][waterRows];
  waterRippleImg = createImage(waterCols, waterRows, ARGB);
}

void clearWaterRipples() {
  for (int x = 0; x < waterCols; x++) {
    for (int y = 0; y < waterRows; y++) {
      waterCurrent[x][y] = 0;
      waterPrevious[x][y] = 0;
    }
  }
}

void addWaterDrop(float x, float y) {
  int centerX = int(x - waterOriginX);
  int centerY = int(y - waterOriginY);

  for (int dx = -rippleDropRadius; dx <= rippleDropRadius; dx++) {
    for (int dy = -rippleDropRadius; dy <= rippleDropRadius; dy++) {
      int px = centerX + dx;
      int py = centerY + dy;
      float d = dist(0, 0, dx, dy);

      if (px > 1 && px < waterCols - 1 && py > 1 && py < waterRows - 1 && d <= rippleDropRadius) {
        waterPrevious[px][py] = rippleStrength * (1 - d / (rippleDropRadius + 1));
      }
    }
  }
}

void updateWaterRipples() {
  if (waterCurrent == null || waterPrevious == null) {
    return;
  }

  for (int x = 1; x < waterCols - 1; x++) {
    for (int y = 1; y < waterRows - 1; y++) {
      waterCurrent[x][y] =
        (waterPrevious[x - 1][y]
        + waterPrevious[x + 1][y]
        + waterPrevious[x][y - 1]
        + waterPrevious[x][y + 1]) * 0.5
        - waterCurrent[x][y];
      waterCurrent[x][y] *= rippleDampening;
    }
  }

  float[][] temp = waterPrevious;
  waterPrevious = waterCurrent;
  waterCurrent = temp;
}

void drawWaterRipples() {
  if (waterRippleImg == null || openProgress < 0.35) {
    return;
  }

  waterRippleImg.loadPixels();
  for (int y = 0; y < waterRows; y++) {
    for (int x = 0; x < waterCols; x++) {
      float worldX = waterOriginX + x;
      float worldY = waterOriginY + y;
      float value = waterPrevious[x][y];
      int index = x + y * waterCols;

      if (!isVisiblePhotoPoint(worldX, worldY) || abs(value) < 0.1) {
        waterRippleImg.pixels[index] = color(255, 0);
      } else {
        float alphaValue = constrain(abs(value) * rippleDrawStrength, 0, 95);
        color rippleTone = value > 0 ? rippleLightColor : rippleDarkColor;
        waterRippleImg.pixels[index] = color(
          red(rippleTone),
          green(rippleTone),
          blue(rippleTone),
          alphaValue
        );
      }
    }
  }
  waterRippleImg.updatePixels();

  imageMode(CORNER);
  image(waterRippleImg, waterOriginX, waterOriginY);
}

void drawBaseRectangle() {
  if (openFlapImg != null && openProgress > 0.001) {
    drawTexturedBaseRectangle(ease(openProgress));
    return;
  }

  rectMode(CENTER);
  noStroke();
  fill(envelopeBackColor);
  rect(rectCenterX, rectCenterY, rectW, rectH);
}

void drawTexturedBaseRectangle(float alphaScale) {
  float left = rectCenterX - rectW * 0.5;
  float right = rectCenterX + rectW * 0.5;
  float top = rectCenterY - rectH * 0.5;
  float bottom = rectCenterY + rectH * 0.5;

  noStroke();
  textureMode(NORMAL);
  tint(255, 255 * alphaScale);
  beginShape();
  texture(openFlapImg);
  vertex(left, top, 0, 0.5);
  vertex(right, top, 1, 0.5);
  vertex(right, bottom, 1, 1);
  vertex(left, bottom, 0, 1);
  endShape(CLOSE);
  noTint();
}

void drawPhotoBrightnessOverlay() {
  if (openFlapImg == null || openProgress <= 0.001) {
    return;
  }

  float alphaScale = ease(openProgress);
  noStroke();
  fill(255, photoBrightnessOverlay * alphaScale);
  drawOpenTopPhotoShape();
  drawBasePhotoShape();
}

void drawOpenTopPhotoShape() {
  float top = rectCenterY - rectH * 0.5;
  float p = ease(openProgress);
  float lift = sin(p * PI) * 10;
  float h = openFlapH * p + lift;

  if (h <= 0.1) {
    return;
  }

  beginShape();
  for (int i = 0; i <= 48; i++) {
    float angle = map(i, 0, 48, PI, TWO_PI);
    float x = rectCenterX + cos(angle) * rectW * 0.5;
    float y = top + sin(angle) * h * 0.5;
    vertex(x, y);
  }
  endShape(CLOSE);
}

void drawBasePhotoShape() {
  float left = rectCenterX - rectW * 0.5;
  float right = rectCenterX + rectW * 0.5;
  float top = rectCenterY - rectH * 0.5;
  float bottom = rectCenterY + rectH * 0.5;

  beginShape();
  vertex(left, top);
  vertex(right, top);
  vertex(right, bottom);
  vertex(left, bottom);
  endShape(CLOSE);
}

void drawPaperCastShadows() {
  float left = rectCenterX - rectW * 0.5;
  float right = rectCenterX + rectW * 0.5;
  float top = rectCenterY - rectH * 0.5;
  float bottom = rectCenterY + rectH * 0.5;
  float bottomTopLeft = rectCenterX - bottomFlapTopW * 0.5;
  float bottomTopRight = rectCenterX + bottomFlapTopW * 0.5;
  float alphaScale = max(0.28, ease(openProgress));

  drawSoftShadowLine(
    left + leftFlapTopInset,
    top,
    left + leftFlapBottomW,
    bottom,
    paperCastShadowOpacity * alphaScale
  );
  drawSoftShadowLine(
    right - rightFlapTopInset,
    top,
    right - rightFlapBottomW,
    bottom,
    paperCastShadowOpacity * alphaScale
  );
  drawSoftShadowLine(
    left,
    bottom,
    bottomTopLeft,
    bottomFlapTopY,
    paperCastShadowOpacity * 0.75 * alphaScale
  );
  drawSoftShadowLine(
    right,
    bottom,
    bottomTopRight,
    bottomFlapTopY,
    paperCastShadowOpacity * 0.75 * alphaScale
  );

  noStroke();
  for (int i = 7; i >= 1; i--) {
    float spread = i * 1.15;
    float a = paperCastShadowOpacity * alphaScale / (i * 2.1);
    fill(red(paperCastShadowColor), green(paperCastShadowColor), blue(paperCastShadowColor), a);
    beginShape();
    vertex(left + leftFlapTopInset + spread * 0.2, top + spread);
    vertex(right - rightFlapTopInset - spread * 0.2, top + spread);
    vertex(bottomTopRight + spread * 0.45, bottomFlapTopY + spread * 0.35);
    vertex(bottomTopLeft - spread * 0.45, bottomFlapTopY + spread * 0.35);
    endShape(CLOSE);
  }
}

void drawSoftShadowLine(float x1, float y1, float x2, float y2, float opacity) {
  strokeCap(ROUND);
  for (int i = 7; i >= 1; i--) {
    stroke(red(paperCastShadowColor), green(paperCastShadowColor), blue(paperCastShadowColor), opacity / (i * 1.55));
    strokeWeight(i);
    line(x1, y1, x2, y2);
  }
}

void drawLeftFlap() {
  float left = rectCenterX - rectW * 0.5;
  float top = rectCenterY - rectH * 0.5;
  float bottom = rectCenterY + rectH * 0.5;

  noStroke();
  fill(255);
  beginShape();
  vertex(left, top);
  vertex(left + leftFlapTopInset, top);
  vertex(left + leftFlapBottomW, bottom);
  vertex(left, bottom);
  endShape(CLOSE);
}

void drawRightFlap() {
  float right = rectCenterX + rectW * 0.5;
  float top = rectCenterY - rectH * 0.5;
  float bottom = rectCenterY + rectH * 0.5;

  noStroke();
  fill(255);
  beginShape();
  vertex(right - rightFlapTopInset, top);
  vertex(right, top);
  vertex(right, bottom);
  vertex(right - rightFlapBottomW, bottom);
  endShape(CLOSE);
}

void drawBottomFlap() {
  float left = rectCenterX - rectW * 0.5;
  float right = rectCenterX + rectW * 0.5;
  float bottom = rectCenterY + rectH * 0.5;
  float topLeft = rectCenterX - bottomFlapTopW * 0.5;
  float topRight = rectCenterX + bottomFlapTopW * 0.5;

  drawBottomFlapShadow(left, right, bottom, topLeft, topRight);

  noStroke();
  fill(255);
  beginShape();
  vertex(left, bottom);
  vertex(topLeft, bottomFlapTopY);
  vertex(topRight, bottomFlapTopY);
  vertex(right, bottom);
  endShape(CLOSE);
}

void drawBottomFlapShadow(float left, float right, float bottom, float topLeft, float topRight) {
  noStroke();
  for (int i = int(bottomShadowBlur); i >= 1; i--) {
    float spread = i;
    float alphaValue = map(i, int(bottomShadowBlur), 1, 0, bottomShadowOpacity * 2.55 / 7.0);
    fill(red(bottomShadowColor), green(bottomShadowColor), blue(bottomShadowColor), alphaValue);
    beginShape();
    vertex(left - spread, bottom + spread);
    vertex(topLeft - spread * 0.72, bottomFlapTopY - spread * 0.55);
    vertex(topRight + spread * 0.72, bottomFlapTopY - spread * 0.55);
    vertex(right + spread, bottom + spread);
    endShape(CLOSE);
  }
}

void drawOpenTopFlap() {
  if (openProgress <= 0.001) {
    return;
  }

  float top = rectCenterY - rectH * 0.5;
  float p = ease(openProgress);
  float lift = sin(p * PI) * 10;
  float h = openFlapH * p + lift;

  if (openFlapImg != null) {
    drawTexturedTopFlap(top, h, p);
    return;
  }

  noStroke();
  fill(openFlapColor, 255 * p);
  arc(rectCenterX, top, rectW, h, PI, TWO_PI, CHORD);
}

void drawTexturedTopFlap(float top, float h, float alphaScale) {
  float left = rectCenterX - rectW * 0.5;

  noStroke();
  textureMode(NORMAL);
  tint(255, 255 * alphaScale);
  beginShape();
  texture(openFlapImg);

  for (int i = 0; i <= 48; i++) {
    float angle = map(i, 0, 48, PI, TWO_PI);
    float x = rectCenterX + cos(angle) * rectW * 0.5;
    float y = top + sin(angle) * h * 0.5;
    float u = (x - left) / rectW;
    float v = map(y, top - h * 0.5, top, 0, 0.5);
    vertex(x, y, u, v);
  }

  endShape(CLOSE);
  noTint();
}

void drawClosedTopFlap() {
  if (openProgress >= 0.16) {
    return;
  }

  float top = rectCenterY - rectH * 0.5;
  float p = ease(constrain(openProgress / 0.16, 0, 1));
  float closeAmount = 1 - p;
  float h = closedFlapH * closeAmount;

  noStroke();
  fill(flapCoverColor, 255 * closeAmount);
  arc(rectCenterX, top, rectW, h, 0, PI, CHORD);

  noFill();
  for (int i = 4; i >= 1; i--) {
    stroke(137, 148, 150, closedFlapShadowOpacity * closeAmount / i);
    strokeWeight(i);
    arc(rectCenterX, top + i * 0.35, rectW, h, 0, PI);
  }
}

float ease(float t) {
  t = constrain(t, 0, 1);
  return t * t * (3 - 2 * t);
}

float smoothstep(float edge0, float edge1, float x) {
  float t = constrain((x - edge0) / (edge1 - edge0), 0, 1);
  return t * t * (3 - 2 * t);
}

boolean isVisiblePhotoPoint(float x, float y) {
  if (openFlapImg == null || openProgress < 0.35) {
    return false;
  }

  return isInOpenTopPhoto(x, y) || isInBasePhoto(x, y);
}

boolean isInOpenTopPhoto(float x, float y) {
  float top = rectCenterY - rectH * 0.5;
  float p = ease(openProgress);
  float lift = sin(p * PI) * 10;
  float h = openFlapH * p + lift;
  float rx = rectW * 0.5;
  float ry = h * 0.5;

  if (ry <= 0 || y < top - ry || y > top) {
    return false;
  }

  float nx = (x - rectCenterX) / rx;
  float ny = (y - top) / ry;
  return nx * nx + ny * ny <= 1;
}

boolean isInBasePhoto(float x, float y) {
  float left = rectCenterX - rectW * 0.5;
  float right = rectCenterX + rectW * 0.5;
  float top = rectCenterY - rectH * 0.5;
  float bottom = rectCenterY + rectH * 0.5;

  if (x < left || x > right || y < top || y > bottom) {
    return false;
  }

  if (isInLeftFlap(x, y) || isInRightFlap(x, y) || isInBottomFlap(x, y)) {
    return false;
  }

  return true;
}

boolean isInLeftFlap(float x, float y) {
  float left = rectCenterX - rectW * 0.5;
  float top = rectCenterY - rectH * 0.5;
  float bottom = rectCenterY + rectH * 0.5;

  return pointInQuad(
    x, y,
    left, top,
    left + leftFlapTopInset, top,
    left + leftFlapBottomW, bottom,
    left, bottom
  );
}

boolean isInRightFlap(float x, float y) {
  float right = rectCenterX + rectW * 0.5;
  float top = rectCenterY - rectH * 0.5;
  float bottom = rectCenterY + rectH * 0.5;

  return pointInQuad(
    x, y,
    right - rightFlapTopInset, top,
    right, top,
    right, bottom,
    right - rightFlapBottomW, bottom
  );
}

boolean isInBottomFlap(float x, float y) {
  float left = rectCenterX - rectW * 0.5;
  float right = rectCenterX + rectW * 0.5;
  float bottom = rectCenterY + rectH * 0.5;
  float topLeft = rectCenterX - bottomFlapTopW * 0.5;
  float topRight = rectCenterX + bottomFlapTopW * 0.5;

  return pointInQuad(
    x, y,
    left, bottom,
    topLeft, bottomFlapTopY,
    topRight, bottomFlapTopY,
    right, bottom
  );
}

boolean pointInQuad(
  float px, float py,
  float ax, float ay,
  float bx, float by,
  float cx, float cy,
  float dx, float dy
) {
  return pointInTriangle(px, py, ax, ay, bx, by, cx, cy)
    || pointInTriangle(px, py, ax, ay, cx, cy, dx, dy);
}

boolean pointInTriangle(
  float px, float py,
  float ax, float ay,
  float bx, float by,
  float cx, float cy
) {
  float d1 = sign(px, py, ax, ay, bx, by);
  float d2 = sign(px, py, bx, by, cx, cy);
  float d3 = sign(px, py, cx, cy, ax, ay);
  boolean hasNeg = d1 < 0 || d2 < 0 || d3 < 0;
  boolean hasPos = d1 > 0 || d2 > 0 || d3 > 0;
  return !(hasNeg && hasPos);
}

float sign(float px, float py, float ax, float ay, float bx, float by) {
  return (px - bx) * (ay - by) - (ax - bx) * (py - by);
}

class DrizzleDrop {
  float x;
  float y;
  float vx;
  float vy;
  float len;
  float weightValue;
  float alphaValue;
  boolean finished = false;

  DrizzleDrop(boolean anywhere) {
    reset(anywhere);
  }

  void reset(boolean anywhere) {
    if (anywhere) {
      x = random(-120, width + 220);
      y = random(-180, height + 120);
    } else {
      x = random(width * 0.45, width + 240);
      y = random(-220, height * 0.18);
    }

    float speed = random(3.4, 6.2);
    float depth = random(0.45, 1.0);
    vx = -speed * random(0.34, 0.48);
    vy = speed;
    len = random(38, 78) * depth;
    weightValue = random(0.55, 1.15) * depth;
    alphaValue = drizzleAlpha * random(0.42, 0.95) * depth;
    finished = false;
  }

  void update() {
    x += vx;
    y += vy;

    if (x < -180 || y > height + 180) {
      finished = true;
    }
  }

  void display() {
    float angle = atan2(vy, vx);
    float x2 = x - cos(angle) * len;
    float y2 = y - sin(angle) * len;

    stroke(red(drizzleColor), green(drizzleColor), blue(drizzleColor), alphaValue);
    strokeWeight(weightValue);
    line(x, y, x2, y2);
  }
}

class FloatingText {
  String content;
  float x;
  float y;
  float vx;
  float vy;
  float age = 0;
  float life;
  float baseAngle;
  float curveBend;
  float curveLength;
  float sizeScale;
  float waveSeed;
  boolean finished = false;

  FloatingText(String textContent, float startX, float startY) {
    content = textContent;
    x = startX;
    y = startY;
    float driftSide = random(1) < 0.5 ? -1 : 1;
    vx = driftSide * random(0.12, 0.34);
    vy = random(-0.48, -0.22);
    life = floatingTextLife * random(0.82, 1.18);
    if (driftSide < 0) {
      baseAngle = random(-2.72, -2.18);
    } else {
      baseAngle = random(-0.92, -0.42);
    }
    curveBend = random(-42, 46);
    curveLength = random(150, 230);
    sizeScale = random(0.88, 1.08);
    waveSeed = random(TWO_PI);
  }

  void update() {
    age++;
    float p = age / life;
    x += vx + sin(age * 0.035 + waveSeed) * 0.09;
    y += vy;
    vy *= 0.992;

    if (p >= 1) {
      finished = true;
    }
  }

  void display() {
    float p = constrain(age / life, 0, 1);
    float reveal = smoothstep(0.02, 0.58, p);
    float fadeOut = 1 - smoothstep(0.72, 1, p);
    float alphaValue = 245 * fadeOut;
    int visibleCount = max(1, int(content.length() * reveal));
    float s = floatingTextSize * sizeScale;

    textSize(s);
    noStroke();

    for (int i = 0; i < visibleCount; i++) {
      float t = content.length() <= 1 ? 0 : i / float(content.length() - 1);
      PVector pos = pointOnTextCurve(t);
      PVector next = pointOnTextCurve(min(1, t + 0.01));
      float charAngle = atan2(next.y - pos.y, next.x - pos.x);
      String ch = content.substring(i, i + 1);
      float charAlpha = alphaValue * smoothstep(0, 0.18, reveal - t);

      pushMatrix();
      translate(pos.x, pos.y);
      rotate(charAngle);
      fill(red(floatingTextColor), green(floatingTextColor), blue(floatingTextColor), charAlpha);
      text(ch, 0, 0);
      popMatrix();
    }
  }

  PVector pointOnTextCurve(float t) {
    float endX = x + cos(baseAngle) * curveLength;
    float endY = y + sin(baseAngle) * curveLength;
    float midX = (x + endX) * 0.5 + cos(baseAngle - HALF_PI) * curveBend;
    float midY = (y + endY) * 0.5 + sin(baseAngle - HALF_PI) * curveBend;
    float a = (1 - t) * (1 - t);
    float b = 2 * (1 - t) * t;
    float c = t * t;
    return new PVector(
      a * x + b * midX + c * endX,
      a * y + b * midY + c * endY
    );
  }
}
