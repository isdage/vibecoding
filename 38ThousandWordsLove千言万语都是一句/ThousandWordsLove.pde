ArrayList<FallingWord> words = new ArrayList<FallingWord>();
PImage bg;
PImage preparedBg;
PGraphics glowLayer;

// ===== 流星丛数量 / 密度 / 速度 / 大小 =====
float fallingWordMinSize = 10;
float fallingWordMaxSize = 18; // 碰到输入框后显示出来的文字大小范围
int wordSpawnInterval = 3;     // 流星密度：数值越小，生成越密
int maxWords = 150;            // 流星数量：同屏最多保留多少颗
float fallSpeedMin = 3.0;      // 流星速度：最慢下落速度
float fallSpeedMax = 8.2;      // 流星速度：最快下落速度
float wantedDropChance = 0.30; // “我 / 喜 / 欢 / 你”整体出现比例
float niChanceInWanted = 0.10; // 随机目标字里“你”的比例，越小越难集齐最后一个字

// ===== 背景照片调整参数 =====
String backgroundFile = "background.jpg";
int backgroundDarkAlpha = 0;  // 数值越大，照片越暗，0 表示不加黑色蒙版

// ===== 流星闪烁 / 发光 / 拖尾 =====
float twinkleSpeedMin = 0.035; // 闪烁速度最慢值
float twinkleSpeedMax = 0.075; // 闪烁速度最快值
float targetGlowSize = 24;  // “我 / 喜 / 欢 / 你”的黄色柔光范围
float noiseGlowSize = 10;   // 其他文字的灰色柔光范围
float targetGlowStrength = 1.35; // 黄色星星亮度：数值越大越明显
float noiseGlowStrength = 0.86;  // 灰色星星亮度：数值越小越暗
float meteorTrailMin = 78;  // 流星尾巴最短长度
float meteorTrailMax = 185; // 流星尾巴最长长度
float meteorCoreMin = 2.6;  // 流星亮点最小尺寸
float meteorCoreMax = 8.4;  // 流星亮点最大尺寸
int maxTrailCount = 30;     // 拖尾密度：每个流星保留的轨迹点数量
boolean useAdditiveGlow = true; // true 会让流星在照片上更像发光
float glowScale = 0.5; // blur 光层分辨率，0.5 是 300x400，更流畅
float glowBlurAmount = 4; // 整体 blur 发光强度
float glowLayerAlpha = 185; // blur 光层整体透明度
float hitRevealFadeSpeed = 7; // 被输入框碰到后，文字消失速度

// ===== 输入框调整参数：大小、颜色、输入框里的字大小 =====
float boxW = 240;
float boxH = 50;
float boxRound = 16;
float boxTextSize = 15;
float boxLetterSpacing = 4; // 输入框里面“我喜欢你”的字间距
int boxFillR = 255;
int boxFillG = 255;
int boxFillB = 255;
int boxFillAlpha = 42; // 白色透明框
int boxCursorAlpha = 180;
float boxCursorBlinkSpeed = 0.16; // 输入竖线闪烁速度
int boxTextR = 255;
int boxTextG = 237;
int boxTextB = 205;
float sendButtonSize = 42; // 集齐后右侧发送按钮大小
float sendButtonGap = 12;  // 发送按钮和输入框的距离
int sendButtonFillAlpha = 62;   // 发送按钮浅色圆形背景透明度
int sendButtonArrowAlpha = 230;  // 发送按钮箭头透明度
float sendButtonHoverScale = 1.13; // 鼠标浮到发送按钮上时的放大比例
float sendButtonHoverFloat = 2.5;  // 鼠标浮到发送按钮上时的上浮幅度
float sentBoxBlinkSpeed = 0.09;    // 点击发送后输入框闪动频率
float sentButtonBlinkSpeed = 0.17; // 点击发送后发送键闪动频率
float sentTextBlinkBaseSpeed = 0.31; // 点击发送后“我喜欢你”文字基础闪动频率
float sentFadeSpeed = 5.2;         // 点击发送后整体闪动消失速度，数值越大消失越快

String[] wanted = {"我", "喜", "欢", "你"};
String collected = "";
int guaranteedIndex = 0;
boolean boxLocked = false;
boolean messageSent = false;
float sentFadeAlpha = 255;
float lockedBoxX = 0;
float lockedBoxY = 0;
String[] noise = {
  "春", "风", "月", "夜", "梦", "云", "雨", "花", "海", "星",
  "光", "路", "心", "念", "等", "问", "远", "近", "旧", "新",
  "山", "川", "河", "书", "信", "窗", "灯", "影", "声", "诗",
  "想", "见", "言", "千", "万", "句", "沉", "默", "晴", "雪"
};

