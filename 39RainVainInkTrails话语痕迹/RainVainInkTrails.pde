int seed = 2018;
int nums;
float maxLife = 10;
float noiseScale = 200;
float simulationSpeed = 0.2;
int fadeFrame = 0;

float paddingTop = 100;
float paddingSide = 100;
float innerSquare = 512;

String chinesePhrase = "那天，那句话，像雨一样腐蚀侵入了我的心";
String phrase = "That day, those words seeped into my heart like rain, slowly corroding it.";
PFont letterFont;
PFont chineseFont;
PImage bg;
Particle[] particles;

float letterSize = 13;
float typingProgress = 0;
float typingSpeed = 0.42;
int chineseGlyphCount = 0;
int englishGlyphCount = 0;
float chineseY;
float englishY;
int trailStartFrame = 0;
float trailFadeFrames = 90;
float textBuildFadeFrames = 120;
boolean textReady = false;
boolean trailsStarted = false;

void setup() {
  size(600, 800);
  smooth(8);
  letterFont = createFont("Georgia", letterSize, true);
  chineseFont = createFont("Songti SC", letterSize, true);
  bg = loadImage("background.jpg");
  if (bg != null) {
    bg.resize(width, height);
  }
  resetSketch();
}

void resetSketch() {
  randomSeed(seed);
  noiseSeed(seed);
  fadeFrame = 0;
  typingProgress = 0;
  textReady = false;
  trailsStarted = false;

  paddingTop = (height - innerSquare) / 2.0;
  paddingSide = (width - innerSquare) / 2.0;
  chineseY = paddingTop - 32;
  englishY = paddingTop;

  chineseGlyphCount = countVisibleGlyphs(chinesePhrase);
  englishGlyphCount = countVisibleGlyphs(phrase);
  nums = chineseGlyphCount + englishGlyphCount;
  particles = new Particle[nums];
  layoutParticlesFromPhrases();

  drawBackground(255);
  noStroke();
}

void draw() {
  if (!trailsStarted) {
    drawBackground(255);
    updateTyping();
    drawStartLetters();
    return;
  }

  fadeFrame++;
  if (fadeFrame % 5 == 0) {
    blendMode(BLEND);
    noStroke();
    drawBackground(16);
  }

  updateInkTrails();
  drawStartLetters();
}

void keyPressed() {
  if (key == 'r' || key == 'R') {
    resetSketch();
  } else if (key == ' ') {
    startInkTrails();
  }
}

void drawBackground(float alphaValue) {
  blendMode(BLEND);
  if (bg != null) {
    tint(255, alphaValue);
    image(bg, 0, 0, width, height);
    noTint();
  } else {
    noStroke();
    fill(255, alphaValue);
    rect(0, 0, width, height);
  }
}

void updateTyping() {
  if (textReady) {
    return;
  }

  int targetCount = max(chineseGlyphCount, englishGlyphCount);
  typingProgress += typingSpeed / targetCount;
  if (typingProgress >= 1) {
    typingProgress = 1;
    textReady = true;
  }
}

void startInkTrails() {
  if (!textReady || trailsStarted) {
    return;
  }

  trailsStarted = true;
  fadeFrame = 0;
  trailStartFrame = frameCount;

  for (int i = 0; i < nums; i++) {
    particles[i].respawnTop();
  }
}

void updateInkTrails() {
  blendMode(BLEND);
  noStroke();
  float appear = constrain((frameCount - trailStartFrame) / trailFadeFrames, 0, 1);
  appear = appear * appear * (3 - 2 * appear);

  for (int i = 0; i < nums; i++) {
    if (!particles[i].makesTrail) {
      continue;
    }

    float iterations = map(i, 0, nums, 5, 1);
    float radius = map(i, 0, nums, 2, 6);

    particles[i].move(iterations);
    particles[i].checkEdge();

    float fadeRatio = min(particles[i].life * 5 / maxLife, 1);
    fadeRatio = min((maxLife - particles[i].life) * 5 / maxLife, fadeRatio);

    fill(0, 255 * fadeRatio * 0.36 * appear);
    particles[i].display(radius);
  }
}

