ArrayList<SentenceLine> lines = new ArrayList<SentenceLine>();
ArrayList<EndingLine> endingLines = new ArrayList<EndingLine>();
PFont songti;
PImage bg;
boolean dispersing = false;
float endingAlpha = 0;
float textSizeValue = 13;
float lineGap = 22;
float paragraphGap = 39;
float textCenterX = 300;
float topY = 200;

// ===== 触发前雨效果调整区 =====
// 调整这里：雨滴数量。数值越大，雨越密。
int rainCount = 46;

// 调整这里：雨的倾斜方向。负数向左斜，正数向右斜。
float rainSlant = -0.34;

// 调整这里：雨下落速度。
float rainSpeed = 9.0;

// 调整这里：雨滴长度范围。
float rainLengthMin = 46;
float rainLengthMax = 126;

// 调整这里：触发“我很想你”后，雨停下来的速度。数值越大，天晴越快。
float rainFadeOutSpeed = 0.035;

// 调整这里：雨滴透明度。数值越大，雨越明显。
float rainAlphaMax = 105;

// 调整这里：雨滴打在画面上的涟漪数量。
int rainRippleCount = 38;

// 调整这里：雨滴大概落到画面的高度范围。
float rainHitYMin = 120;
float rainHitYMax = 650;

RainDrop[] rainDrops;
RainRipple[] rainRipples;
float rainVisibility = 1;
float rainWind = 0;

// 调整这里：最后三行“雨停了 / 天晴了 / 我来找你”的横向中心位置。
float endingCenterX = 300;

// 调整这里：最后三行第一行的纵向位置。数值越大，越往下。
float endingTopY = 552;

// 调整这里：最后三行自己的行距。
float endingLineGap = 22;

// 调整这里：文字飞散消散的速度。数值越小，散开和消失越慢。
float disperseSpeed = 0.0045;

// 调整这里：文字左右飞散范围。数值越大，字会向左右散得越远。
float scatterXRange = 165;

// 调整这里：文字向上飞散范围。数值越大，字会更容易向上飘开。
float scatterUpRange = 165;

// 调整这里：文字向下掉落范围。数值越大，字会向下掉得越远。
float scatterDownRange = 180;

// 调整这里：同一句里面，越靠边的字额外散开的程度。
float characterSpread = 9.0;

// 调整这里：飞散时文字模糊程度。数值越大，消散越雾。
float blurStrength = 4.2;

// 调整这里：文字飞散到什么程度后才开始明显变透明。数值越大，文字保留越久。
float fadeStart = 0.42;

// 调整这里：文字淡出的缓慢程度。数值越大，前面淡得越慢，后面才消失。
float fadeSlowness = 1.9;

// 调整这里：文字彻底消失后，流星落下和反弹持续多久。数值越大，停留越久。
float starDuration = 2;

// 调整这里：有多少字会变成流星。0.30 表示大约 30% 的字会变成流星。
float starChance = 0.30;

// 调整这里：流星星点的大小范围。
float starMinSize = 2.0;
float starMaxSize = 5.2;

// 调整这里：流星落下时左右飘移的范围。
float meteorDriftRange = 50;

// 调整这里：流星下落的随机重力差异。数值越大，每颗落下的节奏越不一样。
float meteorGravityRandom = 3;

// 调整这里：流星落到画面底部附近的位置。
float meteorGroundY = 745;

// 调整这里：流星落地后反弹高度。
float meteorBounceHeight = 38;

// 调整这里：流星落地后反弹几下。
float meteorBounceCount = 3.2;

// 调整这里：流星尾巴长度。
float meteorTailLength = 1;

// 调整这里：流星最亮时的透明度。数值越大，流星越亮。
float starAlphaMax = 150;

// 调整这里：流星落地后保持闪烁的透明度。数值越大，地上的星星越亮。
float groundedStarAlpha = 58;

