import java.util.HashMap;

PFont serif;
PGraphics staticLayer;
ArrayList<LetterPiece> letters = new ArrayList<LetterPiece>();
boolean staticDirty = true;

final int CANVAS_W = 600;
final int CANVAS_H = 800;
final float TEXT_W = 360;
final float TEXT_LEFT = (CANVAS_W - TEXT_W) * 0.5;
final float TEXT_TOP = 120;
final float BODY_SIZE = 16;
final float BODY_LEADING = 20;
final float PARAGRAPH_GAP = 24;
final float DROP_SIZE = 42;
final float DROP_GAP = 7;
final int DROP_LINES = 2;
final color BG_COLOR = #e2e2e2;
final color TEXT_COLOR = #5e5e5e;
final color POINTER_COLOR = #000000;
final float POINTER_X = 300;
final float POINTER_Y = 360;
final float POINTER_LENGTH = 240;
final float POINTER_HIT_RADIUS = 5;
final float MAX_POINTER_STEP = 0.08;
final int COLLISION_CELL = 26;
final float SLIDER_X1 = 84;
final float SLIDER_X2 = 508;
final float SLIDER_Y = 700;

float floorY;
float pointerControl = 0;
float previousPointerControl = 0;
float pointerVelocity = 0;
float pointerSweepStartControl = 0;
float pointerSweepDelta = 0;
boolean controllerActive = false;

String[] paragraphs = {
  "Tonight, I find myself listening to the quiet as if it might bring me your voice. The room is still, yet everything in it seems to remember you: the chair where you once lingered, the window where the evening light used to fall across your face, even the air, which feels incomplete without your laughter moving through it.",
  "I miss you in ordinary moments most of all. I miss you when morning arrives and I reach for a thought to share. I miss you when the sky changes color and there is no one beside me to say, “Look.” Your absence is not loud, but it is everywhere, like moonlight on water, touching each small thing with silver ache.",
  "Sometimes I imagine the distance between us as a long road made of stars. Every night, my heart walks it patiently, carrying all the words I have not been able to say. If love could travel faster than light, you would feel it now: warm on your hands, gentle on your shoulders, steady as a candle refusing to go out."
};

void setup() {
  size(600, 800);
  try {
    pixelDensity(displayDensity());
  } catch (Exception e) {
  }
  smooth(8);

  serif = loadSerifFont();
  floorY = height - 28;
  resetLetters();
}

void draw() {
  background(BG_COLOR);
  updateControllerHover();
  updatePointerPhysics();

  applyPointerToLetters();

  if (staticDirty) {
    renderStaticLayer();
  }
  image(staticLayer, 0, 0);

  int fallingCount = 0;
  for (LetterPiece letter : letters) {
    letter.integrate();
    if (letter.falling) {
      fallingCount++;
    }
  }

  if (fallingCount > 1) {
    for (int i = 0; i < 2; i++) {
      solveLetterCollisions();
    }
  }

  for (LetterPiece letter : letters) {
    letter.constrainToRoom();
    if (letter.isLoose()) {
      letter.display();
    }
  }

  drawPointer();
  drawController();
}

void keyPressed() {
  if (key == 'r' || key == 'R' || key == ' ') {
    resetLetters();
  }
}

void resetLetters() {
  letters.clear();
  staticDirty = true;
  previousPointerControl = pointerControl;
  pointerVelocity = 0;
  textFont(serif);
  fill(TEXT_COLOR);

  float y = TEXT_TOP + BODY_SIZE;

  for (int i = 0; i < paragraphs.length; i++) {
    if (i == 0) {
      y = layoutFirstParagraph(paragraphs[i], TEXT_LEFT, y, TEXT_W);
    } else {
      y = layoutParagraph(paragraphs[i], TEXT_LEFT, y, TEXT_W);
    }
    y += PARAGRAPH_GAP;
  }
}

