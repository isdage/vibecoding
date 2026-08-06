PImage backgroundImage;
PFont font;
ArrayList<LineText> lines = new ArrayList<LineText>();
ArrayList<RainDrop> rainDrops = new ArrayList<RainDrop>();

float poemTextSize = 15;
float letterX = 115;
float poemStartY = 235;

// 调整这里：同一段里面，每一行之间的距离。
float lineGap = 25;

// 调整这里：段落和段落之间的距离。
float paragraphGap = 50;

// 调整这里：右下角“我爱你。”的位置和大小。
float loveTextX = 395;
float loveTextY = 525;
float loveTextSize = 15;

// 字体文件名。这个 .ttf 放在 UnsentLetter 文件夹里，Processing 会按这个名字加载。
String fontFileName = "经典宋体简.ttf";

// 调整这里：数值越大，鼠标靠近后文字变清晰越快。
// 推荐范围：0.06 到 0.14。太大会变得很突然。
float clearSpeed = 0.08;

// 调整这里：数值越大，鼠标离开后文字重新模糊越快。
float blurBackSpeed = 0.05;

// 调整这里：鼠标离文字多近才开始变清楚。数值越小，影响范围越窄。
float mouseAffectDistance = 85;

// 调整这里：鼠标离文字多近时最清楚。
float mouseFullClearDistance = 30;

// 调整这里：雨滴出现频率。数值越大，雨越密。
float rainChance = 0.01;

// 调整这里：画面上同时出现的水滴数量上限。
int maxRainDrops = 3;

// 调整这里：雨滴让附近文字额外清楚的程度。
float rainClearAmount = 1.5;

// 调整这里：雨滴影响文字清晰的范围。
float rainAffectDistance = 80;

// 调整这里：水渍停留时间。数值越大，消失越慢。
float waterLife = 170;

// 调整这里：水波的亮色和暗色。这里用中性偏暖灰，避免泛蓝。
color rippleLightColor = color(248, 247, 240);
color rippleDarkColor = color(118, 116, 108);

// 调整这里：水波颜色透明度。数值越大，水滴越明显。
float rippleLightAlpha = 54;
float rippleDarkAlpha = 42;

void setup() {
  size(600, 800);
  smooth(4);

  backgroundImage = loadImage(sketchPath("background.jpg"));
  backgroundImage.resize(width, height);

  font = createFont(sketchPath(fontFileName), poemTextSize, true);
  textFont(font);
  textSize(poemTextSize);

  float y = poemStartY;

  // 第一段
  y = addParagraph(new String[] {
    "那天，我原本有话告诉你。"
  }, y);

  // 第二段
  y = addParagraph(new String[] {
    "后来雨一直下。",
    "我写了三遍你的名字，",
    "停了一会儿。"
  }, y);

  // 第三段
  y = addParagraph(new String[] {
    "有些话没有忘，",
    "只是没有寄出。"
  }, y);

  // 第四段
  y = addParagraph(new String[] {
    "雨停以后，",
    "信还留在原处。"
  }, y);

  lines.add(new LineText("我爱你。", loveTextX, loveTextY, loveTextSize));
}

float addParagraph(String[] paragraphLines, float y) {
  for (int i = 0; i < paragraphLines.length; i++) {
    lines.add(new LineText(paragraphLines[i], letterX, y, poemTextSize));
    y += lineGap;
  }

  return y - lineGap + paragraphGap;
}

void draw() {
  image(backgroundImage, 0, 0);

  if (rainDrops.size() < maxRainDrops && random(1) < rainChance) {
    rainDrops.add(new RainDrop(random(70, width - 70), random(140, 560)));
  }

  for (int i = rainDrops.size() - 1; i >= 0; i--) {
    RainDrop drop = rainDrops.get(i);
    drop.update();
    drop.display();

    if (drop.justLanded) {
      for (LineText line : lines) {
        line.addRainBoost(drop.x, drop.y);
      }
    }

    if (drop.finished) {
      rainDrops.remove(i);
    }
  }

  int activeLine = findClosestLine();

  for (int i = 0; i < lines.size(); i++) {
    lines.get(i).update(i == activeLine);
    lines.get(i).display();
  }
}

int findClosestLine() {
  int closestIndex = -1;
  float closestDistance = mouseAffectDistance;

  for (int i = 0; i < lines.size(); i++) {
    float d = lines.get(i).distanceToText(mouseX, mouseY);
    if (d < closestDistance) {
      closestDistance = d;
      closestIndex = i;
    }
  }

  return closestIndex;
}

class LineText {
  String content;
  float x;
  float y;
  float textSizeValue;
  float clarity = 0;
  float rainBoost = 0;
  PGraphics layer;

  LineText(String content, float x, float y, float textSizeValue) {
    this.content = content;
    this.x = x;
    this.y = y;
    this.textSizeValue = textSizeValue;

    textSize(textSizeValue);
    float w = textWidth(content) + 40;
    float h = textSizeValue + 42;
    layer = createGraphics(int(w), int(h));
  }

