boolean lampOn = false;
boolean draggingSwitch = false;
boolean switchWasPulled = false;

// 原始设计稿尺寸：下面所有位置数字都按 840x1080 来写，再整体缩放到 600x800。
float designW = 840;
float designH = 1080;
float viewScale = 1;
float viewOffsetX = 0;
float viewOffsetY = 0;

// 背景小星星：开灯后才会出现。
int starCount = 40;
float[] starX = new float[starCount];
float[] starY = new float[starCount];
float[] starSize = new float[starCount];
float[] starTwinkle = new float[starCount];

// 灯整体的中心位置：改 shadeX 会让灯罩、灯杆、底座一起左右移动。
float shadeX = 420;
// 灯罩主体的顶部位置：数值越大，灯罩越往下。
float shadeY = 235;

// 开关拉绳的左右位置：数值越大，整条拉绳和吊坠越往右。
float switchX = 550;
// 开关自然垂下的位置：数值越大，吊坠初始位置越低。
float switchRestY = 595;
float switchY = switchRestY;
// 开关最多能被拉到的位置：数值越大，可以向下拉得越远。
float switchPullLimit = 610;

// 顶部椭圆的中心渐变颜色。
color blueTopCenter = #006bed;
color blueTopOuter = #77d2fe;
// 灯罩和灯杆的线性渐变颜色。
color blueBodyTop = #7dd9ff;
color blueBodyBottom = #dff4ff;
// 灯杆单独的线性渐变颜色：上方颜色、下方颜色。
color bluePoleTop = #ccf0ff;
color bluePoleBottom = #80d8ff;
// 灯罩底部椭圆分成上下两个部分，方便单独调整层级和颜色。
color blueShadeBottomEllipseTop = #c8eeff;
color blueShadeBottomEllipseBottom = #dff4ff;
// 底座椭圆的中心渐变颜色。
color blueBaseOuter = #baebff;
color blueBaseInner = #e0f1ff;

void setup() {
  size(600, 800);
  smooth(8);
  viewScale = min(width / designW, height / designH);
  viewOffsetX = (width - designW * viewScale) / 2.0;
  viewOffsetY = (height - designH * viewScale) / 2.0;
  setupStars();
}

void draw() {
  background(248, 252, 253);
  pushMatrix();
  translate(viewOffsetX, viewOffsetY);
  scale(viewScale);
  drawPaper();
  updateSwitch();
  drawLightAura();
  drawStars();
  drawStand();
  drawShade();
  drawTopOpening();
  drawPullSwitch();
  popMatrix();
}

void mousePressed() {
  if (dist(designMouseX(), designMouseY(), switchX, switchY) < 32) {
    draggingSwitch = true;
    switchWasPulled = false;
  }
}

void mouseDragged() {
  if (draggingSwitch) {
    switchY = constrain(designMouseY(), switchRestY, switchPullLimit);
    if (!switchWasPulled && switchY >= switchPullLimit - 2) {
      lampOn = !lampOn;
      switchWasPulled = true;
    }
  }
}

void mouseReleased() {
  draggingSwitch = false;
}

void updateSwitch() {
  if (!draggingSwitch) {
    switchY = lerp(switchY, switchRestY, 0.18);
  }
}

void drawPaper() {
  noStroke();
  fill(242, 248, 250);
  // 背景纸张的位置和大小：rect(x, y, 宽, 高)。
  rect(48, 34, designW - 96, designH - 68);
}

void drawLightAura() {
  if (!lampOn) {
    return;
  }

  noStroke();
  for (int i = 300; i > 0; i--) {
    float alpha = map(i, 260, 0, 0, 20);
    fill(255, 224, 76, alpha);
    ellipse(shadeX, shadeY + 210, i * 3.0, i * 3.0);
  }
}

void setupStars() {
  randomSeed(12);
  for (int i = 0; i < starCount; i++) {
    // 星星限制在背景纸张里面，避开画布边缘。
    starX[i] = random(95, designW - 95);
    starY[i] = random(95, designH - 95);
    starSize[i] = random(3, 9);
    starTwinkle[i] = random(TWO_PI);
  }
}

void drawStars() {
  if (!lampOn) {
    return;
  }

  noStroke();
  for (int i = 0; i < starCount; i++) {
    float twinkle = 0.65 + 0.35 * sin(frameCount * 0.06 + starTwinkle[i]);
    float s = starSize[i] * twinkle;

    // 星星主体：一横一竖组成小星光。
    fill(255, 255, 255, 200);
    ellipse(starX[i], starY[i], s, s);
    rect(starX[i] - s * 1.8, starY[i] - s * 0.18, s * 3.6, s * 0.36);
    rect(starX[i] - s * 0.18, starY[i] - s * 1.8, s * 0.36, s * 3.6);
  }
}

void drawBaseShadow() {
  noStroke();
  for (int i = 75; i > 0; i--) {
    float alpha = map(i, 75, 0, 0, 22);
    fill(lampOn ? color(245, 190, 70, alpha) : color(72, 194, 232, alpha));
    ellipse(shadeX, 803, i * 4.2, i * 1.0);
  }
}

