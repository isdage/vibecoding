PFont font;
PImage bg;
ArrayList<LetterPiece> letters = new ArrayList<LetterPiece>();
ArrayList<Flower> flowers = new ArrayList<Flower>();
ArrayList<FallingPetal> fallingPetals = new ArrayList<FallingPetal>();

// 文字内容：每一行就是画面中的一段/一行文字。
String[] poem = {
  "你是一树一树的花开，",
  "是燕在梁间呢喃，",
  "你是爱，是暖，是希望，",
  "你是人间的四月天！"
};

// ===== 这里是最常用的排版参数，可以直接调整 =====
float fontSize = 14;       // 文字大小：数值越大，字越大。
float lineHeight = 28;     // 行间距：每两行文字之间的垂直距离。
float startY = 105;        // 第一行文字的 Y 位置：数值越大，整段文字越靠下。
float centerX = 300;       // 文字整体的水平中心位置：300 是画布正中间。
float triggerRadius = 24;  // 鼠标触发范围：数值越大，鼠标离字更远也会触发掉落。
float floorMargin = 26;    // 底部留白：字掉落后停在距离画布底部多少像素的位置。
float landingTop = 2.0 / 3.0; // 掉落停止区域的顶部：2/3 表示只停在画面下方 1/3 区域。
float petalLandingTop = 1.2 / 3.0; // 花瓣落点区域顶部：1.2/3 表示画面 40% 高度。
float petalLandingBottom = 4.5 / 5.0; // 花瓣落点区域底部：4.5/5 表示画面 90% 高度。
int letterPetalMin = 1;     // 一个字最少炸开多少片落下花瓣。
int letterPetalMax = 3;     // 一个字最多炸开多少片落下花瓣。
float petalBurstPower = 2.2;  // 字散成花瓣时的炸开力度：越大散得越开。
float flowerMinHeight = 22;    // 根茎最短高度。
float flowerMaxHeight = 158;   // 根茎最高高度。
float flowerGrowSpeed = 0.035; // 花朵生长速度：数值越大，开花越快。
float petalSize = 22;          // 花瓣长度。
int flowerPetalMin = 3;        // 花瓣最少数量。
int flowerPetalMax = 8;        // 花瓣最多数量。
float flowerMinScale = 0.58;   // 花朵最小整体比例。
float flowerMaxScale = 1.18;   // 花朵最大整体比例。
float stemSwing = 10;          // 根茎弹出摆动幅度：越大晃动越明显。
float leafyFlowerChance = 0.18; // 花瓣落下后长出带叶子花朵的概率：0.18 表示约 18%。

// ===== 吹动背景花瓣参数，可以直接调整 =====
int maxWindPetals = 26;        // 背景同时飘过的淡绿色花瓣数量上限。
WindPetal[] windPetals = new WindPetal[maxWindPetals];
float windPetalSpawnDebt = 0;  // 花瓣生成累积量，不需要手动改。
float blowPower = 0;           // 当前按键风力，不需要手动改。
float flowerWind = 0;          // 吹动时花朵受到的平滑风力，不需要手动改。
float flowerWindVelocity = 0;  // 花朵风力速度，不需要手动改。
float windPetalRate = 1.0;     // 空格触发后背景花瓣持续生成速度。
float windPetalSpeed = 0.6;    // 背景花瓣从右上到左下飘动速度。
float flowerBlowSwing = 15;    // 空格触发后花朵向左摆动的整体幅度。
float windFade = 0.935;        // 空格风力衰减速度：越接近 1，风吹得越久。
float windPetalLifeMin = 260;  // 背景花瓣最短持续时间：数值越大，花瓣停留越久。
float windPetalLifeMax = 440;  // 背景花瓣最长持续时间：数值越大，花瓣停留越久。
float windPetalBurstCount = 14; // 每次空格立刻出现的花瓣数量：越小越不集中。
float windPetalStartXMin = 0.54; // 花瓣出生区域左边界：0.54 表示从画面 54% 宽度开始。
float windPetalStartXOut = 260;  // 花瓣出生区域右侧画面外延伸距离：越大横向越分散。
float windPetalStartYMin = -230; // 花瓣出生区域最高位置：负数越小，越多花瓣从画面外上方进入。
float windPetalStartYMax = 0.48; // 花瓣出生区域最低位置：0.48 表示最高到画面 48% 高度。
float windPetalDelayMax = 90;    // 花瓣出现时间错开程度：越大，花瓣越不会同一瞬间出现。