  void update(boolean isActiveLine) {
    float targetClarity = 0;

    if (isActiveLine) {
      float distanceToMouse = distanceToText(mouseX, mouseY);
      targetClarity = map(distanceToMouse, mouseAffectDistance, mouseFullClearDistance, 0, 1);
      targetClarity = constrain(targetClarity, 0, 1);
    }

    targetClarity = max(targetClarity, rainBoost);

    if (targetClarity > clarity) {
      clarity = lerp(clarity, targetClarity, clearSpeed);
    } else {
      clarity = lerp(clarity, targetClarity, blurBackSpeed);
    }

    rainBoost *= 0.94;
  }

  void addRainBoost(float dropX, float dropY) {
    float d = distanceToText(dropX, dropY);

    if (d < rainAffectDistance) {
      float boost = map(d, rainAffectDistance, 0, 0.04, rainClearAmount);
      rainBoost = max(rainBoost, boost);
    }
  }

  float distanceToText(float px, float py) {
    float left = x;
    textSize(textSizeValue);
    float right = x + textWidth(content);
    float top = y - textSizeValue - 8;
    float bottom = y + 8;

    float closestX = constrain(px, left, right);
    float closestY = constrain(py, top, bottom);
    return dist(px, py, closestX, closestY);
  }

  void display() {
    float blurAmount = map(clarity, 0, 1, 8, 0);
    float alphaAmount = map(clarity, 0, 1, 88, 255);

    layer.beginDraw();
    layer.clear();
    layer.textFont(font);
    layer.textSize(textSizeValue);
    layer.fill(0, alphaAmount);
    layer.text(content, 20, textSizeValue + 16);
    layer.endDraw();

    if (blurAmount > 0.1) {
      layer.filter(BLUR, blurAmount);
    }

    image(layer, x - 20, y - textSizeValue - 16);
  }
}

class RainDrop {
  float x;
  float y;
  float age = 0;
  float stainSize;
  float maxRipple;
  PGraphics waterLayer;
  boolean justLanded = true;
  boolean finished = false;

  RainDrop(float x, float y) {
    this.x = x;
    this.y = y;
    stainSize = random(12, 24);
    maxRipple = random(70, 105);
    waterLayer = createGraphics(150, 150);
  }

  void update() {
    if (age > 0) {
      justLanded = false;
    }

    age++;
    if (age > waterLife) {
      finished = true;
    }
  }

  void display() {
    float p = constrain(age / waterLife, 0, 1);
    float rippleSize = easeOut(p) * maxRipple;
    float fade = 1 - smoothstepWater(0.42, 1.0, p);
    float appear = smoothstepWater(0.0, 0.12, p);

    waterLayer.beginDraw();
    waterLayer.clear();
    waterLayer.pushMatrix();
    waterLayer.translate(waterLayer.width / 2, waterLayer.height / 2);

    float stainAlpha = 18 * fade;
    waterLayer.noStroke();
    waterLayer.fill(red(rippleDarkColor), green(rippleDarkColor), blue(rippleDarkColor), stainAlpha);
    waterLayer.ellipse(0, 0, stainSize + rippleSize * 0.18, stainSize + rippleSize * 0.18);

    waterLayer.noFill();

    waterLayer.strokeWeight(5);
    waterLayer.stroke(red(rippleLightColor), green(rippleLightColor), blue(rippleLightColor), rippleLightAlpha * fade * appear);
    waterLayer.ellipse(-1.2, -1.2, rippleSize * 0.96, rippleSize * 0.96);

    waterLayer.strokeWeight(3);
    waterLayer.stroke(red(rippleDarkColor), green(rippleDarkColor), blue(rippleDarkColor), rippleDarkAlpha * fade * appear);
    waterLayer.ellipse(1.4, 1.4, rippleSize, rippleSize);

    waterLayer.strokeWeight(4);
    waterLayer.stroke(red(rippleDarkColor), green(rippleDarkColor), blue(rippleDarkColor), rippleDarkAlpha * 0.28 * fade * appear);
    waterLayer.ellipse(0, 0, rippleSize * 0.62, rippleSize * 0.62);

    waterLayer.strokeWeight(2);
    waterLayer.stroke(red(rippleLightColor), green(rippleLightColor), blue(rippleLightColor), rippleLightAlpha * 0.5 * fade * appear);
    waterLayer.ellipse(0, 0, rippleSize * 1.18, rippleSize * 1.18);

    waterLayer.popMatrix();
    waterLayer.filter(BLUR, 1.7);
    waterLayer.endDraw();

    image(waterLayer, x - waterLayer.width / 2, y - waterLayer.height / 2);
  }

  float easeOut(float t) {
    return 1 - pow(1 - t, 3);
  }

  float smoothstepWater(float edge0, float edge1, float value) {
    float t = constrain((value - edge0) / (edge1 - edge0), 0, 1);
    return t * t * (3 - 2 * t);
  }
}