PFont font;
int nextIndex = 0;

// ===== 系统自带字体修改位置 =====
// macOS 一般用 Heiti SC；如果没有，会按顺序尝试后面的黑体。
String[] preferredFontNames = {
  "Heiti SC",
  "STHeiti",
  "STHeitiSC-Light",
  "STHeitiSC-Medium",
  "PingFang SC",
  "Microsoft YaHei",
  "SimHei",
  "Noto Sans CJK SC",
  "Source Han Sans SC"
};

void setup() {
  size(600, 800);
  smooth();
  font = loadSketchFont();
  textFont(font);
  bg = loadImage(backgroundFile);
  preparedBg = createPreparedBackground();
  glowLayer = createGraphics(int(width * glowScale), int(height * glowScale));
  noCursor();
}

PFont loadSketchFont() {
  String chosenFont = chooseSystemFont();
  println("Using system font: " + chosenFont);
  return createFont(chosenFont, 28, true);
}

String chooseSystemFont() {
  String[] availableFonts = PFont.list();

  for (int i = 0; i < preferredFontNames.length; i++) {
    for (int j = 0; j < availableFonts.length; j++) {
      if (availableFonts[j].equals(preferredFontNames[i])) {
        return availableFonts[j];
      }
    }
  }

  for (int i = 0; i < preferredFontNames.length; i++) {
    for (int j = 0; j < availableFonts.length; j++) {
      if (availableFonts[j].indexOf(preferredFontNames[i]) >= 0) {
        return availableFonts[j];
      }
    }
  }

  return "Serif";
}

void draw() {
  drawBackgroundPhoto();

  if (frameCount % wordSpawnInterval == 0) {
    addWord();
  }

  for (int i = words.size() - 1; i >= 0; i--) {
    FallingWord w = words.get(i);
    w.update();

    if (hitsInputBox(w)) {
      if (isCurrentNeededLetter(w)) {
        tryCollect(w);
        words.remove(i);
      } else {
        w.bounceFromInputBox(getBoxX(), getBoxY());
      }
    } else if (w.y > height + 50) {
      words.remove(i);
    }
  }

  drawAllMeteors();
  drawAllLetters();

  updateSentFade();
  drawInputBox();
  updateMouseCursor();
}

void updateMouseCursor() {
  if (boxLocked) {
    cursor();
  } else {
    noCursor();
  }
}

void keyPressed() {
  if (key == ' ') {
    restartSketch();
  }
}

void mousePressed() {
  if (boxLocked && !messageSent && hitsSendButton(mouseX, mouseY)) {
    messageSent = true;
    sentFadeAlpha = 255;
  }
}

void restartSketch() {
  words.clear();
  collected = "";
  nextIndex = 0;
  guaranteedIndex = 0;
  boxLocked = false;
  messageSent = false;
  sentFadeAlpha = 255;
}

void addWord() {
  if (words.size() >= maxWords) {
    words.remove(0);
  }

  boolean makeWanted = random(1) < wantedDropChance;
  String letter;

  if (guaranteedIndex < wanted.length) {
    letter = wanted[guaranteedIndex];
    guaranteedIndex++;
  } else {
    letter = makeWanted ? pickWantedLetter() : noise[int(random(noise.length))];
  }

  words.add(new FallingWord(letter));
}

String pickWantedLetter() {
  if (random(1) < niChanceInWanted) {
    return "你";
  }

  String[] easierWanted = {"我", "喜", "欢"};
  return easierWanted[int(random(easierWanted.length))];
}

boolean hitsInputBox(FallingWord w) {
  if (messageSent) {
    return false;
  }

  float bx = getBoxX();
  float by = getBoxY();
  return w.bounceCooldown == 0 &&
    w.x > bx - boxW / 2 && w.x < bx + boxW / 2 &&
    w.y > by - boxH / 2 && w.y < by + boxH / 2;
}

boolean isCurrentNeededLetter(FallingWord w) {
  return nextIndex < wanted.length && w.letter.equals(wanted[nextIndex]);
}

