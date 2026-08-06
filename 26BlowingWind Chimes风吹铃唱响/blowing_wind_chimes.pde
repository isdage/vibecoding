// 26 blowing wind chimes
// Blow into the microphone to move the wind chime.

import processing.sound.*;

float designW = 768;
float designH = 1024;
float viewScale = 1;
float viewOffsetX = 0;
float viewOffsetY = 0;

// ===== 风铃位置调整区 =====
// anchorX：整只风铃的顶部悬挂点左右位置。数值越大，风铃越往右。
float anchorX = 384;
// anchorY：整只风铃的顶部悬挂点上下位置。负数表示绳子从画面外上方垂下来。
float anchorY = -12;
// chimeTopY：三颗小圆珠最上面那颗的中心高度。数值越大，珠子越往下。
float chimeTopY = 150;
// shadeCenterY：半圆灯罩体的中心高度。数值越大，灯罩越往下。
float shadeCenterY = 335;
// shadeTopY：灯罩顶部连接主绳的位置。由 shadeCenterY 自动推算，灯罩现在以这个点为轴。
float shadeTopY = shadeCenterY - 115;
// stripTopY：下方小布条的顶部连接点高度。数值越大，布条整体越往下。
float stripTopY = 480;
// stripBottomY：下方小布条的底部高度。数值越大，布条越长。
float stripBottomY = 735;
// chimeScale：风铃整体大小。1.0 是原尺寸；1.0 / 1.2 表示整体缩小 1.2 倍。
float chimeScale = 1.0 / 1.2;

PImage bg;
AudioIn mic;
Amplitude amplitude;

// ===== 背景白色叶子粒子 =====
// maxLeaves：最多同时出现的叶子数量。越大，吹动强时画面越密。
int maxLeaves = 46;
Leaf[] leaves = new Leaf[maxLeaves];
float leafSpawnDebt = 0;

float wind = 0;
float windVelocity = 0;
// swing：主摆动角度。顶部绳子、珠子、灯罩共用这个角度，所以它们会连在一起晃。
float swing = 0;
float swingVelocity = 0;
// stripSwing：布条自己的延迟摆动角度。它会跟随主摆动，但反应更慢一点。
float stripSwing = 0;
float stripSwingVelocity = 0;
// shadeSwing：玻璃体自己的轻微二级摆动角度。顶部挂点固定，只让玻璃体下方轻轻晃。
float shadeSwing = 0;
float shadeSwingVelocity = 0;
float micLevel = 0;
// quietLevel：环境底噪估计。环境很吵时可以适当调大一点。
float quietLevel = 0.01;
// blowPower：当前吹气强度，范围大约是 0 到 1。
float blowPower = 0;

color whiteGlass = #fbfbf7;
color paleGreen = #b8dcb4;
// stripTopAlpha / stripBottomAlpha：纸条上方和底部的透明度，范围 0 到 255。
// 想让底部更透明，就把 stripBottomAlpha 调小；想更实，就调大。
float stripTopAlpha = 235;
float stripBottomAlpha = 155;

void setup() {
  size(600, 800);
  smooth(8);
  setupView();
  bg = loadImage(sketchPath("background.jpg"));

  mic = new AudioIn(this, 0);
  mic.start();
  amplitude = new Amplitude(this);
  amplitude.input(mic);

  for (int i = 0; i < maxLeaves; i++) {
    leaves[i] = new Leaf();
  }
}

void draw() {
  setupView();
  updateWind();
  updateLeaves();
  drawBackgroundImage();
  drawLeaves();
  drawChime();
}

void keyPressed() {
  if (key == ' ' || key == ENTER || key == RETURN) {
    windVelocity += random(-0.65, 0.65);
  }
}

void setupView() {
  viewScale = min(width / designW, height / designH);
  viewOffsetX = (width - designW * viewScale) / 2.0;
  viewOffsetY = (height - designH * viewScale) / 2.0;
}