void drawStand() {
  color top = lampOn ? color(255, 251, 218) : bluePoleTop;
  color bottom = lampOn ? color(255, 218, 76) : bluePoleBottom;
  color baseOuter = lampOn ? color(255, 214, 86) : blueBaseOuter;
  color baseInner = lampOn ? color(255, 251, 218) : blueBaseInner;

  noStroke();
  // 底座先画，所以会在灯杆后面；850 是上下位置，200 是宽度，76 是高度。
  drawRadialEllipse(shadeX, 850, 200, 76, baseInner, baseOuter, 80);

  // 灯杆：560 是灯杆顶部 y 坐标，280 是灯杆长度，25 是灯杆宽度。
  for (int i = 0; i < 280; i++) {
    float t = i / 314.0;
    fill(lerpColor(top, bottom, t));
    rect(shadeX - 13, 560 + i, 25, 1.4);
  }
}

void drawShade() {
  color bodyTop = lampOn ? color(255, 220, 75) : blueBodyTop;
  color bodyBottom = lampOn ? color(255, 251, 218) : blueBodyBottom;
  color ellipseTop = lampOn ? color(255, 244, 166) : blueShadeBottomEllipseTop;
  color ellipseBottom = lampOn ? color(255, 251, 218) : blueShadeBottomEllipseBottom;

  noStroke();

  // 灯罩下面的椭圆上半部分：先画，位置在灯体后面。
  drawHalfEllipse(shadeX, shadeY + 280, 365, 120, ellipseTop, true);

  // 灯体正梯形：280 是高度，顶部宽 200，底部宽 365。
  for (int i = 0; i < 280; i++) {
    float t = i / 279.0;
    float y = shadeY + i;
    float halfW = lerp(100, 182.5, t);
    fill(lerpColor(bodyTop, bodyBottom, t));
    rect(shadeX - halfW, y, halfW * 2.0, 1.4);
  }

  // 灯罩下面的椭圆下半部分：后画，形成前景圆弧。
  drawHalfEllipse(shadeX, shadeY + 279, 365, 120, ellipseBottom, false);
}

void drawTopOpening() {
  color center = lampOn ? color(229, 141, 26) : blueTopCenter;
  color outer = lampOn ? color(255, 218, 76) : blueTopOuter;
  // 顶部椭圆：230 是上下位置，200 是宽度，75 是高度。
  drawRadialEllipse(shadeX, 235, 200, 75, center, outer, 72);
}

void drawPullSwitch() {
  color cord = lampOn ? color(241, 196, 67, 115) : color(73, 196, 232, 105);
  color knobTop = lampOn ? color(255, 224, 86) : color(58, 195, 236);
  color knobBottom = lampOn ? color(255, 251, 225) : color(228, 250, 255);

  stroke(cord);
  strokeWeight(2);
  // 拉绳位置修改入口：
  // switchX 控制整条拉绳左右位置；
  // shadeY + 316 控制拉绳顶部连接点的上下位置；
  // switchY - 14 控制拉绳下端连接到吊坠的位置。
  line(switchX, shadeY + 316, switchX, switchY - 14);

  noStroke();
  // 开关小吊坠：switchX 控制左右，switchY 控制上下，下面四个点决定梯形吊坠的形状。
  beginShape();
  fill(knobTop);
  vertex(switchX - 9, switchY - 13);
  vertex(switchX + 9, switchY - 13);
  fill(knobBottom);
  vertex(switchX + 13, switchY + 14);
  vertex(switchX - 13, switchY + 14);
  endShape(CLOSE);

  fill(255, 115);
  ellipse(switchX - 4, switchY - 5, 9, 20);
}

float smoothstep(float edge0, float edge1, float x) {
  float t = constrain((x - edge0) / (edge1 - edge0), 0, 1);
  return t * t * (3 - 2 * t);
}

void drawRadialEllipse(float x, float y, float w, float h, color centerColor, color outerColor, int steps) {
  noStroke();
  // 中心渐变椭圆：从外圈画到中心，外圈是 outerColor，中心是 centerColor。
  for (int i = steps; i >= 1; i--) {
    float t = i / float(steps);
    fill(lerpColor(centerColor, outerColor, t));
    ellipse(x, y, w * t, h * t);
  }
}

void drawHalfEllipse(float x, float y, float w, float h, color c, boolean topHalf) {
  fill(c);
  beginShape();
  if (topHalf) {
    // 椭圆上半部分：从左边画到右边。
    for (float a = PI; a <= TWO_PI; a += 0.04) {
      vertex(x + cos(a) * w / 2.0, y + sin(a) * h / 2.0);
    }
  } else {
    // 椭圆下半部分：从右边画到左边。
    for (float a = 0; a <= PI; a += 0.04) {
      vertex(x + cos(a) * w / 2.0, y + sin(a) * h / 2.0);
    }
  }
  endShape(CLOSE);
}

float designMouseX() {
  return (mouseX - viewOffsetX) / viewScale;
}

float designMouseY() {
  return (mouseY - viewOffsetY) / viewScale;
}