void tryCollect(FallingWord w) {
  if (nextIndex < wanted.length && w.letter.equals(wanted[nextIndex])) {
    float bxBeforeCollect = getBoxX();
    float byBeforeCollect = getBoxY();
    collected += w.letter;
    nextIndex++;

    if (nextIndex == wanted.length) {
      lockInputBoxPosition(bxBeforeCollect, byBeforeCollect);
    }
  }
}

void lockInputBoxPosition(float bx, float by) {
  float rightSpace = sendButtonGap + sendButtonSize;
  lockedBoxX = constrain(bx, boxW / 2 + 16, width - boxW / 2 - 16 - rightSpace);
  lockedBoxY = constrain(by, 80, height - 70);
  boxLocked = true;
}

void drawInputBox() {
  float bx = getBoxX();
  float by = getBoxY();
  float boxAlphaScale = getSentBoxAlphaScale();
  float buttonAlphaScale = getSentButtonAlphaScale();

  if (messageSent && sentFadeAlpha <= 0) {
    return;
  }

  rectMode(CENTER);
  noStroke();

  fill(boxFillR, boxFillG, boxFillB, boxFillAlpha * boxAlphaScale);
  rect(bx, by, boxW, boxH, boxRound);

  textFont(font);
  textAlign(CENTER, CENTER);
  textSize(boxTextSize);
  String displayText = formatCollected();
  if (messageSent) {
    drawSpacedTextWithBlink(displayText, bx, by - 1, boxLetterSpacing);
  } else {
    fill(boxTextR, boxTextG, boxTextB);
    drawSpacedText(displayText, bx, by - 1, boxLetterSpacing);
  }

  if (nextIndex < wanted.length) {
    float cursorBlink = max(0, sin(frameCount * boxCursorBlinkSpeed));
    float cursorX = bx + getSpacedTextWidth(displayText, boxLetterSpacing) / 2 + 9;
    stroke(255, 255, 255, boxCursorAlpha * cursorBlink * boxAlphaScale);
    strokeWeight(1.2);
    line(cursorX, by - boxH * 0.33, cursorX, by + boxH * 0.33);
  } else {
    drawSendButton(bx, by, buttonAlphaScale);
  }
}

float getSentBoxAlphaScale() {
  if (!messageSent) {
    return 1;
  }

  return getSentFadeScale() * (0.46 + 0.54 * abs(sin(frameCount * sentBoxBlinkSpeed)));
}

float getSentButtonAlphaScale() {
  if (!messageSent) {
    return 1;
  }

  return getSentFadeScale() * (0.34 + 0.66 * abs(sin(frameCount * sentButtonBlinkSpeed + 1.1)));
}

float getSentFadeScale() {
  if (!messageSent) {
    return 1;
  }

  return constrain(sentFadeAlpha / 255.0, 0, 1);
}

void updateSentFade() {
  if (messageSent && sentFadeAlpha > 0) {
    sentFadeAlpha = max(0, sentFadeAlpha - sentFadeSpeed);
  }
}

float getBoxX() {
  if (boxLocked) {
    return lockedBoxX;
  }

  float rightSpace = nextIndex >= wanted.length ? sendButtonGap + sendButtonSize : 0;
  return constrain(mouseX, boxW / 2 + 16, width - boxW / 2 - 16 - rightSpace);
}

float getBoxY() {
  if (boxLocked) {
    return lockedBoxY;
  }

  return constrain(mouseY, 80, height - 70);
}

String formatCollected() {
  return collected;
}

void drawSendButton(float bx, float by, float alphaScale) {
  float buttonX = bx + boxW / 2 + sendButtonGap + sendButtonSize / 2;
  boolean hovering = !messageSent && hitsSendButton(mouseX, mouseY);
  float hoverPulse = 0.5 + 0.5 * sin(frameCount * 0.12);
  float buttonSize = hovering ? sendButtonSize * (sendButtonHoverScale + hoverPulse * 0.025) : sendButtonSize;
  float buttonY = hovering ? by - sendButtonHoverFloat - hoverPulse * 0.8 : by;
  float arrowTop = buttonY - buttonSize * 0.22;
  float arrowBottom = buttonY + buttonSize * 0.20;
  float arrowHalf = buttonSize * 0.13;

  noStroke();
  fill(255, 255, 255, (hovering ? min(120, sendButtonFillAlpha + 32) : sendButtonFillAlpha) * alphaScale);
  ellipse(buttonX, buttonY, buttonSize, buttonSize);

  stroke(255, 255, 255, sendButtonArrowAlpha * alphaScale);
  strokeWeight(hovering ? 2.5 : 2.2);
  strokeCap(ROUND);
  line(buttonX, arrowBottom, buttonX, arrowTop);
  line(buttonX, arrowTop, buttonX - arrowHalf, arrowTop + arrowHalf);
  line(buttonX, arrowTop, buttonX + arrowHalf, arrowTop + arrowHalf);
  noStroke();
}