void renderStaticLayer() {
  if (staticLayer == null) {
    staticLayer = createGraphics(width, height);
  }

  staticLayer.beginDraw();
  staticLayer.clear();
  staticLayer.smooth(8);
  staticLayer.textFont(serif);
  staticLayer.textAlign(LEFT, BASELINE);
  staticLayer.fill(TEXT_COLOR);

  for (LetterPiece letter : letters) {
    if (!letter.removedFromStatic) {
      letter.displayStatic(staticLayer);
    }
  }

  staticLayer.endDraw();
  staticDirty = false;
}

void drawPointer() {
  float angle = pointerAngle();
  float tipX = POINTER_X + cos(angle) * POINTER_LENGTH;
  float tipY = POINTER_Y + sin(angle) * POINTER_LENGTH;

  stroke(POINTER_COLOR);
  strokeWeight(2.4);
  strokeCap(ROUND);
  line(POINTER_X, POINTER_Y, tipX, tipY);

  noStroke();
  fill(POINTER_COLOR);
  ellipse(POINTER_X, POINTER_Y, 13, 13);
}

void drawController() {
  float knobX = lerp(SLIDER_X1, SLIDER_X2, pointerControl);

  stroke(TEXT_COLOR);
  strokeWeight(1.5);
  strokeCap(ROUND);
  line(SLIDER_X1, SLIDER_Y, SLIDER_X2, SLIDER_Y);

  noStroke();
  fill(POINTER_COLOR);
  ellipse(knobX, SLIDER_Y, 10, 10);
}

void updateControllerHover() {
  boolean inside = isOnSlider(mouseX, mouseY);

  if (inside) {
    updatePointerControl(mouseX);
    if (!controllerActive) {
      previousPointerControl = pointerControl;
      pointerSweepStartControl = pointerControl;
      pointerSweepDelta = 0;
      pointerVelocity = 0;
    }
  }

  controllerActive = inside;
}

boolean isOnSlider(float x, float y) {
  return x >= SLIDER_X1 - 14 &&
         x <= SLIDER_X2 + 14 &&
         abs(y - SLIDER_Y) <= 18;
}

void updatePointerControl(float x) {
  pointerControl = constrain((x - SLIDER_X1) / (SLIDER_X2 - SLIDER_X1), 0, 1);
}

float pointerAngle() {
  return -HALF_PI + pointerControl * TWO_PI;
}

void updatePointerPhysics() {
  float delta = pointerControl - previousPointerControl;
  pointerSweepStartControl = previousPointerControl;
  pointerSweepDelta = delta;
  pointerVelocity = constrain(delta, -MAX_POINTER_STEP, MAX_POINTER_STEP) * TWO_PI;
  previousPointerControl = pointerControl;
}

void applyPointerToLetters() {
  if (abs(pointerSweepDelta) < 0.0001) {
    return;
  }

  int steps = max(1, min(14, (int)ceil(abs(pointerSweepDelta) / 0.015)));
  float sweepDir = pointerSweepDelta > 0 ? 1 : -1;

  for (int s = 1; s <= steps; s++) {
    float control = pointerSweepStartControl + pointerSweepDelta * (float(s) / steps);
    float angle = -HALF_PI + control * TWO_PI;
    float tipX = POINTER_X + cos(angle) * POINTER_LENGTH;
    float tipY = POINTER_Y + sin(angle) * POINTER_LENGTH;

    for (LetterPiece letter : letters) {
      if (letter.sleeping) {
        continue;
      }

      float t = pointSegmentT(letter.cx(), letter.cy(), POINTER_X, POINTER_Y, tipX, tipY);
      if (t < 0.04 || t > 1.02) {
        continue;
      }

      float closestX = lerp(POINTER_X, tipX, constrain(t, 0, 1));
      float closestY = lerp(POINTER_Y, tipY, constrain(t, 0, 1));
      float d = dist(letter.cx(), letter.cy(), closestX, closestY);

      if (d < letter.r + POINTER_HIT_RADIUS) {
        float strength = map(t, 0, 1, 0.35, 1.45) * map(abs(pointerVelocity), 0, MAX_POINTER_STEP * TWO_PI, 0.45, 1.35);
        letter.collideWithPointerBlade(angle, closestX, closestY, sweepDir, strength);
      }
    }
  }
}