void updateWind() {
  float rawLevel = amplitude.analyze();
  // 0.22：麦克风音量平滑速度。越大越灵敏但也越抖，越小越柔和。
  micLevel = lerp(micLevel, rawLevel, 0.22);

  if (micLevel < quietLevel + 0.015) {
    // 0.01：环境底噪自动校准速度。越大越快适应环境，但可能吃掉轻微吹气。
    quietLevel = lerp(quietLevel, micLevel, 0.01);
  }

  float activeSound = max(0, micLevel - quietLevel);
  // 声音灵敏度：0.012 是开始被识别为吹气的门槛，0.14 是达到最大吹动的音量。
  // 想更容易吹动：把 0.012 和 0.14 都调小；想不那么敏感：把它们调大。
  // 最后的 0.18 是吹气强度变化的平滑速度，越大反应越快。
  blowPower = lerp(blowPower, constrain(map(activeSound, 0.012, 0.14, 0, 1), 0, 1), 0.18);

  // breath：没有明显吹气时的轻微自然呼吸感。
  float breath = sin(frameCount * 0.018) * 0.11 + sin(frameCount * 0.047) * 0.04;
  // gustDirection：让风向慢慢左右交换，避免一直朝同一边僵硬倾斜。
  float gustDirection = sin(frameCount * 0.025) > 0 ? 1 : -1;
  // 1.65：声音带来的风力大小。越大，吹一下风铃越容易大幅度摆动。
  float soundWind = gustDirection * blowPower * 1.65;

  // 0.026：风力追随速度。越大越突然，越小越慢。
  // 0.92 / 0.965：风力阻尼。越接近 1，风会拖得越久。
  windVelocity += (soundWind + breath * (0.2 + blowPower) - wind) * 0.026;
  windVelocity *= 0.92;
  wind += windVelocity;
  wind *= 0.965;
  // -1.85 到 1.85：最大风力限制，防止摆动过猛。
  wind = constrain(wind, -1.85, 1.85);

  // 0.22：主摆动大小。越大，绳子、珠子、灯罩整体摆动越大。
  // constrain(..., -0.28, 0.28)：限制最大角度，避免吹太大时主绳穿出玻璃体宽度。
  float targetSwing = constrain(wind * 0.22, -0.28, 0.28);
  // 0.035：主摆动追随速度。越大反应越快，越小越有重量感。
  // 0.91：主摆动阻尼。越接近 1，回弹拖尾越长。
  swingVelocity += (targetSwing - swing) * 0.035;
  swingVelocity *= 0.91;
  swing += swingVelocity;
  swing = constrain(swing, -0.30, 0.30);

  // 0.035：玻璃体相对主绳多出来的轻微摆动量。越大，玻璃体下方越明显地轻晃。
  // 这里把相对角度限制在 -0.055 到 0.055，保证玻璃体不会和绳子错开太多。
  // 0.018：玻璃体追随速度。越小越柔，越大越贴着主摆动。
  // 0.90：玻璃体阻尼。越接近 1，细小回弹越久。
  float shadeOffset = constrain(wind * 0.035 + sin(frameCount * 0.04) * blowPower * 0.018, -0.055, 0.055);
  float targetShadeSwing = swing + shadeOffset;
  shadeSwingVelocity += (targetShadeSwing - shadeSwing) * 0.018;
  shadeSwingVelocity *= 0.90;
  shadeSwing += shadeSwingVelocity;
  shadeSwing = constrain(shadeSwing, swing - 0.065, swing + 0.065);

  // 0.22：布条比主风铃多出来的倾斜量。越大，布条被吹开的角度越明显。
  float targetStripSwing = swing + wind * 0.22;
  // 0.025：布条追随速度。越小延迟越明显，越大越贴着主体一起动。
  // 0.88：布条阻尼。越接近 1，布条晃动尾巴越长。
  stripSwingVelocity += (targetStripSwing - stripSwing) * 0.025;
  stripSwingVelocity *= 0.88;
  stripSwing += stripSwingVelocity;
}

void updateLeaves() {
  // 0.10：开始出现叶子的吹动门槛。越小越容易出现叶子。
  if (blowPower > 0.10) {
    // 0.34：叶子生成速度。越大，同样声音下出现的叶子越多。
    leafSpawnDebt += blowPower * 0.34;
  }

  while (leafSpawnDebt >= 1.0) {
    spawnLeaf();
    leafSpawnDebt -= 1.0;
  }

  for (int i = 0; i < maxLeaves; i++) {
    leaves[i].update();
  }
}

void spawnLeaf() {
  for (int i = 0; i < maxLeaves; i++) {
    if (!leaves[i].alive) {
      leaves[i].reset();
      return;
    }
  }
}

void drawBackgroundImage() {
  pushMatrix();
  translate(viewOffsetX, viewOffsetY);
  scale(viewScale);

  background(250, 252, 249);
  if (bg != null) {
    imageMode(CORNER);
    float bgScale = max(designW / float(bg.width), designH / float(bg.height));
    float bgW = bg.width * bgScale;
    float bgH = bg.height * bgScale;
    image(bg, (designW - bgW) / 2.0, (designH - bgH) / 2.0, bgW, bgH);
  }

  noStroke();
  for (int y = 0; y < designH; y++) {
    float edge = min(y / 140.0, (designH - y) / 140.0);
    edge = 1.0 - constrain(edge, 0, 1);
    fill(255, 255, 255, edge * 70);
    rect(0, y, designW, 1.2);
  }

  popMatrix();
}