boolean hitsSendButton(float mx, float my) {
  float bx = getBoxX();
  float by = getBoxY();
  float buttonX = bx + boxW / 2 + sendButtonGap + sendButtonSize / 2;
  return dist(mx, my, buttonX, by) <= sendButtonSize * sendButtonHoverScale / 2;
}

float getSpacedTextWidth(String content, float spacing) {
  if (content.length() == 0) {
    return 0;
  }

  float total = 0;
  for (int i = 0; i < content.length(); i++) {
    total += textWidth("" + content.charAt(i));
  }
  return total + spacing * (content.length() - 1);
}

void drawSpacedText(String content, float centerX, float centerY, float spacing) {
  if (content.length() == 0) {
    return;
  }

  float totalW = getSpacedTextWidth(content, spacing);
  float cursorX = centerX - totalW / 2;
  for (int i = 0; i < content.length(); i++) {
    String ch = "" + content.charAt(i);
    float charW = textWidth(ch);
    text(ch, cursorX + charW / 2, centerY);
    cursorX += charW + spacing;
  }
}

void drawSpacedTextWithBlink(String content, float centerX, float centerY, float spacing) {
  if (content.length() == 0) {
    return;
  }

  float totalW = getSpacedTextWidth(content, spacing);
  float cursorX = centerX - totalW / 2;
  for (int i = 0; i < content.length(); i++) {
    String ch = "" + content.charAt(i);
    float charW = textWidth(ch);
    float blinkSpeed = sentTextBlinkBaseSpeed + i * 0.035;
    float blinkAlpha = (120 + 135 * abs(sin(frameCount * blinkSpeed + i * 1.35))) * getSentFadeScale();

    fill(boxTextR, boxTextG, boxTextB, blinkAlpha);
    text(ch, cursorX + charW / 2, centerY);
    cursorX += charW + spacing;
  }
}

void drawBackgroundPhoto() {
  if (preparedBg != null) {
    imageMode(CORNER);
    image(preparedBg, 0, 0);
    return;
  }

  rectMode(CORNER);
  background(12, 15, 24);

  if (bg != null) {
    float bgRatio = float(bg.width) / bg.height;
    float screenRatio = float(width) / height;
    float drawW;
    float drawH;
    float drawX;
    float drawY;

    if (bgRatio > screenRatio) {
      drawH = height;
      drawW = height * bgRatio;
      drawX = (width - drawW) / 2;
      drawY = 0;
    } else {
      drawW = width;
      drawH = width / bgRatio;
      drawX = 0;
      drawY = (height - drawH) / 2;
    }

    image(bg, drawX, drawY, drawW, drawH);
  }

  noStroke();
  fill(0, backgroundDarkAlpha);
  rect(0, 0, width, height);
}

PImage createPreparedBackground() {
  PGraphics pg = createGraphics(width, height);

  pg.beginDraw();
  pg.background(12, 15, 24);

  if (bg != null) {
    float bgRatio = float(bg.width) / bg.height;
    float screenRatio = float(width) / height;
    float drawW;
    float drawH;
    float drawX;
    float drawY;

    if (bgRatio > screenRatio) {
      drawH = height;
      drawW = height * bgRatio;
      drawX = (width - drawW) / 2;
      drawY = 0;
    } else {
      drawW = width;
      drawH = width / bgRatio;
      drawX = 0;
      drawY = (height - drawH) / 2;
    }

    pg.image(bg, drawX, drawY, drawW, drawH);
  }

  pg.noStroke();
  pg.fill(0, backgroundDarkAlpha);
  pg.rect(0, 0, width, height);
  pg.endDraw();

  return pg.get();
}

void drawAllMeteors() {
  renderGlowLayer();

  if (useAdditiveGlow) {
    blendMode(ADD);
  }
  tint(255, glowLayerAlpha);
  imageMode(CORNER);
  image(glowLayer, 0, 0, width, height);
  noTint();

  if (useAdditiveGlow) {
    blendMode(BLEND);
  }

  for (FallingWord w : words) {
    w.showSharpMeteor();
  }
}