// ===== 花朵根茎曲线参数，可以直接调整 =====
float stemBendMin = -42;       // 根茎末端最左弯曲距离。
float stemBendMax = 42;        // 根茎末端最右弯曲距离。
float stemControlMin = 0.24;   // 控制点高度比例：越小，曲线更早弯。
float stemControlMax = 0.72;   // 控制点高度比例上限：越大，曲线更靠上弯。
float stemControlJitter = 38;  // 控制点左右随机偏移：越大曲线越弯。
float sproutDepthMin = 8;      // 新芽从地下抽出的最浅深度。
float sproutDepthMax = 22;     // 新芽从地下抽出的最深深度。
// ================================================

float floorY;

void setup() {
  size(600, 800);
  smooth(4);
  bg = loadImage("background.jpg");
  if (bg != null) {
    bg.resize(width, height);
  }
  font = createFont("Songti SC", fontSize, true);
  textFont(font);
  textSize(fontSize);
  textAlign(CENTER, CENTER);
  floorY = height - floorMargin;
  layoutLetters();

  for (int i = 0; i < maxWindPetals; i++) {
    windPetals[i] = new WindPetal();
  }
}

void draw() {
  if (bg != null) {
    image(bg, 0, 0, width, height);
  } else {
    background(232);
  }

  updateWindPetals();

  for (LetterPiece letter : letters) {
    letter.checkMouse();
    letter.integrate();
  }

  for (int i = 0; i < 3; i++) {
    solveLetterCollisions();
  }

  for (Flower flower : flowers) {
    flower.update();
  }

  for (FallingPetal petal : fallingPetals) {
    petal.update();
  }

  for (LetterPiece letter : letters) {
    letter.constrainToRoom();
  }

  drawWindPetals();

  for (Flower flower : flowers) {
    flower.display();
  }

  for (FallingPetal petal : fallingPetals) {
    petal.display();
  }

  for (LetterPiece letter : letters) {
    letter.display();
  }
}

void keyPressed() {
  if (key == 'r' || key == 'R') {
    resetLetters();
  } else if (key == ' ' || key == ENTER || key == RETURN) {
    triggerWind();
  }
}

void resetLetters() {
  letters.clear();
  flowers.clear();
  fallingPetals.clear();
  windPetalSpawnDebt = 0;
  blowPower = 0;
  flowerWind = 0;
  flowerWindVelocity = 0;
  layoutLetters();
}

void updateWindPetals() {
  if (blowPower > 0.035) {
    windPetalSpawnDebt += blowPower * windPetalRate;
  }

  float targetFlowerWind = -blowPower * flowerBlowSwing;
  flowerWindVelocity += (targetFlowerWind - flowerWind) * 0.055;
  flowerWindVelocity *= 0.91;
  flowerWind += flowerWindVelocity;
  flowerWind *= 0.99;
  blowPower *= windFade;

  while (windPetalSpawnDebt >= 1) {
    spawnWindPetal();
    windPetalSpawnDebt -= 1;
  }

  for (int i = 0; i < maxWindPetals; i++) {
    windPetals[i].update();
  }
}

void triggerWind() {
  blowPower = min(1, blowPower + 0.88);
  windPetalSpawnDebt += windPetalBurstCount;
}

void spawnWindPetal() {
  for (int i = 0; i < maxWindPetals; i++) {
    if (!windPetals[i].alive) {
      windPetals[i].reset();
      return;
    }
  }
}

void drawWindPetals() {
  for (int i = 0; i < maxWindPetals; i++) {
    windPetals[i].display();
  }
}

float smoothstep(float edge0, float edge1, float x) {
  float t = constrain((x - edge0) / (edge1 - edge0), 0, 1);
  return t * t * (3 - 2 * t);
}

void layoutLetters() {
  textFont(font);
  textSize(fontSize);

  for (int row = 0; row < poem.length; row++) {
    String line = poem[row];
    float lineW = textWidth(line);
    // 每一行按 centerX 居中；如果想整体左移/右移，改上面的 centerX。
    float x = centerX - lineW / 2;
    // 每一行的高度由 startY + 行号 * lineHeight 决定。
    float y = startY + row * lineHeight;

    for (int i = 0; i < line.length(); i++) {
      String ch = str(line.charAt(i));
      float w = textWidth(ch);
      letters.add(new LetterPiece(ch, x, y, w, fontSize));
      x += w;
    }
  }
}