void drawLeaves() {
  pushMatrix();
  translate(viewOffsetX, viewOffsetY);
  scale(viewScale);

  for (int i = 0; i < maxLeaves; i++) {
    leaves[i].draw();
  }

  popMatrix();
}

void drawChime() {
  pushMatrix();
  translate(viewOffsetX, viewOffsetY);
  scale(viewScale);
  translate(anchorX, anchorY);
  scale(chimeScale);
  translate(-anchorX, -anchorY);

  float mainAngle = swing;
  // beadTop：三颗珠子的顶部位置，会沿着主绳摆动。
  PVector beadTop = pointOnCord(chimeTopY, mainAngle);
  // shadeTop：半圆灯罩体顶部挂点。灯罩以这里为轴心，不再用中心点乱漂。
  PVector shadeTop = pointOnCord(shadeTopY, mainAngle);
  // stripTop：下方布条连接到主绳的位置，会沿着主绳摆动。
  PVector stripTop = pointOnCord(stripTopY, mainAngle);

  stroke(255, 255, 255, 232);
  strokeWeight(5);
  strokeCap(ROUND);
  // 主绳：从画面上方悬挂点，一直连接到布条顶部。
  line(anchorX, anchorY, stripTop.x, stripTop.y);

  drawTopBeads(beadTop.x, beadTop.y, mainAngle);
  drawShade(shadeTop.x, shadeTop.y, shadeSwing);
  drawHangingStrip(stripTop.x, stripTop.y, stripSwing);

  popMatrix();
}

void drawTopBeads(float x, float y, float angle) {
  pushMatrix();
  translate(x, y);
  // 这里用 -angle，保证三颗珠子的竖直排列方向和主绳完全重合。
  rotate(-angle);
  noStroke();

  // 顶部三颗圆珠：第一颗较大，下面两颗较小。
  drawRadialEllipse(0, 0, 24, 24, color(255, 255, 255), color(245, 251, 244), 20);
  drawRadialEllipse(0, 24, 16, 16, color(255, 255, 255), color(238, 249, 236), 16);
  drawRadialEllipse(0, 45, 16, 16, color(255, 255, 255), color(238, 249, 236), 16);

  popMatrix();
}

void drawShade(float x, float y, float angle) {
  pushMatrix();
  translate(x, y);
  // 灯罩以顶部连接点为轴旋转，上方稳定，下面随风摆动。
  rotate(-angle);
  noStroke();

  // 灯罩大小：domeW 控制最宽处，domeH 控制圆拱高度。
  float domeW = 240;
  float domeH = 210;
  // bottomY：平切底边的位置。bottomHalfW 控制底边的半宽。
  float bottomY = 196;
  float bottomHalfW = 94;
  // chamferStartY：从这里开始把圆拱侧边收成底部斜角。
  float chamferStartY = 158;

  for (int yy = 0; yy <= bottomY; yy++) {
    float localY = yy;
    float t = yy / bottomY;
    float domeY = yy - domeH * 0.5;
    float domeCurve = sqrt(max(0, 1.0 - sq(domeY / (domeH * 0.5))));
    float roundHalfW = domeW * 0.5 * domeCurve;
    float chamferT = smoothstep(chamferStartY, bottomY, yy);
    float halfW = lerp(roundHalfW, bottomHalfW, chamferT);

    color c = lerpColor(whiteGlass, paleGreen, smoothstep(0.12, 0.92, t));
    fill(c, 202);
    // 2.2：每条渐变切片的高度。整体缩放后仍然互相覆盖，避免出现横向条纹。
    rect(-halfW, localY, halfW * 2.0, 2.2);
  }

  popMatrix();
}

