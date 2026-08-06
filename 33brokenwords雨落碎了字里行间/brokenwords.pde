PImage bg;
PFont letterFont;
ArrayList<LetterPiece> letters = new ArrayList<LetterPiece>();
ArrayList<RainLine> rainLines = new ArrayList<RainLine>();
ArrayList<WaterStain> stains = new ArrayList<WaterStain>();

String letterText =
  "My dearest,\n\n" +
  "Tonight, I find myself listening to the quiet as if it might bring me your voice. The room is still, yet everything in it seems to remember you: the chair where you once lingered, the window where the evening light used to fall across your face, even the air, which feels incomplete without your laughter moving through it.\n\n" +
  "I miss you in ordinary moments most of all. I miss you when morning arrives and I reach for a thought to share. I miss you when the sky changes color and there is no one beside me to say, \"Look.\" Your absence is not loud, but it is everywhere, like moonlight on water, touching each small thing with silver ache.\n\n" +
  "Sometimes I imagine the distance between us as a long road made of stars. Every night, my heart walks it patiently, carrying all the words I have not been able to say. If love could travel faster than light, you would feel it now: warm on your hands, gentle on your shoulders, steady as a candle refusing to go out.\n\n" +
  "Please know that being apart has not dimmed what I feel. It has only taught me how deeply you live within me. You are in the music I return to, in the dreams I wake from reluctantly, in the silence after every beautiful thing.\n\n" +
  "Until I can see you again, I will keep missing you with tenderness rather than sorrow. I will let hope sit beside me. I will believe that every day apart is quietly bringing us closer to the moment when distance becomes memory, and I can finally hold you instead of this longing.\n\n" +
  "With all my heart,\n\n" +
  "Yours";

float textX = 135;
float textY = 64;
float textW = 430;
float fontSize = 12;
float lineHeight = 15;
float triggerRadius = 20;
float floorY;
int rainTimer = 0;
float rainAlpha = 0;
float revealTime = 0;
float minRainImpactR = 10;
float maxRainImpactR = 38;
boolean rainStarted = false;
boolean textReady = false;

void setup() {
  size(600, 800);
  smooth(4);
  bg = loadImage("background.png");
  letterFont = createFont("Courier New.ttf", fontSize);
  textFont(letterFont);
  textSize(fontSize);
  textLeading(lineHeight);
  floorY = height - 28;
  resetLetters();
}

void draw() {
  image(bg, 0, 0, width, height);
  updateRainIntro();
  updateReveal();

  for (LetterPiece letter : letters) {
    letter.checkMouse();
    letter.integrate();
  }

  for (int i = 0; i < 3; i++) {
    solveLetterCollisions();
  }

  for (LetterPiece letter : letters) {
    letter.constrainToRoom();
    letter.display();
  }
}

void keyPressed() {
  if (key == 'r' || key == 'R') {
    resetLetters();
  } else if (key == ' ') {
    startRainIntro();
  }
}

void resetLetters() {
  letters.clear();
  rainLines.clear();
  stains.clear();
  rainTimer = 0;
  rainAlpha = 0;
  revealTime = 0;
  rainStarted = false;
  textReady = false;
  layoutLetters();
}

void startRainIntro() {
  if (rainStarted || !textReady) {
    return;
  }

  rainStarted = true;
  rainTimer = 0;
  rainAlpha = 0;
  rainLines.clear();
  stains.clear();

  for (int i = 0; i < 6; i++) {
    rainLines.add(new RainLine());
  }
}

PVector chooseRainImpact() {
  LetterPiece picked = null;

  for (int i = 0; i < 80; i++) {
    LetterPiece candidate = letters.get(int(random(letters.size())));
    if (!candidate.isLoose() && candidate.alpha > 220 && candidate.isNearHome()) {
      picked = candidate;
      break;
    }
  }

  if (picked == null) {
    return new PVector(random(textX + 70, textX + textW - 55), random(textY + 65, textY + 360));
  }

  return new PVector(constrain(picked.cx() + random(-24, 24), textX + 25, textX + textW - 35),
                     constrain(picked.cy() + random(-20, 20), textY + 35, textY + 530));
}

void updateRainIntro() {
  for (int i = stains.size() - 1; i >= 0; i--) {
    WaterStain stain = stains.get(i);
    stain.update();
    stain.display();
    if (stain.isGone()) {
      stains.remove(i);
    }
  }

  if (!rainStarted) {
    return;
  }

  rainTimer++;

  rainAlpha = lerp(rainAlpha, 1, 0.055);

  for (RainLine rain : rainLines) {
    rain.update();
    rain.display(rainAlpha);
  }

}