void renderGlowLayer() {
  glowLayer.beginDraw();
  glowLayer.clear();
  glowLayer.pushMatrix();
  glowLayer.scale(glowScale);
  glowLayer.noFill();
  glowLayer.strokeCap(ROUND);
  glowLayer.strokeJoin(ROUND);

  for (FallingWord w : words) {
    w.showBlurGlow(glowLayer);
  }

  glowLayer.popMatrix();
  glowLayer.endDraw();
  glowLayer.filter(BLUR, glowBlurAmount);
}

void drawAllLetters() {
  for (FallingWord w : words) {
    w.showLetterIfVisible();
  }
}

class FallingWord {
  String letter;
  float x;
  float y;
  float speed;
  float baseSpeed;
  float drift;
  float size;
  float twinklePhase;
  float twinkleSpeed;
  float twinkle;
  float trailLength;
  float coreSize;
  float meteorAngle;
  int bounceCooldown;
  boolean bouncing;
  float hitRevealAlpha;
  boolean target;
  ArrayList<PVector> trail = new ArrayList<PVector>();

  FallingWord(String letter) {
    this.letter = letter;
    x = random(30, width - 30);
    y = random(-120, -20);
    setupMotion();
  }

  void setupMotion() {
    baseSpeed = random(fallSpeedMin, fallSpeedMax);
    speed = baseSpeed;
    drift = random(-0.18, 0.18);
    size = random(fallingWordMinSize, fallingWordMaxSize);
    twinklePhase = random(TWO_PI);
    twinkleSpeed = random(twinkleSpeedMin, twinkleSpeedMax);
    trailLength = random(meteorTrailMin, meteorTrailMax);
    coreSize = random(meteorCoreMin, meteorCoreMax);
    meteorAngle = random(-0.08, 0.08);
    target = isWanted(letter);
  }

  void update() {
    if (bounceCooldown > 0) {
      bounceCooldown--;
    }

    if (bouncing) {
      speed += 0.13;
      if (speed >= baseSpeed) {
        speed = baseSpeed;
        bouncing = false;
        drift *= 0.35;
      }
    }

    if (hitRevealAlpha > 0) {
      hitRevealAlpha = max(0, hitRevealAlpha - hitRevealFadeSpeed);
    }

    y += speed;
    x += drift;
    twinkle = 0.55 + 0.45 * sin(frameCount * twinkleSpeed + twinklePhase);

    trail.add(new PVector(x, y));
    int dynamicMaxTrail = getDynamicMaxTrail();
    while (trail.size() > dynamicMaxTrail) {
      trail.remove(0);
    }
  }

  int getDynamicMaxTrail() {
    float motion = constrain(abs(speed) / fallSpeedMax, 0.0, 1.0);
    return max(8, int(lerp(maxTrailCount * 0.45, maxTrailCount, motion)));
  }

  void bounceFromInputBox(float bx, float by) {
    float side = x < bx ? -1 : 1;
    if (abs(x - bx) < 6) {
      side = random(1) < 0.5 ? -1 : 1;
    }

    bouncing = true;
    hitRevealAlpha = 255;
    bounceCooldown = 22;
    x += side * 8;
    y = by - boxH / 2 - coreSize - 4;
    drift = side * random(0.85, 1.9);
    speed = -random(1.4, 3.0);
    twinklePhase += PI * 0.35;
  }

  void showBlurGlow(PGraphics layer) {
    if (target) {
      drawBlurTrail(layer, 255, 225, 120, targetGlowStrength, targetGlowSize);
      if (!isTextVisible()) {
        drawBlurHead(layer, 255, 225, 120, targetGlowStrength, targetGlowSize);
      }
    } else {
      drawBlurTrail(layer, 220, 225, 235, noiseGlowStrength, noiseGlowSize);
      if (!isTextVisible()) {
        drawBlurHead(layer, 220, 225, 235, noiseGlowStrength, noiseGlowSize);
      }
    }
  }

  void showSharpMeteor() {
    if (target) {
      drawSharpTrail(255, 232, 150, 1.12);
      if (!isTextVisible()) {
        drawSharpHead(255, 248, 220, 1.16);
      }
    } else {
      drawSharpTrail(230, 235, 245, 0.42);
      if (!isTextVisible()) {
        drawSharpHead(255, 255, 250, 0.34);
      }
    }
  }