float pointSegmentT(float px, float py, float ax, float ay, float bx, float by) {
  float dx = bx - ax;
  float dy = by - ay;
  float len2 = dx * dx + dy * dy;

  if (len2 <= 0.0001) {
    return 0;
  }

  return ((px - ax) * dx + (py - ay) * dy) / len2;
}

void solveLetterCollisions() {
  int cols = int(width / COLLISION_CELL) + 2;
  HashMap<Integer, ArrayList<LetterPiece>> grid = new HashMap<Integer, ArrayList<LetterPiece>>();

  for (LetterPiece letter : letters) {
    if (!letter.falling) {
      continue;
    }

    int cellX = constrain(int(letter.cx() / COLLISION_CELL), 0, cols - 1);
    int cellY = max(0, int(letter.cy() / COLLISION_CELL));
    int key = cellX + cellY * cols;
    ArrayList<LetterPiece> bucket = grid.get(key);
    if (bucket == null) {
      bucket = new ArrayList<LetterPiece>();
      grid.put(key, bucket);
    }
    bucket.add(letter);
  }

  for (LetterPiece a : letters) {
    if (!a.falling) {
      continue;
    }

    int cellX = constrain(int(a.cx() / COLLISION_CELL), 0, cols - 1);
    int cellY = max(0, int(a.cy() / COLLISION_CELL));

    for (int oy = -1; oy <= 1; oy++) {
      for (int ox = -1; ox <= 1; ox++) {
        int key = (cellX + ox) + (cellY + oy) * cols;
        ArrayList<LetterPiece> bucket = grid.get(key);
        if (bucket == null) {
          continue;
        }

        for (LetterPiece b : bucket) {
          if (b.uid <= a.uid || !b.falling) {
            continue;
          }
          resolveLetterPair(a, b);
        }
      }
    }
  }
}

void resolveLetterPair(LetterPiece a, LetterPiece b) {
  if (a.sleeping && b.sleeping) {
    return;
  }

  float dx = a.cx() - b.cx();
  float dy = a.cy() - b.cy();
  float d2 = dx * dx + dy * dy;
  float target = (a.r + b.r) * 0.72;

  if (d2 <= 0.001 || d2 >= target * target) {
    return;
  }

  float d = sqrt(d2);
  float nx = dx / d;
  float ny = dy / d;
  float overlap = target - d;
  float aMove = a.sleeping ? 0.16 : 0.5;
  float bMove = b.sleeping ? 0.16 : 0.5;
  float totalMove = aMove + bMove;

  a.x += nx * overlap * (aMove / totalMove);
  a.baselineY += ny * overlap * (aMove / totalMove);
  b.x -= nx * overlap * (bMove / totalMove);
  b.baselineY -= ny * overlap * (bMove / totalMove);

  float push = overlap * 0.014;
  a.vx += nx * push;
  a.vy += ny * push;
  b.vx -= nx * push;
  b.vy -= ny * push;

  a.spin += nx * 0.004;
  b.spin -= nx * 0.004;
  a.touchingPile = true;
  b.touchingPile = true;

  if (a.sleeping && abs(b.vy) > 1.2) {
    a.sleeping = false;
    a.falling = true;
  }
  if (b.sleeping && abs(a.vy) > 1.2) {
    b.sleeping = false;
    b.falling = true;
  }
}

PFont loadSerifFont() {
  try {
    java.awt.Font awtFont = java.awt.Font.createFont(
      java.awt.Font.TRUETYPE_FONT,
      new java.io.File(sketchPath("Hoefler Text.ttc"))
    );
    java.awt.GraphicsEnvironment.getLocalGraphicsEnvironment().registerFont(awtFont);
    return createFont(awtFont.getFamily(), BODY_SIZE, true);
  } catch (Exception e) {
    return createFont("Hoefler Text", BODY_SIZE, true);
  }
}

