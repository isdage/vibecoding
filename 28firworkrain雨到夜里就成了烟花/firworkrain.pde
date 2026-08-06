// firworkrain
// Space toggles between quiet blue rain and glowing night rain.

float designW = 600;
float designH = 800;
float viewScale = 1;
float viewOffsetX = 0;
float viewOffsetY = 0;

// ===== 雨量更改区 =====
int rainCount = 86;
float rainSlant = -0.34;
float rainSpeed = 9.0;
float rainLengthMin = 46;
float rainLengthMax = 126;

// ===== 绽开水花更改区 =====
int sparkCount = 420;
float sparkGravity = 0.22;
float sparkAir = 0.925;
float sparkLife = 42;

// ===== 涟漪更改区 =====
int rippleCount = 48;
float groundY = 662;

RainDrop[] rain = new RainDrop[rainCount];
Spark[] sparks = new Spark[sparkCount];
Ripple[] ripples = new Ripple[rippleCount];
PImage nightBackground;

float wind = 0;
float windVelocity = 0;
float rainPulse = 0;
float nightFade = 0;
boolean fireworkMode = false;

void setup() {
  size(600, 800);
  smooth(8);
  setupView();
  nightBackground = loadImage("background.jpg");

  for (int i = 0; i < rainCount; i++) {
    rain[i] = new RainDrop();
    rain[i].reset(random(-designH, designH), true);
  }

  for (int i = 0; i < sparkCount; i++) {
    sparks[i] = new Spark();
  }

  for (int i = 0; i < rippleCount; i++) {
    ripples[i] = new Ripple();
  }
}

void draw() {
  setupView();
  updateWeather();

  pushMatrix();
  translate(viewOffsetX, viewOffsetY);
  scale(viewScale);

  drawSky();
  pushMatrix();
  if (fireworkMode) {
    translate(designW, designH);
    rotate(PI);
  }
  updateAndDrawRipples();
  updateAndDrawRain();
  updateAndDrawSparks();
  popMatrix();
  drawForegroundWash();
  drawHint();

  popMatrix();
}

void setupView() {
  viewScale = min(width / designW, height / designH);
  viewOffsetX = (width - designW * viewScale) / 2.0;
  viewOffsetY = (height - designH * viewScale) / 2.0;
}

void updateWeather() {
  float targetWind = sin(frameCount * 0.012) * 0.68 + sin(frameCount * 0.031) * 0.22;
  if (mousePressed) {
    float sx = (mouseX - viewOffsetX) / viewScale;
    targetWind += map(sx, 0, designW, -1.3, 1.3);
    rainPulse = max(rainPulse, 0.5);
  }

  windVelocity += (targetWind - wind) * 0.018;
  windVelocity *= 0.94;
  wind += windVelocity;
  rainPulse *= 0.94;

  float targetNight = fireworkMode ? 1 : 0;
  nightFade = lerp(nightFade, targetNight, 0.055);
}

void updateAndDrawRain() {
  for (int i = 0; i < rainCount; i++) {
    rain[i].update();
    rain[i].draw();
  }
}

void updateAndDrawSparks() {
  for (int i = 0; i < sparkCount; i++) {
    sparks[i].update();
    sparks[i].draw();
  }
}

void updateAndDrawRipples() {
  for (int i = 0; i < rippleCount; i++) {
    ripples[i].update();
    ripples[i].draw();
  }
}

void keyPressed() {
  if (key == ' ' || key == ENTER || key == RETURN) {
    fireworkMode = !fireworkMode;
    rainPulse = 1.0;
    if (fireworkMode) {
      for (int i = 0; i < 9; i++) {
        burstFirework(random(90, 510), random(430, 690), random(0.65, 1.2));
      }
    }
  }
}

void mousePressed() {
  float sx = (mouseX - viewOffsetX) / viewScale;
  float sy = (mouseY - viewOffsetY) / viewScale;
  sx = weatherX(sx);
  sy = weatherY(sy);
  spawnRipple(sx, sy, random(48, 90));
  if (fireworkMode) {
    burstFirework(sx, sy, 1.0);
  }
  rainPulse = 1.0;
}

void mouseDragged() {
  float sx = (mouseX - viewOffsetX) / viewScale;
  float sy = (mouseY - viewOffsetY) / viewScale;
  sx = weatherX(sx);
  sy = weatherY(sy);
  if (frameCount % 3 == 0) {
    spawnRipple(sx, sy, random(24, 48));
    if (fireworkMode) {
      burstFirework(sx, sy, 0.55);
    }
  }
}

float weatherX(float x) {
  return fireworkMode ? designW - x : x;
}

float weatherY(float y) {
  return fireworkMode ? designH - y : y;
}

void drawSky() {
  color dayTop = color(250, 250, 247);
  color dayBottom = color(239, 244, 244);

  noStroke();
  for (int y = 0; y < designH; y += 3) {
    float t = y / designH;
    color day = lerpColor(dayTop, dayBottom, t);
    fill(day);
    rect(0, y, designW, 3);
  }

  if (nightBackground != null && nightFade > 0.01) {
    tint(255, 255 * nightFade);
    drawCoverImage(nightBackground, 0, 0, designW, designH);
    noTint();
  } else if (nightFade > 0.01) {
    fill(13, 29, 74, 255 * nightFade);
    rect(0, 0, designW, designH);
  }
}