void solveLetterCollisions() {
  for (int i = 0; i < letters.size(); i++) {
    LetterPiece a = letters.get(i);
    if (!a.isLoose()) {
      continue;
    }

    for (int j = i + 1; j < letters.size(); j++) {
      LetterPiece b = letters.get(j);
      if (!b.isLoose() || (a.sleeping && b.sleeping)) {
        continue;
      }

      float dx = a.cx() - b.cx();
      float dy = a.cy() - b.cy();
      float d2 = dx * dx + dy * dy;
      float target = (a.r + b.r) * 0.78;

      if (d2 > 0.001 && d2 < target * target) {
        float d = sqrt(d2);
        float nx = dx / d;
        float ny = dy / d;
        float overlap = target - d;

        a.x += nx * overlap * 0.5;
        a.y += ny * overlap * 0.5;
        b.x -= nx * overlap * 0.5;
        b.y -= ny * overlap * 0.5;

        float push = overlap * 0.018;
        a.vx += nx * push;
        a.vy += ny * push;
        b.vx -= nx * push;
        b.vy -= ny * push;

        a.spin += nx * 0.006;
        b.spin -= nx * 0.006;
        a.touchingPile = true;
        b.touchingPile = true;

        if (a.sleeping && abs(b.vy) > 1.1) {
          a.sleeping = false;
          a.falling = true;
        }
        if (b.sleeping && abs(a.vy) > 1.1) {
          b.sleeping = false;
          b.falling = true;
        }
      }
    }
  }
}

class LetterPiece {
  String ch;
  float homeX;
  float homeY;
  float x;
  float y;
  float w;
  float h;
  float r;
  float landY;
  float vx;
  float vy;
  float angle;
  float spin;
  boolean falling = false;
  boolean sleeping = false;
  boolean touchingPile = false;
  boolean gone = false;

  LetterPiece(String tempCh, float tempX, float tempY, float tempW, float tempH) {
    ch = tempCh;
    homeX = tempX;
    homeY = tempY;
    x = tempX;
    y = tempY;
    w = max(tempW, 8);
    h = tempH;
    r = max(8, min(14, max(w, h) * 0.48));
    landY = random(height * landingTop, floorY);
    angle = random(-0.015, 0.015);
  }

  boolean isLoose() {
    return !gone && (falling || sleeping);
  }

  float cx() {
    return x + w * 0.5;
  }

  float cy() {
    return y + h * 0.5;
  }

  void checkMouse() {
    if (gone || isLoose()) {
      return;
    }

    if (dist(mouseX, mouseY, cx(), cy()) < triggerRadius) {
      gone = true;
      int count = int(random(letterPetalMin, letterPetalMax + 1));
      for (int i = 0; i < count; i++) {
        fallingPetals.add(new FallingPetal(cx(), cy(), mouseX, mouseY));
      }
    }
  }

  void integrate() {
    if (!falling || sleeping) {
      return;
    }

    touchingPile = false;
    vy += 0.18;
    vx *= 0.992;
    spin *= 0.992;
    x += vx;
    y += vy;
    angle += spin;
  }

  void constrainToRoom() {
    if (!isLoose()) {
      return;
    }

    if (x < 4) {
      x = 4;
      vx *= -0.18;
      spin *= 0.8;
    }

    if (x + w > width - 4) {
      x = width - 4 - w;
      vx *= -0.18;
      spin *= 0.8;
    }

    if (y + h > landY) {
      y = landY - h;
      vy *= -0.34;
      vx *= 0.82;
      spin *= 0.82;
    }

    boolean calm = abs(vx) < 0.08 && abs(vy) < 0.28 && abs(spin) < 0.012;
    boolean supported = y + h >= landY - 0.4 || touchingPile;

    if (supported && calm) {
      sleeping = true;
      falling = false;
      vx = 0;
      vy = 0;
      spin = 0;
    }
  }