float layoutFirstParagraph(String paragraph, float x, float y, float w) {
  textSize(DROP_SIZE);
  float dropBaseline = y + BODY_LEADING + 1;
  float dropIndent = ceil(textWidth("T") + DROP_GAP);
  addLetter("T", x, dropBaseline, DROP_SIZE);

  String remainder = paragraph.substring(1);
  String[] words = splitTokens(remainder, " ");
  textSize(BODY_SIZE);
  ArrayList<String[]> lines = makeLines(words, w - dropIndent, w, DROP_LINES);

  for (int i = 0; i < lines.size(); i++) {
    String[] line = lines.get(i);
    boolean lastLine = i == lines.size() - 1;
    boolean besideDrop = i < DROP_LINES;
    float lineX = besideDrop ? x + dropIndent : x;
    float lineW = besideDrop ? w - dropIndent : w;
    addLineLetters(line, lineX, y, lineW, !lastLine, BODY_SIZE);
    y += BODY_LEADING;
  }
  return y - BODY_LEADING;
}

float layoutParagraph(String paragraph, float x, float y, float w) {
  String[] words = splitTokens(paragraph, " ");
  textSize(BODY_SIZE);
  ArrayList<String[]> lines = makeLines(words, w, w, 0);

  for (int i = 0; i < lines.size(); i++) {
    String[] line = lines.get(i);
    boolean lastLine = i == lines.size() - 1;
    addLineLetters(line, x, y, w, !lastLine, BODY_SIZE);
    y += BODY_LEADING;
  }
  return y - BODY_LEADING;
}

ArrayList<String[]> makeLines(String[] words, float firstWidth, float normalWidth, int firstLineCount) {
  ArrayList<String[]> lines = new ArrayList<String[]>();
  ArrayList<String> current = new ArrayList<String>();
  float currentWidth = 0;
  float spaceWidth = textWidth(" ");
  float maxWidth = firstLineCount > 0 ? firstWidth : normalWidth;

  for (int i = 0; i < words.length; i++) {
    float wordWidth = textWidth(words[i]);
    float nextWidth = current.size() == 0 ? wordWidth : currentWidth + spaceWidth + wordWidth;

    if (current.size() > 0 && nextWidth > maxWidth) {
      lines.add(current.toArray(new String[current.size()]));
      current.clear();
      currentWidth = 0;
      maxWidth = lines.size() < firstLineCount ? firstWidth : normalWidth;
      nextWidth = wordWidth;
    }

    current.add(words[i]);
    currentWidth = nextWidth;
  }

  if (current.size() > 0) {
    lines.add(current.toArray(new String[current.size()]));
  }

  return lines;
}

void addLineLetters(String[] words, float x, float y, float w, boolean justify, float fontSize) {
  if (words.length == 0) {
    return;
  }

  textSize(fontSize);
  float gap = textWidth(" ");

  if (justify && words.length > 1) {
    float wordsWidth = 0;
    for (int i = 0; i < words.length; i++) {
      wordsWidth += textWidth(words[i]);
    }
    gap = (w - wordsWidth) / (words.length - 1);
  }

  float cursor = x;
  for (int i = 0; i < words.length; i++) {
    for (int j = 0; j < words[i].length(); j++) {
      String ch = str(words[i].charAt(j));
      addLetter(ch, cursor, y, fontSize);
      cursor += textWidth(ch);
    }
    if (i < words.length - 1) {
      cursor += gap;
    }
  }
}

void addLetter(String ch, float x, float baselineY, float fontSize) {
  textFont(serif);
  textSize(fontSize);
  letters.add(new LetterPiece(letters.size(), ch, x, baselineY, textWidth(ch), textAscent(), textDescent(), fontSize));
}