void drawCoverImage(PImage img, float x, float y, float w, float h) {
  float imageScale = max(w / img.width, h / img.height);
  float drawW = img.width * imageScale;
  float drawH = img.height * imageScale;
  image(img, x + (w - drawW) / 2.0, y + (h - drawH) / 2.0, drawW, drawH);
}

void drawForegroundWash() {
  noStroke();
  if (nightFade < 0.5) {
    fill(255, 255, 255, 28 * (1 - nightFade));
  } else {
    fill(126, 236, 255, 8 * nightFade);
  }
  rect(0, 0, designW, designH);
}

void drawHint() {
  textAlign(CENTER);
  textSize(13);
  fill(lerpColor(color(72, 132, 152, 120), color(176, 246, 255, 145), nightFade));
  text("space: night firework rain  ·  click or drag to disturb the ripples", designW / 2, 752);
}

void raindropHit(float x, float y, float force) {
  spawnRipple(x, y + random(-4, 4), random(28, 72) * (0.8 + force * 0.3));
  burstFirework(x, y, force);
}

void burstFirework(float x, float y, float force) {
  float splashScale = randomSplashScale();
  int amount = int((random(10, 18) + force * 5) * (0.82 + splashScale * 0.30));
  for (int i = 0; i < amount; i++) {
    float spread = random(1);
    float angle;
    if (spread < 0.62) {
      angle = random(-PI * 0.82, -PI * 0.18);
    } else if (random(1) < 0.5) {
      angle = random(-PI * 0.98, -PI * 0.78);
    } else {
      angle = random(-PI * 0.22, -PI * 0.02);
    }
    float speed = random(2.4, 5.8) * (0.82 + force * 0.24) * splashScale;
    spawnSpark(x, y, angle, speed, splashScale);
  }
}

float randomSplashScale() {
  float r = random(1);
  if (r < 0.18) {
    return random(1.25, 1.85);
  }
  if (r < 0.56) {
    return random(0.88, 1.16);
  }
  return random(0.30, 0.52);
}

void spawnSpark(float x, float y, float angle, float speed, float splashScale) {
  for (int i = 0; i < sparkCount; i++) {
    if (!sparks[i].alive) {
      sparks[i].reset(x, y, angle, speed, splashScale);
      return;
    }
  }
}

void spawnRipple(float x, float y, float size) {
  for (int i = 0; i < rippleCount; i++) {
    if (!ripples[i].alive) {
      ripples[i].reset(x, y, size);
      return;
    }
  }
}

class RainDrop {
  float x;
  float y;
  float impactY;
  float length;
  float speed;
  float alpha;
  float weight;
  float tone;

  void reset(float startY, boolean anywhere) {
    x = random(-90, designW + 140);
    y = anywhere ? startY : random(-180, -20);
    impactY = random(designH * 0.34, designH * 0.85);
    length = random(rainLengthMin, rainLengthMax);
    speed = random(rainSpeed * 0.66, rainSpeed * 1.28);
    alpha = random(86, 160);
    weight = random(1.2, 2.6);
    tone = random(1);
  }

  void update() {
    float storm = 1.0 + rainPulse * 0.7;
    x += (rainSlant * speed + wind * 0.48) * storm;
    y += speed * storm;

    float hitY = impactY + sin(x * 0.018 + frameCount * 0.012) * 22;
    if (y > hitY) {
      raindropHit(x, hitY, map(speed, rainSpeed * 0.66, rainSpeed * 1.28, 0.45, 1.1));
      reset(0, false);
    }

    if (x < -160 || x > designW + 190) {
      reset(0, false);
    }
  }

  void draw() {
    color dayRain = color(91, 181, 221);
    color nightRain = nightMixedColor(tone);
    color rainColor = lerpColor(dayRain, nightRain, nightFade);

    stroke(red(rainColor), green(rainColor), blue(rainColor), alpha * (0.74 + nightFade * 0.02));
    strokeWeight(weight * (1.0 - nightFade * 0.18));
    float dx = rainSlant * length + wind * 8;
    line(x, y, x + dx, y + length);

    if (length > 102 && nightFade < 0.25) {
      stroke(red(rainColor), green(rainColor), blue(rainColor), alpha * 0.16);
      strokeWeight(weight + 2.0);
      line(x + 1, y + 2, x + dx + 1, y + length + 2);
    }
  }
}

class Spark {
  float x;
  float y;
  float vx;
  float vy;
  float heading;
  float age;
  float life;
  float size;
  float tone;
  boolean alive = false;