// 调整这里：流星落地后的低频闪烁速度。数值越小，闪得越慢。
float groundedTwinkleSpeed = 0.035;

// 调整这里：流星落地后的闪烁幅度。数值越大，明暗变化越明显。
float groundedTwinkleStrength = 0.38;

// 调整这里：每个字开始飞散的随机延迟。数值越大，散开越有先后层次。
float scatterDelayMax = 0.48;

// 调整这里：每个字旋转的幅度。数值越大，散开时越凌乱。
float rotationRange = 0.5;

// 调整这里：鼠标悬停在普通句子上时，句子变灰变模糊的速度。
float hoverBlurInSpeed = 0.16;

// 调整这里：鼠标悬停时普通句子的模糊强度。数值越大，越模糊。
float hoverBlurStrength = 2.2;

// 调整这里：鼠标悬停时普通句子的灰度。数值越大，颜色越浅。
float hoverGrayValue = 118;

// 调整这里：最后三行什么时候开始出现。
// 1.0 表示文字消失、流星刚开始时出现；数值越大，出现越晚。
float endingAppearAtDisperse = 1.5;

// 调整这里：最后三行在开始出现后慢慢浮现的速度。数值越大，出现越快。
float endingFadeInSpeed = 0.01;

// 调整这里：最后三行出现时像星星一样闪烁的速度。数值越大，闪得越快。
float endingTwinkleSpeed = 0.3;

// 调整这里：最后三行出现时闪烁的强度。数值越大，明暗变化越明显。
float endingTwinkleStrength = 0.75;

// 调整这里：其他文字消散末段慢慢放大的程度。1.0 是原大小。
float disperseEndScale = 1.22;

String[][] paragraphs = {
  {
    "那天，你说你有很多话想对我讲"
  },
  {
    "后来雨下得很大",
    "你走了"
  },
  {
    "结果转眼雨过天晴了",
    "我在窗外看着你离开的路很久"
  },
  {
    "有些话并不是忘了",
    "只是每次想起",
    "都要稍微停一下"
  },
  {
    "“我很想你”"
  }
};

String[] endingParagraph = {
  "雨停了",
  "天晴了",
  "我来找你"
};

void setup() {
  size(600, 800);
  smooth(4);
  bg = loadImage("background.jpg");
  bg.resize(width, height);
  songti = createFont(sketchPath("经典宋体简.ttf"), textSizeValue, true);
  textFont(songti);
  textSize(textSizeValue);
  textAlign(CENTER, BASELINE);
  resetSketch();
}

void draw() {
  image(bg, 0, 0);

  for (int i = 0; i < lines.size(); i++) {
    if (lines.get(i).isLoveLine && lines.get(i).isMouseOver()) {
      dispersing = true;
    }
  }

  updateAndDrawRain();

  for (int i = 0; i < lines.size(); i++) {
    lines.get(i).update();
    lines.get(i).display();
  }

  if (starPhaseStarted()) {
    endingAlpha = lerp(endingAlpha, 255, endingFadeInSpeed);
  }

  for (int i = 0; i < endingLines.size(); i++) {
    endingLines.get(i).display(endingAlpha);
  }
}

void keyPressed() {
  if (key == 'r' || key == 'R') {
    resetSketch();
  }
}

void resetSketch() {
  lines.clear();
  endingLines.clear();
  dispersing = false;
  endingAlpha = 0;
  rainVisibility = 1;
  setupRain();

  textFont(songti);
  textSize(textSizeValue);
  textAlign(CENTER, BASELINE);

  float y = topY;
  for (int i = 0; i < paragraphs.length; i++) {
    y = addParagraph(paragraphs[i], y);
  }

  addEndingParagraph(endingParagraph, y);
}

float addParagraph(String[] paragraphLines, float y) {
  for (int i = 0; i < paragraphLines.length; i++) {
    lines.add(new SentenceLine(paragraphLines[i], textCenterX, y));
    y += lineGap;
  }

  return y - lineGap + paragraphGap;
}