  void showLetterIfVisible() {
    if (isTextVisible()) {
      pushMatrix();
      translate(x, y);
      textAlign(CENTER, CENTER);
      textFont(font);
      noStroke();
      textSize(size);
      drawLetter();
      popMatrix();
    }
  }

  boolean isTextVisible() {
    return hitRevealAlpha > 0;
  }

  void drawLetter() {
    float revealAlpha = hitRevealAlpha;

    if (target) {
      fill(255, 232, 153, min(revealAlpha, 205 + 50 * twinkle));
    } else {
      fill(230, 235, 245, min(revealAlpha, 145 + 90 * twinkle));
    }

    text(letter, 0, 0);
  }

  void drawSharpHead(int r, int g, int b, float strength) {
    float vx = drift;
    float vy = speed;
    float vLen = max(0.001, sqrt(vx * vx + vy * vy));
    float tailX = -vx / vLen;
    float tailY = -vy / vLen;
    float pulse = 0.75 + 0.25 * twinkle;

    strokeCap(ROUND);
    stroke(r, g, b, 48 * strength * pulse);
    strokeWeight(2.2 * strength);
    line(x + tailX * 10, y + tailY * 10, x, y);

    noStroke();
    fill(255, 255, 250, 150 * strength + 55 * twinkle);
    ellipse(x, y, coreSize * 0.95, coreSize * 0.95);
  }

  void drawSharpTrail(int r, int g, int b, float strength) {
    if (trail.size() < 2) {
      return;
    }

    noFill();
    strokeCap(ROUND);
    strokeJoin(ROUND);

    for (int pass = 0; pass < 2; pass++) {
      for (int i = 1; i < trail.size(); i++) {
        float t = i / float(trail.size() - 1);
        float ease = t * t;
        PVector a = trail.get(i - 1);
        PVector c = trail.get(i);
        float sw;
        float alpha;

        if (pass == 0) {
          sw = lerp(1.8, 5.5, ease) * strength;
          alpha = 28 * ease * twinkle;
        } else {
          sw = lerp(0.7, 1.6, ease) * strength;
          alpha = 95 * ease * twinkle;
        }

        stroke(r, g, b, alpha);
        strokeWeight(sw);
        line(a.x, a.y, c.x, c.y);
      }
    }

    noStroke();
  }

  void drawBlurTrail(PGraphics layer, int r, int g, int b, float strength, float glowSize) {
    if (trail.size() < 2) {
      return;
    }

    for (int pass = 0; pass < 3; pass++) {
      for (int i = 1; i < trail.size(); i++) {
        float t = i / float(trail.size() - 1);
        float ease = t * t;
        PVector a = trail.get(i - 1);
        PVector c = trail.get(i);
        float sw;
        float alpha;

        if (pass == 0) {
          sw = lerp(glowSize * 0.35, glowSize * 1.08, ease) * strength;
          alpha = 22 * ease * twinkle;
        } else if (pass == 1) {
          sw = lerp(glowSize * 0.14, glowSize * 0.42, ease) * strength;
          alpha = 45 * ease * twinkle;
        } else {
          sw = lerp(glowSize * 0.05, glowSize * 0.13, ease) * strength;
          alpha = 92 * ease * twinkle;
        }

        layer.stroke(r, g, b, alpha);
        layer.strokeWeight(sw);
        layer.line(a.x, a.y, c.x, c.y);
      }
    }
  }

  void drawBlurHead(PGraphics layer, int r, int g, int b, float strength, float glowSize) {
    float vx = drift;
    float vy = speed;
    float vLen = max(0.001, sqrt(vx * vx + vy * vy));
    float tailX = -vx / vLen;
    float tailY = -vy / vLen;
    float pulse = 0.75 + 0.25 * twinkle;

    layer.strokeCap(ROUND);
    layer.stroke(r, g, b, 115 * strength * pulse);
    layer.strokeWeight(max(1, glowSize * 0.22 * strength));
    layer.line(x + tailX * glowSize * 0.82, y + tailY * glowSize * 0.82, x, y);

    layer.noStroke();
    layer.fill(r, g, b, 70 * strength * pulse);
    layer.ellipse(x, y, coreSize + glowSize * 0.18, coreSize + glowSize * 0.18);
  }
}

boolean isWanted(String letter) {
  for (int i = 0; i < wanted.length; i++) {
    if (letter.equals(wanted[i])) {
      return true;
    }
  }
  return false;
}