void updateReveal() {
  if (textReady) {
    return;
  }

  revealTime += 1;

  int visibleCount = 0;
  for (LetterPiece letter : letters) {
    letter.updateReveal(revealTime);
    if (letter.alpha >= 245) {
      visibleCount++;
    }
  }

  if (visibleCount == letters.size()) {
    textReady = true;
  }
}

void triggerRainFall(float hitX, float hitY, float hitR) {
  for (LetterPiece letter : letters) {
    float d = dist(letter.cx(), letter.cy(), hitX, hitY);
    if (!letter.isLoose() && d < hitR) {
      letter.startRainFall(hitX, hitY, hitR);
    }
  }
}

void layoutLetters() {
  float x = textX;
  float y = textY;
  int i = 0;

  while (i < letterText.length()) {
    char c = letterText.charAt(i);

    if (c == '\n') {
      x = textX;
      y += lineHeight;
      i++;
      continue;
    }

    if (c == ' ') {
      x += textWidth(" ");
      i++;
      continue;
    }

    String word = "";
    while (i < letterText.length()) {
      char wc = letterText.charAt(i);
      if (wc == ' ' || wc == '\n') {
        break;
      }
      word += wc;
      i++;
    }

    if (x > textX && x + textWidth(word) > textX + textW) {
      x = textX;
      y += lineHeight;
    }

    for (int j = 0; j < word.length(); j++) {
      String ch = str(word.charAt(j));
      float cw = textWidth(ch);
      letters.add(new LetterPiece(ch, x, y, cw, fontSize));
      x += cw;
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
      if (!b.isLoose()) {
        continue;
      }
      if (a.sleeping && b.sleeping) {
        continue;
      }

      float dx = a.cx() - b.cx();
      float dy = a.cy() - b.cy();
      float d2 = dx * dx + dy * dy;
      float target = (a.r + b.r) * 0.72;

      if (d2 > 0.001 && d2 < target * target) {
        float d = sqrt(d2);
        float nx = dx / d;
        float ny = dy / d;
        float overlap = target - d;
        float aMove = a.sleeping ? 0.18 : 0.5;
        float bMove = b.sleeping ? 0.18 : 0.5;
        float totalMove = aMove + bMove;

        a.x += nx * overlap * (aMove / totalMove);
        a.y += ny * overlap * (aMove / totalMove);
        b.x -= nx * overlap * (bMove / totalMove);
        b.y -= ny * overlap * (bMove / totalMove);

        float push = overlap * 0.016;
        a.vx += nx * push;
        a.vy += ny * push;
        b.vx -= nx * push;
        b.vy -= ny * push;

        a.spin += nx * 0.006;
        b.spin -= nx * 0.006;
        a.touchingPile = true;
        b.touchingPile = true;

        if (a.sleeping && abs(b.vy) > 1.2) {
          a.sleeping = false;
        }
        if (b.sleeping && abs(a.vy) > 1.2) {
          b.sleeping = false;
        }
      }
    }
  }
}

class RainLine {
  float x;
  float y;
  float targetX;
  float targetY;
  float speed;
  float length;
  float alpha;

  RainLine() {
    resetDrop();
    y -= random(0, 260);
  }

  void resetDrop() {
    PVector target = chooseRainImpact();
    targetX = target.x;
    targetY = target.y;
    x = targetX - random(150, 330);
    y = targetY - random(190, 360);
    speed = random(0.85, 1.65);
    length = random(78, 142);
    alpha = random(95, 175);
  }

  void update() {
    x += speed * 4.8;
    y += speed * 6.4;

    if (dist(x, y, targetX, targetY) < 24 || y > targetY + 34) {
      hit();
      resetDrop();
    }
  }

  void hit() {
    float hitR = random(minRainImpactR, maxRainImpactR);
    triggerRainFall(targetX, targetY, hitR);
    stains.add(new WaterStain(targetX + random(-18, 18), targetY + random(-12, 12), random(44, 86)));
  }

  void display(float fade) {
    stroke(255, alpha * fade);
    strokeWeight(1.6);
    line(x, y, x - length * 0.56, y - length);
  }
}

class WaterStain {
  float x;
  float y;
  float r;
  float targetR;
  float alpha;

  WaterStain(float tempX, float tempY, float tempTargetR) {
    x = tempX;
    y = tempY;
    r = 2;
    targetR = tempTargetR;
    alpha = random(88, 135);
  }