void addEndingParagraph(String[] paragraphLines, float y) {
  y = endingTopY;
  for (int i = 0; i < paragraphLines.length; i++) {
    endingLines.add(new EndingLine(paragraphLines[i], endingCenterX, y));
    y += endingLineGap;
  }
}

void setupRain() {
  rainDrops = new RainDrop[rainCount];
  rainRipples = new RainRipple[rainRippleCount];

  for (int i = 0; i < rainDrops.length; i++) {
    rainDrops[i] = new RainDrop();
    rainDrops[i].reset(true);
  }

  for (int i = 0; i < rainRipples.length; i++) {
    rainRipples[i] = new RainRipple();
  }
}

void updateAndDrawRain() {
  float targetVisibility = dispersing ? 0 : 1;
  rainVisibility = lerp(rainVisibility, targetVisibility, rainFadeOutSpeed);
  rainWind = sin(frameCount * 0.012) * 0.68 + sin(frameCount * 0.031) * 0.22;

  if (rainVisibility < 0.01) {
    return;
  }

  for (int i = 0; i < rainRipples.length; i++) {
    rainRipples[i].update();
    rainRipples[i].display();
  }

  for (int i = 0; i < rainDrops.length; i++) {
    rainDrops[i].update();
    rainDrops[i].display();
  }
}

void spawnRainRipple(float x, float y, float size) {
  for (int i = 0; i < rainRipples.length; i++) {
    if (!rainRipples[i].alive) {
      rainRipples[i].reset(x, y, size);
      return;
    }
  }
}

boolean starPhaseStarted() {
  for (int i = 0; i < lines.size(); i++) {
    if (!lines.get(i).isLoveLine && lines.get(i).disperse > endingAppearAtDisperse) {
      return true;
    }
  }

  return false;
}

float smoothstep(float edge0, float edge1, float value) {
  float t = constrain((value - edge0) / (edge1 - edge0), 0, 1);
  return t * t * (3 - 2 * t);
}

class RainDrop {
  float x;
  float y;
  float hitY;
  float lengthValue;
  float speedValue;
  float alphaValue;
  float weightValue;

  void reset(boolean anywhere) {
    x = random(-90, width + 140);
    y = anywhere ? random(-height, height) : random(-180, -20);
    hitY = random(rainHitYMin, rainHitYMax);
    lengthValue = random(rainLengthMin, rainLengthMax);
    speedValue = random(rainSpeed * 0.66, rainSpeed * 1.28);
    alphaValue = random(rainAlphaMax * 0.55, rainAlphaMax);
    weightValue = random(0.8, 1.8);
  }

  void update() {
    x += rainSlant * speedValue + rainWind * 0.48;
    y += speedValue;

    float currentHitY = hitY + sin(x * 0.018 + frameCount * 0.012) * 16;
    if (y > currentHitY) {
      spawnRainRipple(x, currentHitY, random(24, 58));
      reset(false);
    }

    if (x < -160 || x > width + 190) {
      reset(false);
    }
  }

  void display() {
    color rainColor = color(91, 181, 221);
    stroke(red(rainColor), green(rainColor), blue(rainColor), alphaValue * rainVisibility * 0.72);
    strokeWeight(weightValue);
    float dx = rainSlant * lengthValue + rainWind * 8;
    line(x, y, x + dx, y + lengthValue);

    if (lengthValue > 102) {
      stroke(red(rainColor), green(rainColor), blue(rainColor), alphaValue * rainVisibility * 0.12);
      strokeWeight(weightValue + 2.0);
      line(x + 1, y + 2, x + dx + 1, y + lengthValue + 2);
    }
  }
}

class RainRipple {
  float x;
  float y;
  float radius;
  float maxRadius;
  float alphaValue;
  boolean alive = false;

  void reset(float startX, float startY, float size) {
    x = constrain(startX, 16, width - 16);
    y = constrain(startY, 80, height - 60);
    radius = 2;
    maxRadius = size;
    alphaValue = random(42, 95);
    alive = true;
  }