  void display() {
    if (gone) {
      return;
    }

    pushMatrix();
    translate(cx(), cy());
    rotate(angle);
    fill(94);
    textFont(font);
    textSize(fontSize);
    textAlign(CENTER, CENTER);
    text(ch, 0, -1);
    popMatrix();
  }
}

class FallingPetal {
  float x;
  float y;
  float w;
  float h;
  float landY;
  float vx;
  float vy;
  float angle;
  float spin;
  float scaleValue;
  boolean sleeping = false;
  boolean flowerSpawned = false;

  FallingPetal(float tempX, float tempY, float hitX, float hitY) {
    x = tempX + random(-2, 2);
    y = tempY + random(-2, 2);
    w = random(4.5, 7.5);
    h = random(11, 18);
    scaleValue = random(0.72, 1.18);
    landY = random(height * petalLandingTop, height * petalLandingBottom);
    float burstAngle = random(TWO_PI);
    float burst = random(0.55, 1.0) * petalBurstPower;
    vx = cos(burstAngle) * burst + (tempX - hitX) * 0.028;
    vy = sin(burstAngle) * burst * 0.55 - random(0.35, 1.45);
    angle = random(TWO_PI);
    spin = random(-0.08, 0.08);
  }

  void update() {
    if (sleeping) {
      return;
    }

    vy += 0.075;
    vx += sin(frameCount * 0.035 + y * 0.04) * 0.012;
    vx *= 0.994;
    spin *= 0.992;
    x += vx;
    y += vy;
    angle += spin;

    if (x < 4 || x > width - 4) {
      vx *= -0.22;
      x = constrain(x, 4, width - 4);
    }

    if (y + h * scaleValue > landY) {
      y = landY - h * scaleValue;
      vy *= -0.22;
      vx *= 0.74;
      spin *= 0.72;
    }

    if (abs(vx) < 0.035 && abs(vy) < 0.08 && abs(spin) < 0.01 && y + h * scaleValue >= landY - 0.2) {
      sleeping = true;
      vx = 0;
      vy = 0;
      spin = 0;

      if (!flowerSpawned) {
        flowers.add(new Flower(x, landY, random(1) < leafyFlowerChance));
        flowerSpawned = true;
      }
    }
  }

  void display() {
    pushMatrix();
    translate(x, y);
    rotate(angle);
    scale(scaleValue);
    noStroke();
    fill(255, 255, 255, 238);
    drawPetalShape();
    popMatrix();
  }

  void drawPetalShape() {
    beginShape();
    vertex(0, 0);
    bezierVertex(-w * 0.70, h * 0.28,
                 -w * 0.45, h * 0.78,
                 0, h);
    bezierVertex(w * 0.45, h * 0.78,
                 w * 0.70, h * 0.28,
                 0, 0);
    endShape(CLOSE);
  }
}

class WindPetal {
  float x;
  float y;
  float vx;
  float vy;
  float w;
  float h;
  float angle;
  float spin;
  float age;
  float life;
  float alpha;
  float waveSeed;
  boolean alive = false;

  void reset() {
    alive = true;
    age = -random(windPetalDelayMax);
    life = random(windPetalLifeMin, windPetalLifeMax);
    x = random(width * windPetalStartXMin, width + windPetalStartXOut);
    y = random(windPetalStartYMin, height * windPetalStartYMax);
    vx = random(-2.45, -0.85) * windPetalSpeed - blowPower * random(0.35, 1.05);
    vy = random(0.75, 1.95) * windPetalSpeed + blowPower * random(0.25, 0.85);
    w = random(24, 58) * (0.85 + blowPower * 0.45);
    h = w;
    angle = random(TWO_PI);
    spin = random(-0.018, 0.018);
    alpha = random(95, 175) * (0.72 + blowPower * 0.55);
    waveSeed = random(TWO_PI);
  }

  void update() {
    if (!alive) {
      return;
    }

    age++;
    float wave = sin(age * 0.045 + waveSeed) * 0.55;
    x += vx + wave * 0.22;
    y += vy;
    angle += spin + sin(age * 0.032 + waveSeed) * 0.004;

    if (age > life || y > height + 80 || x < -80 || x > width + 120) {
      alive = false;
    }
  }

  void display() {
    if (!alive) {
      return;
    }

    float fadeIn = smoothstep(0, 24, age);
    float fadeOut = 1.0 - smoothstep(life - 55, life, age);
    float a = alpha * fadeIn * fadeOut;

    pushMatrix();
    translate(x, y);
    rotate(angle);
    scale(w / 56.0);
    noStroke();
    drawWindPetalShape(a);
    popMatrix();
  }