  void update() {
    r = lerp(r, targetR, 0.04);
    alpha *= 0.972;
  }

  void display() {
    noFill();
    stroke(255, alpha);
    strokeWeight(1.8);
    ellipse(x, y, r * 1.28, r * 1.28);

    stroke(95, 150, 255, alpha * 0.78);
    strokeWeight(1.1);
    for (int i = -1; i <= 1; i++) {
      float yy = y + i * r * 0.22;
      line(x - r * 0.72, yy, x + r * 0.72, yy);
    }

    stroke(255, alpha * 0.42);
    strokeWeight(1);
    arc(x, y, r * 1.6, r * 1.6, -0.25, PI * 1.08);
  }

  boolean isGone() {
    return alpha < 0.45;
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
  float vx;
  float vy;
  float angle;
  float spin;
  float alpha = 0;
  float revealDelay;
  float revealSpeed;
  float twinklePhase;
  boolean falling = false;
  boolean sleeping = false;
  boolean touchingPile = false;
  boolean dropped = false;

  LetterPiece(String tempCh, float tempX, float tempY, float tempW, float tempH) {
    ch = tempCh;
    homeX = tempX;
    homeY = tempY;
    x = tempX;
    y = tempY;
    w = max(tempW, 3);
    h = tempH;
    r = max(3.6, min(7.5, max(w, h) * 0.44));
    angle = random(-0.015, 0.015);
    revealDelay = random(0, 115);
    revealSpeed = random(18, 44);
    twinklePhase = random(TWO_PI);
  }

  boolean isLoose() {
    return falling || sleeping;
  }

  boolean isNearHome() {
    return abs(x - homeX) < 2 && abs(y - homeY) < 2;
  }

  float cx() {
    return x + w * 0.5;
  }

  float cy() {
    return y + h * 0.5;
  }

  void checkMouse() {
    if (!textReady || isLoose()) {
      return;
    }

    if (dist(mouseX, mouseY, cx(), cy()) < triggerRadius) {
      falling = true;
      sleeping = false;
      dropped = true;
      vx = random(-0.55, 0.55) + (cx() - mouseX) * 0.022;
      vy = random(0.15, 0.8);
      spin = random(-0.055, 0.055);
    }
  }

  void startRainFall(float hitX, float hitY, float hitR) {
    float d = max(1, dist(cx(), cy(), hitX, hitY));
    float force = map(d, 0, hitR, 1.0, 0.25);
    falling = true;
    sleeping = false;
    dropped = true;
    vx = random(-0.35, 0.35) + (cx() - hitX) * 0.014 * force;
    vy = random(0.45, 1.35) * force;
    spin = random(-0.07, 0.07) * force;
  }

  void updateReveal(float t) {
    float revealAmount = constrain((t - revealDelay) / revealSpeed, 0, 1);
    revealAmount = revealAmount * revealAmount * (3 - 2 * revealAmount);

    if (revealAmount >= 1) {
      alpha = 245;
    } else if (revealAmount > 0) {
      float twinkle = 0.72 + 0.28 * sin(frameCount * 0.18 + twinklePhase);
      alpha = 245 * revealAmount * twinkle;
    } else {
      alpha = 0;
    }
  }

  void integrate() {
    if (!falling || sleeping) {
      return;
    }

    touchingPile = false;
    vy += 0.17;
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

    if (y + h > floorY) {
      y = floorY - h;
      vy *= -0.34;
      vx *= 0.82;
      spin *= 0.82;
    }

    boolean calm = abs(vx) < 0.08 && abs(vy) < 0.28 && abs(spin) < 0.012;
    boolean supported = y + h >= floorY - 0.4 || touchingPile;

    if (supported && calm) {
      sleeping = true;
      falling = false;
      vx = 0;
      vy = 0;
      spin = 0;
    }
  }

  void display() {
    if (alpha <= 0) {
      return;
    }

    pushMatrix();
    translate(cx(), cy());
    rotate(angle);
    if (!textReady && alpha > 0 && alpha < 245) {
      fill(150, 215, 255, alpha * 0.38);
      ellipse(0, 0, 7, 7);
    }
    if (dropped) {
      fill(255, alpha);
    } else {
      fill(59, 86, 115, alpha);
    }
    textAlign(CENTER, CENTER);
    textFont(letterFont);
    textSize(fontSize);
    text(ch, 0, -1);
    popMatrix();
  }
}