  void update() {
    if (!alive) {
      return;
    }

    radius += 1.45;
    alphaValue *= 0.932;
    if (radius > maxRadius || alphaValue < 4) {
      alive = false;
    }
  }

  void display() {
    if (!alive) {
      return;
    }

    noFill();
    stroke(91, 181, 221, alphaValue * rainVisibility * 0.78);
    strokeWeight(1.4);
    arc(x, y, radius * 1.8, radius * 0.62, 0.1, TWO_PI - 0.8);
  }
}

class EndingLine {
  String sentence;
  float x;
  float y;
  float twinkleOffset;

  EndingLine(String sentence, float x, float y) {
    this.sentence = sentence;
    this.x = x;
    this.y = y;
    this.twinkleOffset = random(TWO_PI);
  }

  void display(float alphaValue) {
    if (alphaValue < 1) {
      return;
    }

    textFont(songti);
    textSize(textSizeValue);
    textAlign(CENTER, BASELINE);

    float stable = constrain(alphaValue / 255.0, 0, 1);
    float twinkle = 0.5 + 0.5 * sin(frameCount * endingTwinkleSpeed + twinkleOffset);
    float sparkle = lerp(1 - endingTwinkleStrength, 1, twinkle);
    float finalAlpha = alphaValue * lerp(sparkle, 1, stable * stable);

    fill(0, finalAlpha);
    noStroke();
    text(sentence, x, y);

    if (stable < 0.96 && twinkle > 0.72) {
      fill(255, 215, 103, finalAlpha * 0.42);
      drawFourPointStar(x + textWidth(sentence) / 2 + 13, y - textSizeValue * 0.42, 1.6 + twinkle * 1.5);
    }
  }
}

class SentenceLine {
  String sentence;
  float x;
  float y;
  float w;
  boolean isLoveLine;
  float disperse = 0;
  float hoverBlur = 0;
  float[] scatterX;
  float[] scatterY;
  float[] rotateTo;
  float[] delay;
  boolean[] becomesStar;
  float[] starOffset;
  float[] starRotation;
  float[] meteorDrift;
  float[] meteorGravity;
  float[] meteorGround;
  float[] meteorBounce;

  SentenceLine(String sentence, float x, float y) {
    this.sentence = sentence;
    this.x = x;
    this.y = y;
    this.w = textWidth(sentence);
    this.isLoveLine = sentence.equals("“我很想你”");
    this.scatterX = new float[sentence.length()];
    this.scatterY = new float[sentence.length()];
    this.rotateTo = new float[sentence.length()];
    this.delay = new float[sentence.length()];
    this.becomesStar = new boolean[sentence.length()];
    this.starOffset = new float[sentence.length()];
    this.starRotation = new float[sentence.length()];
    this.meteorDrift = new float[sentence.length()];
    this.meteorGravity = new float[sentence.length()];
    this.meteorGround = new float[sentence.length()];
    this.meteorBounce = new float[sentence.length()];

    for (int i = 0; i < sentence.length(); i++) {
      scatterX[i] = random(-scatterXRange, scatterXRange)
                  + (i - sentence.length() * 0.5) * random(2.0, characterSpread);
      scatterY[i] = random(-scatterUpRange, scatterDownRange);
      rotateTo[i] = random(-rotationRange, rotationRange);
      delay[i] = random(0, scatterDelayMax);
      becomesStar[i] = random(1) < starChance;
      starOffset[i] = random(TWO_PI);
      starRotation[i] = random(TWO_PI);
      meteorDrift[i] = random(-meteorDriftRange, meteorDriftRange);
      meteorGravity[i] = random(1.7, 1.7 + meteorGravityRandom);
      meteorGround[i] = meteorGroundY + random(-18, 10);
      meteorBounce[i] = meteorBounceHeight * random(0.65, 1.15);
    }
  }