void layoutParticlesFromPhrases() {
  int particleIndex = 0;
  particleIndex = layoutPhrase(chinesePhrase, chineseFont, chineseY, particleIndex, false);
  layoutPhrase(phrase, letterFont, englishY, particleIndex, true);
}

int layoutPhrase(String source, PFont fontForPhrase, float baselineY, int particleIndex, boolean makesTrail) {
  textFont(fontForPhrase);
  textSize(letterSize);

  float phraseW = textWidth(source);
  float x = (width - phraseW) / 2.0;

  for (int i = 0; i < source.length(); i++) {
    char c = source.charAt(i);
    String glyph = str(c);
    float glyphW = textWidth(glyph);

    if (c != ' ' && c != '\n') {
      particles[particleIndex] = new Particle(glyph, x + glyphW / 2.0, baselineY, particleIndex, makesTrail, fontForPhrase);
      particleIndex++;
    }

    x += glyphW;
  }

  return particleIndex;
}

int countVisibleGlyphs(String source) {
  int total = 0;

  for (int i = 0; i < source.length(); i++) {
    char c = source.charAt(i);
    if (c != ' ' && c != '\n') {
      total++;
    }
  }

  return total;
}

void drawStartLetters() {
  blendMode(BLEND);
  textFont(letterFont);
  textSize(letterSize);
  textAlign(CENTER, CENTER);
  noStroke();
  float letterAlpha = 245;

  if (trailsStarted) {
    float p = constrain((frameCount - trailStartFrame) / textBuildFadeFrames, 0, 1);
    p = p * p * (3 - 2 * p);
    letterAlpha = lerp(28, 245, p);
  }

  for (int i = 0; i < nums; i++) {
    if (particles[i].isTypedVisible()) {
      particles[i].displayLetter(letterAlpha);
    }
  }
}

class Particle {
  PVector vel;
  PVector pos;
  PVector start;
  float life;
  String glyph;
  int localIndex;
  boolean makesTrail;
  PFont displayFont;

  Particle(String glyph, float startX, float startY, int index, boolean makesTrail, PFont displayFont) {
    vel = new PVector(0, 0);
    pos = new PVector(startX + random(-1.5, 1.5), startY);
    start = new PVector(startX, startY);
    life = random(0, maxLife);
    this.glyph = glyph;
    localIndex = makesTrail ? index - chineseGlyphCount : index;
    this.makesTrail = makesTrail;
    this.displayFont = displayFont;
  }

  boolean isTypedVisible() {
    int lineCount = makesTrail ? englishGlyphCount : chineseGlyphCount;
    return localIndex < int(typingProgress * lineCount);
  }

  void move(float iterations) {
    if ((life -= 0.01666) < 0) {
      respawnTop();
    }

    while (iterations > 0) {
      float transition = map(pos.x, paddingSide, width - paddingSide, 0, 1);
      float angle = noise(pos.x / noiseScale, pos.y / noiseScale) * transition * TWO_PI * noiseScale;

      vel.x = cos(angle);
      vel.y = sin(angle);
      vel.mult(simulationSpeed);
      pos.add(vel);
      iterations--;
    }
  }

  void checkEdge() {
    if (pos.x > width - paddingSide
      || pos.x < paddingSide
      || pos.y > height - paddingTop
      || pos.y < paddingTop) {
      respawnTop();
    }
  }

  void respawnTop() {
    pos.x = start.x + random(-1.5, 1.5);
    pos.y = start.y;
    life = maxLife;
  }

  void display(float r) {
    ellipse(pos.x, pos.y, r, r);
  }

  void displayLetter(float alphaValue) {
    textFont(displayFont);
    textSize(letterSize);
    fill(0, alphaValue);
    text(glyph, start.x, start.y - 15);
  }
}