  void reset(float startX, float startY, float direction, float speed, float splashScale) {
    x = constrain(startX, 4, designW - 4);
    y = constrain(startY, 20, designH - 20);
    vx = cos(direction) * speed + wind * 0.06;
    vy = sin(direction) * speed - random(0.2, 1.0);
    heading = direction;
    age = 0;
    life = sparkLife + random(-8, 10) + splashScale * 3;
    size = random(2.4, 5.2) * splashScale;
    tone = random(1);
    alive = true;
  }

  void update() {
    if (!alive) return;

    vx += wind * 0.002;
    vy += sparkGravity;
    vx *= sparkAir;
    vy *= 0.982;
    x += vx;
    y += vy;
    if (sqrt(vx * vx + vy * vy) > 0.08) {
      heading = atan2(vy, vx);
    }
    age++;

    if (age > life || y > designH + 30 || x < -40 || x > designW + 40) {
      alive = false;
    }
  }

  void draw() {
    if (!alive) return;

    float p = constrain(age / life, 0, 1);
    float a = 206 * sin(p * PI) * (0.64 + nightFade * 0.36);
    if (a <= 2) return;

    float speedNow = sqrt(vx * vx + vy * vy);
    float burstBright = constrain(map(speedNow, 0, 5.2, 0.70, 1.18), 0.70, 1.18);
    float len = size * (1.05 + burstBright * 0.45);
    float thick = size * 0.12;
    float tailLen = len * constrain(map(speedNow, 0, 5.2, 1.25, 4.20), 1.25, 4.20) * (1.0 - p * 0.30);

    pushMatrix();
    translate(x, y);
    rotate(heading);

    noStroke();
    color nightTone = nightMixedColor(tone);
    color nightSoft = lerpColor(nightTone, color(255, 255, 245), 0.42);
    color daySoft = color(151, 225, 245);
    color dayCore = color(80, 184, 224);
    color tailGlow = lerpColor(daySoft, nightSoft, nightFade);
    color tailCore = lerpColor(dayCore, nightTone, nightFade);
    color needleGlow = lerpColor(color(150, 228, 246), nightSoft, nightFade);
    color needleCore = lerpColor(color(82, 188, 228), nightTone, nightFade);
    color needleHot = lerpColor(color(235, 252, 255), color(255, 255, 246), nightFade);

    fill(red(tailGlow), green(tailGlow), blue(tailGlow), a * 0.12);
    sparkTail(tailLen, thick * 6.1);

    fill(red(tailCore), green(tailCore), blue(tailCore), a * 0.27);
    sparkTail(tailLen * 0.76, thick * 2.75);

    fill(red(needleGlow), green(needleGlow), blue(needleGlow), a * 0.14);
    sparkNeedle(len * 1.28, thick * 4.2);

    fill(red(needleCore), green(needleCore), blue(needleCore), a * 0.78);
    sparkNeedle(len, thick * 2.15);

    fill(red(needleHot), green(needleHot), blue(needleHot), a);
    sparkNeedle(len * 0.34, thick * 1.05);

    popMatrix();
  }
}

void sparkNeedle(float len, float thick) {
  beginShape();
  vertex(-len * 0.5, 0);
  vertex(-len * 0.03, -thick * 0.5);
  vertex(len * 0.5, 0);
  vertex(-len * 0.03, thick * 0.5);
  endShape(CLOSE);
}

void sparkTail(float len, float thick) {
  beginShape();
  vertex(-len, 0);
  vertex(-len * 0.10, -thick * 0.5);
  vertex(len * 0.18, 0);
  vertex(-len * 0.10, thick * 0.5);
  endShape(CLOSE);
}

color nightMixedColor(float tone) {
  if (tone < 0.46) {
    return color(255, 245, 178);
  }
  if (tone < 0.76) {
    return color(255, 254, 198);
  }
  return color(255, 255, 152);
}

class Ripple {
  float x;
  float y;
  float radius;
  float maxRadius;
  float alpha;
  boolean alive = false;

  void reset(float startX, float startY, float size) {
    x = constrain(startX, 16, designW - 16);
    y = constrain(startY, 80, designH - 60);
    radius = 2;
    maxRadius = size;
    alpha = random(70, 125);
    alive = true;
  }

  void update() {
    if (!alive) return;
    radius += 1.45;
    alpha *= 0.932;
    if (radius > maxRadius || alpha < 4) {
      alive = false;
    }
  }

  void draw() {
    if (!alive) return;

    color dayRipple = color(91, 181, 221);
    color nightRipple = color(255, 255, 152);
    color rippleColor = lerpColor(dayRipple, nightRipple, nightFade);

    noFill();
    stroke(red(rippleColor), green(rippleColor), blue(rippleColor), alpha * (0.82 + nightFade * 0.25));
    strokeWeight(1.8);
    arc(x, y, radius * 1.8, radius * 0.62, 0.1, TWO_PI - 0.8);

    if (nightFade > 0.15) {
      stroke(red(rippleColor), green(rippleColor), blue(rippleColor), alpha * 0.34 * nightFade);
      strokeWeight(5);
      arc(x + 1, y + 1, radius * 1.8, radius * 0.62, 0.4, PI + 0.3);
    }
  }
}