  void update() {
    if (dispersing && !isLoveLine) {
      disperse = min(1 + starDuration, disperse + disperseSpeed);
      hoverBlur = lerp(hoverBlur, 1, hoverBlurInSpeed);
    }

    if (!dispersing && !isLoveLine && isMouseOver()) {
      hoverBlur = lerp(hoverBlur, 1, hoverBlurInSpeed);
    }
  }

  boolean isMouseOver() {
    return mouseX > x - w / 2
        && mouseX < x + w / 2
        && mouseY > y - textSizeValue - 8
        && mouseY < y + 8;
  }

  void display() {
    textFont(songti);
    textSize(textSizeValue);
    noStroke();

    if (isLoveLine) {
      textAlign(CENTER, BASELINE);
      fill(0);
      text(sentence, x, y);
      return;
    }

    if (disperse <= 0.001) {
      displayStillLine();
      return;
    }

    displayDispersing();
  }

  void displayStillLine() {
    textAlign(CENTER, BASELINE);

    float blurAmount = hoverBlur * hoverBlurStrength;
    float gray = lerp(0, hoverGrayValue, hoverBlur);
    float mainAlpha = lerp(255, 170, hoverBlur);

    if (blurAmount > 0.05) {
      fill(gray, hoverBlur * 22);
      text(sentence, x - blurAmount, y);
      text(sentence, x + blurAmount, y);
      text(sentence, x, y - blurAmount);
      text(sentence, x, y + blurAmount);

      fill(gray, hoverBlur * 30);
      text(sentence, x - blurAmount * 0.45, y - blurAmount * 0.45);
      text(sentence, x + blurAmount * 0.45, y + blurAmount * 0.45);
    }

    fill(gray, mainAlpha);
    text(sentence, x, y);
  }

  void displayDispersing() {
    textAlign(LEFT, BASELINE);

    float startX = x - w / 2;
    float cx = startX;

    for (int i = 0; i < sentence.length(); i++) {
      char c = sentence.charAt(i);
      float cw = textWidth(str(c));
      float textT = constrain((disperse - delay[i]) / (1.0 - delay[i]), 0, 1);
      float ease = textT * textT * (3 - 2 * textT);
      float fadeT = constrain((textT - fadeStart) / (1.0 - fadeStart), 0, 1);
      float alphaValue = 255 * (1 - pow(fadeT, fadeSlowness));
      float blurValue = max(ease * blurStrength, hoverBlur * hoverBlurStrength);
      float grayValue = lerp(0, hoverGrayValue, hoverBlur);
      float finalAlpha = alphaValue * lerp(1, 0.67, hoverBlur);
      float wave = sin(frameCount * 0.035 + i * 0.8) * ease * 1.4;
      float px = cx + scatterX[i] * ease + wave;
      float py = y + scatterY[i] * ease + abs(scatterY[i]) * ease * 0.25;

      if (disperse > 1.0 && c != ' ' && becomesStar[i]) {
        float starDelay = delay[i] * 0.35;
        float starT = constrain((disperse - 1.0 - starDelay) / starDuration, 0, 1);
        float appear = smoothstep(0.0, 0.10, starT);
        float grounded = smoothstep(0.78, 1.0, starT);
        float fallingPulse = 0.72 + 0.28 * sin(starT * PI * 5.0 + starOffset[i]);
        float groundedPulse = 1.0 - groundedTwinkleStrength
                            + groundedTwinkleStrength * (0.5 + 0.5 * sin(frameCount * groundedTwinkleSpeed + starOffset[i]));
        float movingAlpha = starAlphaMax * fallingPulse;
        float restingAlpha = groundedStarAlpha * groundedPulse;
        float starAlpha = appear * lerp(movingAlpha, restingAlpha, grounded);
        float starSize = lerp(starMinSize, starMaxSize, lerp(fallingPulse, groundedPulse, grounded))
                       * lerp(1 - starT * 0.28, 0.72, grounded);

        float fallEnd = 0.58;
        float mx = px;
        float my = py;
        float angle = HALF_PI;

        if (starT < fallEnd) {
          float fallT = smoothstep(0, fallEnd, starT);
          mx = px + meteorDrift[i] * fallT;
          my = lerp(py, meteorGround[i], pow(fallT, meteorGravity[i]));
          angle = atan2(meteorGround[i] - py, meteorDrift[i]);
        } else {
          float bounceT = constrain((starT - fallEnd) / (1.0 - fallEnd), 0, 1);
          float bounce = abs(sin(bounceT * PI * meteorBounceCount)) * (1.0 - bounceT) * meteorBounce[i];
          mx = px + meteorDrift[i] + meteorDrift[i] * 0.18 * bounceT;
          my = meteorGround[i] - bounce;
          angle = HALF_PI + sin(bounceT * PI * meteorBounceCount) * 0.35;
        }

        if (starAlpha > 2) {
          pushMatrix();
          translate(mx, my);
          float rotationProgress = smoothstep(0.10, 1.0, starT);
          rotate((starRotation[i] + angle * 0.10) * rotationProgress);
          drawMeteorStar(0, 0, starSize, starAlpha);
          popMatrix();
        }
      } else if (finalAlpha > 1) {
        float scaleValue = lerp(1.0, disperseEndScale, smoothstep(fadeStart, 1.0, textT));
        pushMatrix();
        translate(px, py);
        rotate(rotateTo[i] * ease);
        scale(scaleValue);
        drawSoftChar(c, 0, 0, finalAlpha, blurValue, grayValue);
        popMatrix();
      }

      cx += cw;
    }
  }