void drawHangingStrip(float topX, float topY, float angle) {
  pushMatrix();
  translate(topX, topY);
  // 布条也使用同一套旋转方向，只是角度来自 stripSwing，所以有自然延迟。
  rotate(-angle);
  noStroke();

  // 布条大小：stripW 控制宽度，stripH 由 stripTopY 和 stripBottomY 决定。
  float stripW = 60;
  float stripH = stripBottomY - stripTopY;
  // 18：布条被风吹弯的幅度。越大，布条底部偏移越明显。
  // 10：吹气时额外的轻微飘动幅度。越大，布条越活泼。
  float curve = wind * 18 + sin(frameCount * 0.035) * blowPower * 10;

  for (int i = 0; i < stripH; i++) {
    float t = i / max(1.0, stripH - 1.0);
    float centerX = curve * sin(t * HALF_PI) * t;
    color c = lerpColor(color(255, 249, 242), color(163, 211, 177), smoothstep(0.0, 1.0, t));
    float stripAlpha = lerp(stripTopAlpha, stripBottomAlpha, smoothstep(0.0, 1.0, t));
    fill(c, stripAlpha);
    // 2.0：每条布条渐变切片的高度，缩放后也会重叠，避免细条纹。
    rect(centerX - stripW / 2.0, i, stripW, 2.0);
  }

  fill(255, 255, 255, 30);
  beginShape();
  for (int i = 0; i <= stripH; i += 6) {
    float t = i / stripH;
    float centerX = curve * sin(t * HALF_PI) * t;
    vertex(centerX - stripW / 2.0, i);
  }
  for (int i = int(stripH); i >= 0; i -= 6) {
    float t = i / stripH;
    float centerX = curve * sin(t * HALF_PI) * t;
    vertex(centerX - stripW * 0.15, i);
  }
  endShape(CLOSE);

  popMatrix();
}

PVector pointOnCord(float y, float angle) {
  float length = y - anchorY;
  return new PVector(anchorX + sin(angle) * length, anchorY + cos(angle) * length);
}

float smoothstep(float edge0, float edge1, float x) {
  float t = constrain((x - edge0) / (edge1 - edge0), 0, 1);
  return t * t * (3 - 2 * t);
}

void drawRadialEllipse(float x, float y, float w, float h, color centerColor, color outerColor, int steps) {
  noStroke();
  for (int i = steps; i >= 1; i--) {
    float t = i / float(steps);
    fill(lerpColor(centerColor, outerColor, t));
    ellipse(x, y, w * t, h * t);
  }
}

class Leaf {
  float x;
  float y;
  float vx;
  float vy;
  float size;
  float angle;
  float spin;
  float age;
  float life;
  float alpha;
  boolean alive = false;

  void reset() {
    alive = true;
    age = 0;
    life = random(150, 260);

    // 叶子主要从画面下半部和两侧被吹进来，避免一出现就盖住风铃主体。
    if (random(1) < 0.55) {
      x = random(80, designW - 80);
      y = random(designH * 0.58, designH + 80);
    } else {
      x = random(1) < 0.5 ? random(-80, 80) : random(designW - 80, designW + 80);
      y = random(designH * 0.35, designH * 0.86);
    }

    float windSide = wind >= 0 ? 1 : -1;
    vx = windSide * random(0.35, 1.45) + wind * random(0.45, 0.9);
    vy = random(-1.75, -0.55) - blowPower * random(0.4, 1.3);
    size = random(22, 62) * (0.75 + blowPower * 0.7);
    angle = random(-0.9, 0.9);
    spin = random(-0.018, 0.018) + wind * 0.006;
    alpha = random(70, 150) * (0.55 + blowPower * 0.65);
  }

  void update() {
    if (!alive) {
      return;
    }

    age++;
    float wave = sin(age * 0.035 + size) * 0.42;
    x += vx + wind * 0.65 + wave;
    y += vy + sin(age * 0.025) * 0.22;
    angle += spin + wind * 0.002;

    if (age > life || x < -140 || x > designW + 140 || y < -120) {
      alive = false;
    }
  }

  void draw() {
    if (!alive) {
      return;
    }

    float fadeIn = smoothstep(0, 22, age);
    float fadeOut = 1.0 - smoothstep(life - 45, life, age);
    float a = alpha * fadeIn * fadeOut;

    pushMatrix();
    translate(x, y);
    rotate(angle);
    scale(size / 56.0);
    drawLeafShape(a);
    popMatrix();
  }

  void drawLeafShape(float a) {
    noStroke();
    for (int i = 7; i >= 1; i--) {
      float s = i / 7.0;
      fill(255, 255, 250, a * map(i, 7, 1, 0.20, 0.78));
      beginShape();
      vertex(-30 * s, 0);
      bezierVertex(-18 * s, -29 * s, 14 * s, -31 * s, 32 * s, -3 * s);
      bezierVertex(18 * s, 26 * s, -14 * s, 27 * s, -30 * s, 0);
      endShape(CLOSE);
    }

    fill(255, 246, 238, a * 0.18);
    beginShape();
    vertex(-18, -1);
    bezierVertex(-6, -14, 14, -16, 28, -4);
    bezierVertex(14, 8, -4, 10, -18, -1);
    endShape(CLOSE);
  }
}