  void drawWindPetalShape(float a) {
    for (int i = 7; i >= 1; i--) {
      float s = i / 7.0;
      fill(207, 231, 190, a * map(i, 7, 1, 0.20, 0.78));
      beginShape();
      vertex(-30 * s, 0);
      bezierVertex(-18 * s, -29 * s, 14 * s, -31 * s, 32 * s, -3 * s);
      bezierVertex(18 * s, 26 * s, -14 * s, 27 * s, -30 * s, 0);
      endShape(CLOSE);
    }

    fill(232, 246, 222, a * 0.18);
    beginShape();
    vertex(-18, -1);
    bezierVertex(-6, -14, 14, -16, 28, -4);
    bezierVertex(14, 8, -4, 10, -18, -1);
    endShape(CLOSE);
  }
}

class Flower {
  float x;
  float rootY;
  float targetH;
  float bend;
  float sproutDepth;
  float controlRate;
  float controlBend;
  float scaleValue;
  float rotation;
  float swingPhase;
  float swingPower;
  float leafAt;
  float leafSide;
  float leafSize;
  float ownWind = 0;
  float ownWindVelocity = 0;
  float windFlex;
  float windFollow;
  float windDamping;
  float windPhase;
  float windFlutter;
  int petalCount;
  boolean hasLeaf;
  float age = 0;

  Flower(float tempX, float tempRootY) {
    this(tempX, tempRootY, false);
  }

  Flower(float tempX, float tempRootY, boolean tempHasLeaf) {
    x = tempX + random(-4, 4);
    rootY = tempRootY + random(8, 18);
    targetH = random(flowerMinHeight, flowerMaxHeight);
    bend = random(stemBendMin, stemBendMax);
    sproutDepth = random(sproutDepthMin, sproutDepthMax);
    controlRate = random(stemControlMin, stemControlMax);
    controlBend = bend * random(0.2, 0.95) + random(-stemControlJitter, stemControlJitter);
    scaleValue = random(flowerMinScale, flowerMaxScale);
    rotation = random(TWO_PI);
    swingPhase = random(TWO_PI);
    swingPower = random(0.75, 1.25);
    leafAt = random(0.38, 0.66);
    leafSide = random(1) < 0.5 ? -1 : 1;
    leafSize = random(0.78, 1.18);
    hasLeaf = tempHasLeaf;
    windFlex = random(0.42, 1.18) * map(targetH, flowerMinHeight, flowerMaxHeight, 0.68, 1.24);
    windFollow = random(0.022, 0.072);
    windDamping = random(0.86, 0.94);
    windPhase = random(TWO_PI);
    windFlutter = random(0.45, 1.20);
    petalCount = int(random(flowerPetalMin, flowerPetalMax + 1));
  }

  void update() {
    age += flowerGrowSpeed / 0.035;

    float windTarget = flowerWind * windFlex;
    ownWindVelocity += (windTarget - ownWind) * windFollow;
    ownWindVelocity *= windDamping;
    ownWind += ownWindVelocity;
    ownWind *= 0.992;
  }

  void display() {
    float sproutT = constrain(age / 26.0, 0, 1);
    float sproutGrow = easeOutBack(sproutT);
    float stemT = constrain(map(age, 8, 68, 0, 1), 0, 1);
    float stemGrow = min(easeOutBack(stemT), 1.06);
    float flowerT = constrain(map(age, 42, 92, 0, 1), 0, 1);
    float open = min(easeOutBack(flowerT), 1.08);
    float spring = sin(age * 0.28 + swingPhase) * exp(-age * 0.045) * stemSwing * swingPower;
    float breathe = sin(frameCount * 0.032 + swingPhase) * 1.2;
    float sway = (spring + breathe) * stemGrow;
    float flutter = sin(frameCount * 0.045 + windPhase) * min(6, abs(ownWind) * 0.10) * windFlutter;
    float windSway = (ownWind + flutter) * stemGrow;

    float x0 = x;
    float y0 = rootY + sproutDepth * (1 - sproutGrow);
    float cx = x + controlBend + sway * 0.22 + windSway * 0.34;
    float cy = rootY - targetH * controlRate * stemGrow;
    float x3 = x + bend + sway + windSway;
    float y3 = rootY - targetH * stemGrow;

    drawStem(x0, y0, cx, cy, x3, y3, stemGrow);
    if (hasLeaf) {
      drawLeafOnStem(x0, y0, cx, cy, x3, y3, stemGrow);
    }

    if (flowerT > 0) {
      pushMatrix();
      translate(x3, y3);
      rotate(rotation + sway * 0.012 + windSway * 0.01);
      scale(scaleValue);
      drawMinimalFlower(open, petalCount);
      popMatrix();
    }
  }