  float smoothstep(float edge0, float edge1, float value) {
    float t = constrain((value - edge0) / (edge1 - edge0), 0, 1);
    return t * t * (3 - 2 * t);
  }

  void drawSoftChar(char c, float px, float py, float alphaValue, float blurValue, float grayValue) {
    if (blurValue < 0.25) {
      fill(grayValue, alphaValue);
      text(c, px, py);
      return;
    }

    fill(grayValue, alphaValue * 0.08);
    text(c, px - blurValue, py);
    text(c, px + blurValue, py);
    text(c, px, py - blurValue);
    text(c, px, py + blurValue);

    fill(grayValue, alphaValue * 0.18);
    text(c, px - blurValue * 0.5, py - blurValue * 0.5);
    text(c, px + blurValue * 0.5, py + blurValue * 0.5);

    fill(grayValue, alphaValue * 0.65);
    text(c, px, py);
  }

  void drawMeteorStar(float px, float py, float s, float alphaValue) {
    strokeWeight(1.4);
    stroke(255, 222, 112, alphaValue * 0.36);
    line(px, py - s * 0.2, px, py - meteorTailLength);

    noStroke();
    fill(255, 205, 82, alphaValue * 0.18);
    drawFourPointStar(px, py, s * 1.75);

    fill(255, 215, 103, alphaValue);
    drawFourPointStar(px, py, s);

    fill(255, 242, 175, alphaValue * 0.55);
    drawFourPointStar(px, py, s * 0.48);
  }
}

void drawFourPointStar(float px, float py, float s) {
  noStroke();
  beginShape();
  vertex(px, py - s * 2.05);
  bezierVertex(px + s * 0.08, py - s * 0.88, px + s * 0.45, py - s * 0.18, px + s * 1.45, py);
  bezierVertex(px + s * 0.45, py + s * 0.18, px + s * 0.08, py + s * 0.88, px, py + s * 2.05);
  bezierVertex(px - s * 0.08, py + s * 0.88, px - s * 0.45, py + s * 0.18, px - s * 1.45, py);
  bezierVertex(px - s * 0.45, py - s * 0.18, px - s * 0.08, py - s * 0.88, px, py - s * 2.05);
  endShape(CLOSE);
}