class LetterPiece {
  int uid;
  String ch;
  float homeX;
  float homeBaselineY;
  float x;
  float baselineY;
  float w;
  float ascent;
  float descent;
  float fontSize;
  float r;
  float vx;
  float vy;
  float angle;
  float spin;
  boolean falling = false;
  boolean sleeping = false;
  boolean touchingPile = false;
  boolean removedFromStatic = false;
  int lastPointerHitFrame = -1;

  LetterPiece(int tempUid, String tempCh, float tempX, float tempBaselineY, float tempW, float tempAscent, float tempDescent, float tempFontSize) {
    uid = tempUid;
    ch = tempCh;
    homeX = tempX;
    homeBaselineY = tempBaselineY;
    x = tempX;
    baselineY = tempBaselineY;
    w = max(tempW, 3);
    ascent = tempAscent;
    descent = tempDescent;
    fontSize = tempFontSize;
    r = max(3.8, min(10.5, max(w, ascent + descent) * 0.42));
    angle = 0;
  }

  float h() {
    return ascent + descent;
  }

  float cx() {
    return x + w * 0.5;
  }

  float cy() {
    return baselineY + (descent - ascent) * 0.5;
  }

  boolean isLoose() {
    return falling || sleeping;
  }

  void collideWithPointerBlade(float pointerAngle, float bladeX, float bladeY, float sweepDir, float strength) {
    if (sleeping) {
      return;
    }

    if (lastPointerHitFrame == frameCount) {
      return;
    }
    lastPointerHitFrame = frameCount;

    removeFromStaticLayer();

    falling = true;
    sleeping = false;

    float pushX = -sin(pointerAngle) * sweepDir;
    float pushY = cos(pointerAngle) * sweepDir;
    float bladeXDir = cos(pointerAngle);
    float bladeYDir = sin(pointerAngle);
    float slideSign = bladeYDir >= 0 ? 1 : -1;
    float slideX = bladeXDir * slideSign;
    float slideY = bladeYDir * slideSign;
    float safeDistance = r + POINTER_HIT_RADIUS + 0.6;

    setCenter(bladeX + pushX * safeDistance, bladeY + pushY * safeDistance);

    vx = vx * 0.35 + pushX * random(0.55, 1.25) * strength + slideX * random(0.42, 1.0) * strength;
    vy = vy * 0.35 + pushY * random(0.55, 1.25) * strength + slideY * random(0.42, 1.0) * strength + 0.32;
    spin += sweepDir * random(0.035, 0.095) * strength;
  }

  void setCenter(float newCx, float newCy) {
    x = newCx - w * 0.5;
    baselineY = newCy - (descent - ascent) * 0.5;
  }

  void removeFromStaticLayer() {
    if (removedFromStatic) {
      return;
    }

    removedFromStatic = true;
    staticDirty = true;
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
    baselineY += vy;
    angle += spin;
  }

  void constrainToRoom() {
    if (!falling) {
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

    if (baselineY + descent > floorY) {
      baselineY = floorY - descent;
      vy *= -0.36;
      vx *= 0.82;
      spin *= 0.82;
    }

    boolean calm = abs(vx) < 0.08 && abs(vy) < 0.28 && abs(spin) < 0.012;
    boolean supported = baselineY + descent >= floorY - 0.4 || touchingPile;

    if (supported && calm) {
      sleeping = true;
      falling = false;
      vx = 0;
      vy = 0;
      spin = 0;
    }
  }

  void display() {
    pushMatrix();
    translate(cx(), cy());
    rotate(angle);
    textFont(serif);
    textSize(fontSize);
    textAlign(LEFT, BASELINE);
    fill(TEXT_COLOR);
    text(ch, -w * 0.5, (ascent - descent) * 0.5);
    popMatrix();
  }

  void displayStatic(PGraphics pg) {
    pg.textSize(fontSize);
    pg.text(ch, x, baselineY);
  }
}