  void drawStem(float x0, float y0, float cx, float cy,
                float x3, float y3, float amount) {
    noFill();
    float limit = min(amount, 1);

    stroke(255, 255, 255, 230);
    strokeWeight(2.0);
    beginShape();
    for (float t = 0; t < limit; t += 0.035) {
      vertex(quadPoint(x0, cx, x3, t),
             quadPoint(y0, cy, y3, t));
    }
    vertex(quadPoint(x0, cx, x3, limit),
           quadPoint(y0, cy, y3, limit));
    endShape();
  }

  void drawLeafOnStem(float x0, float y0, float cx, float cy,
                      float x3, float y3, float amount) {
    float leafGrow = constrain(map(amount, 0.42, 0.86, 0, 1), 0, 1);
    if (leafGrow <= 0) {
      return;
    }

    float px = quadPoint(x0, cx, x3, leafAt);
    float py = quadPoint(y0, cy, y3, leafAt);
    float tx = quadTangent(x0, cx, x3, leafAt);
    float ty = quadTangent(y0, cy, y3, leafAt);
    float leafAngle = atan2(ty, tx) + HALF_PI * leafSide;
    float eased = easeOutBack(leafGrow);

    pushMatrix();
    translate(px, py);
    rotate(leafAngle);
    scale(leafSize * eased);
    noStroke();
    fill(172, 215, 144, 205);
    beginShape();
    vertex(0, 0);
    bezierVertex(5, -9, 13, -19, 5, -34);
    bezierVertex(-2, -22, -7, -8, 0, 0);
    endShape(CLOSE);
    popMatrix();
  }

  void drawMinimalFlower(float open, int count) {
    float o = constrain(open, 0, 1.08);
    float alphaValue = 255 * constrain(open, 0, 1);
    float petalOpen = 0.12 + 0.88 * o;
    float angleOpen = 0.18 + 0.82 * constrain(open, 0, 1);

    noStroke();
    for (int i = 0; i < count; i++) {
      float finalAngle;
      if (count >= 8) {
        finalAngle = QUARTER_PI * i;
      } else {
        finalAngle = (i - (count - 1) * 0.5) * QUARTER_PI;
      }
      pushMatrix();
      rotate(finalAngle * angleOpen);
      scale(0.46 + 0.54 * petalOpen, petalOpen);
      drawSinglePetal(alphaValue);
      popMatrix();
    }

    if (count >= 7) {
      fill(247, 221, 168, alphaValue);
      ellipse(0, 0, petalSize * 0.52 * o, petalSize * 0.52 * o);
    }
  }

  void drawSinglePetal(float alphaValue) {
    fill(255, 255, 255, alphaValue);
    beginShape();
    vertex(0, 0);
    bezierVertex(-petalSize * 0.34, -petalSize * 0.48,
                 -petalSize * 0.22, -petalSize * 1.25,
                 0, -petalSize * 1.75);
    bezierVertex(petalSize * 0.22, -petalSize * 1.25,
                 petalSize * 0.34, -petalSize * 0.48,
                 0, 0);
    endShape(CLOSE);
  }

  float easeOut(float t) {
    return 1 - pow(1 - t, 3);
  }

  float quadPoint(float a, float b, float c, float t) {
    return (1 - t) * (1 - t) * a + 2 * (1 - t) * t * b + t * t * c;
  }

  float quadTangent(float a, float b, float c, float t) {
    return 2 * (1 - t) * (b - a) + 2 * t * (c - b);
  }

  float easeOutBack(float t) {
    float c1 = 1.7;
    float c3 = c1 + 1;
    return 1 + c3 * pow(t - 1, 3) + c1 * pow(t - 1, 2);
  }
}
